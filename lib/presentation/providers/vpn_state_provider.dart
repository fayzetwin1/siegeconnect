import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/vpn_service.dart';
import '../../data/network/api_client.dart';
import '../../data/config_manager.dart';
import 'log_provider.dart';

enum VpnConnectionState { disconnected, connecting, connected, error }

class VpnStateNotifier extends Notifier<VpnConnectionState> {
  final _vpnService = VpnService();
  final _apiClient = ApiClient();
  final _configManager = ConfigManager();

  @override
  VpnConnectionState build() {
    return VpnConnectionState.disconnected;
  }

  String? lastError;

  Future<void> connect(String subLink) async {
    state = VpnConnectionState.connecting;
    lastError = null;
    ref.read(logProvider.notifier).addLog('Starting connection process...');
    try {
      final rawYaml = await _apiClient.fetchSubConfig(subLink);
      ref.read(logProvider.notifier).addLog('Subscription config fetched successfully.');
      final configPath = await _configManager.prepareConfig(rawYaml);
      
      await _vpnService.startVpn(configPath, onLog: (msg) {
        ref.read(logProvider.notifier).addLog(msg, isError: msg.startsWith('ERR:'));
      });

      // Wait for the Mihomo API to become ready before declaring success.
      // If Mihomo crashes (e.g. bad config), waitForReady will time out and throw.
      await _vpnService.waitForReady();

      ref.read(logProvider.notifier).addLog('Connection established successfully.');
      state = VpnConnectionState.connected;
    } catch (e) {
      ref.read(logProvider.notifier).addLog('Connection Error: $e', isError: true);
      print('VPN Connection Error: $e');
      lastError = e.toString();
      // Make sure to clean up the process if it started but failed
      try { await _vpnService.stopVpn(); } catch (_) {}
      state = VpnConnectionState.error;
    }
  }

  Future<void> disconnect() async {
    ref.read(logProvider.notifier).addLog('Disconnecting...');
    try {
      await _vpnService.stopVpn();
      ref.read(logProvider.notifier).addLog('Disconnected successfully.');
      state = VpnConnectionState.disconnected;
    } catch (e) {
      ref.read(logProvider.notifier).addLog('Disconnection Error: $e', isError: true);
      print('VPN Disconnection Error: $e');
      state = VpnConnectionState.error;
    }
  }
}

final vpnStateProvider = NotifierProvider<VpnStateNotifier, VpnConnectionState>(() {
  return VpnStateNotifier();
});
