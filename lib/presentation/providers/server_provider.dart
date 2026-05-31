import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/network/mihomo_api.dart';
import '../../data/network/api_client.dart';
import '../../data/config_manager.dart';
import 'settings_provider.dart';
import 'vpn_state_provider.dart';
import '../../main.dart'; // for isarProvider
import '../../domain/models/app_settings.dart';
import '../../services/vpn_service.dart';
import 'package:isar/isar.dart';

class ServerData {
  final String activeServer;
  final List<String> availableServers;
  final String groupName;
  final Map<String, int> pingResults; // Store pings here

  ServerData({
    required this.activeServer,
    required this.availableServers,
    required this.groupName,
    this.pingResults = const {},
  });

  ServerData copyWith({
    String? activeServer,
    List<String>? availableServers,
    String? groupName,
    Map<String, int>? pingResults,
  }) {
    return ServerData(
      activeServer: activeServer ?? this.activeServer,
      availableServers: availableServers ?? this.availableServers,
      groupName: groupName ?? this.groupName,
      pingResults: pingResults ?? this.pingResults,
    );
  }
}

class ServerNotifier extends Notifier<ServerData?> {
  final _api = MihomoApi();
  final _apiClient = ApiClient();
  final _configManager = ConfigManager();
  Timer? _pollingTimer;

  @override
  ServerData? build() {
    _loadFromIsar();

    // Listen to VPN state to start/stop API polling
    ref.listen<VpnConnectionState>(vpnStateProvider, (prev, next) {
      if (next == VpnConnectionState.connected) {
        _startPolling();
      } else {
        _stopPolling();
      }
    });
    return null;
  }

  void _loadFromIsar() {
    final appSettings = ref.read(settingsProvider);
    if (appSettings.parsedServers.isNotEmpty) {
      state = ServerData(
        activeServer: '', // Unknown until connected
        availableServers: appSettings.parsedServers,
        groupName: '', // Unknown until connected
      );
    }
  }

  void clearData() {
    state = null;
  }

  void _startPolling() async {
    await _fetchActiveServer();

    // If an activeServer is saved in Isar, enforce it now since we've just connected
    final isar = ref.read(isarProvider);
    final settings = isar.appSettings.where().findFirstSync();
    if (settings != null && settings.activeServer != null && settings.activeServer!.isNotEmpty) {
      if (state != null && state!.groupName.isNotEmpty) {
        if (state!.availableServers.contains(settings.activeServer)) {
          final success = await _api.selectProxy(state!.groupName, settings.activeServer!);
          if (success) {
            state = state!.copyWith(activeServer: settings.activeServer!);
          }
        }
      }
    }

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchActiveServer());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchActiveServer() async {
    final proxiesData = await _api.getProxies();
    if (proxiesData.containsKey('proxies')) {
      final proxies = proxiesData['proxies'] as Map<String, dynamic>;
      
      String? mainGroup;
      for (final key in proxies.keys) {
        if (proxies[key]['type'] == 'Selector') {
          mainGroup = key;
          break;
        }
      }

      if (mainGroup != null) {
        final groupData = proxies[mainGroup];
        final now = groupData['now'] ?? '';
        if (state != null) {
          state = state!.copyWith(activeServer: now, groupName: mainGroup);
        }
      }
    }
  }

  Future<void> updateSubscription() async {
    final subLink = ref.read(settingsProvider).subLink;
    if (subLink == null || subLink.isEmpty) return;

    try {
      final rawYaml = await _apiClient.fetchSubConfig(subLink);
      final servers = _configManager.parseServers(rawYaml);
      
      if (servers.isNotEmpty) {
        final isar = ref.read(isarProvider);
        final settings = isar.appSettings.where().findFirstSync();
        if (settings != null) {
          isar.writeTxnSync(() {
            settings.parsedServers = servers;
            settings.cachedYamlConfig = rawYaml;
            isar.appSettings.putSync(settings);
          });
        }
        
        state = ServerData(
          activeServer: state?.activeServer ?? '',
          availableServers: servers,
          groupName: state?.groupName ?? '',
        );
      }
    } catch (e) {
      print('Update sub error: \$e');
      throw Exception('Failed to update subscription');
    }
  }

  Future<void> selectServer(String serverName) async {
    // Save selection persistently even if disconnected
    final isar = ref.read(isarProvider);
    var settings = isar.appSettings.where().findFirstSync() ?? AppSettings();
    isar.writeTxnSync(() {
      settings.activeServer = serverName;
      isar.appSettings.putSync(settings);
    });

    final isConnected = ref.read(vpnStateProvider) == VpnConnectionState.connected;

    if (isConnected && state != null && state!.groupName.isNotEmpty) {
      final success = await _api.selectProxy(state!.groupName, serverName);
      if (success) {
        state = state!.copyWith(activeServer: serverName);
      }
    } else {
      // Just update UI if disconnected
      state = state?.copyWith(activeServer: serverName);
    }
  }

  Future<void> pingServers() async {
    final vpnState = ref.read(vpnStateProvider);
    final isConnected = vpnState == VpnConnectionState.connected;
    
    if (state == null) return;

    // Set all pings to -1 (loading indicator)
    final pings = <String, int>{};
    for (final srv in state!.availableServers) {
      pings[srv] = -1;
    }
    state = state!.copyWith(pingResults: Map.from(pings));

    final vpnService = VpnService();

    if (!isConnected) {
      // Offline ping: start a temporary Mihomo instance
      try {
        final isar = ref.read(isarProvider);
        final appSettings = isar.appSettings.where().findFirstSync();
        if (appSettings == null || appSettings.cachedYamlConfig == null) {
          throw Exception('No configuration available to test.');
        }
        final testConfigPath = await _configManager.prepareTestConfig(appSettings.cachedYamlConfig!);
        await vpnService.startTestMode(testConfigPath);
        
        // Wait for the API to become ready instead of a blind delay
        await vpnService.waitForReady();
      } catch (e) {
        // Test mode failed — clear all spinners to show failure
        for (final srv in state!.availableServers) {
          pings[srv] = 0; // 0 = timeout/error
        }
        state = state!.copyWith(pingResults: Map.from(pings));

        // Clean up
        try { await vpnService.stopTestMode(); } catch (_) {}

        throw Exception('Failed to start test mode: $e');
      }
    }

    try {
      // Ping all servers concurrently
      await Future.wait(state!.availableServers.map((srv) async {
        final delay = await _api.getDelay(srv);
        pings[srv] = delay;
        if (state != null) {
          state = state!.copyWith(pingResults: Map.from(pings));
        }
      }));
    } finally {
      if (!isConnected) {
        await vpnService.stopTestMode();
      }
    }
  }
}

final serverProvider = NotifierProvider<ServerNotifier, ServerData?>(() {
  return ServerNotifier();
});
