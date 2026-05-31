import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vpn_state_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/server_provider.dart';
import '../utils/flag_utils.dart';
import 'package:circle_flags/circle_flags.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';
import '../providers/log_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _linkController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _updateSub(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(serverProvider.notifier).updateSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Subscription updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
          title: const Text('Update Failed'),
          content: const Text('Could not update subscription. Please check your link in Settings and your internet connection.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Okay'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnStateProvider);
    final appSettings = ref.watch(settingsProvider);
    final serverData = ref.watch(serverProvider);
    
    ref.listen<VpnConnectionState>(vpnStateProvider, (previous, next) {
      if (next == VpnConnectionState.error) {
        final errorMsg = ref.read(vpnStateProvider.notifier).lastError ?? 'Unknown error';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
            title: const Text('Connection Error'),
            content: Text(
              'Oops! Something went wrong while connecting.\n\nDetails:\n$errorMsg',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen()));
                },
                child: const Text('View Logs'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      }
    });

    final hasSubLink = appSettings != null && appSettings.subLink != null && appSettings.subLink!.isNotEmpty;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: isDesktop ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'View Logs',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen())),
          ),
          _buildSettingsButton(context),
        ],
      ),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100, right: -100,
            child: _buildGlowingBlob(colorScheme.primary.withOpacity(0.15), 400),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: _buildGlowingBlob(colorScheme.tertiary.withOpacity(0.1), 500),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      // Sidebar
                        Container(
                          width: 350,
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
                            color: colorScheme.surfaceContainerLow,
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain),
                                        ),
                                      ),
                                      Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.list_alt, color: colorScheme.onSurfaceVariant),
                                          tooltip: 'View Logs',
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen())),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.sync, color: colorScheme.onSurfaceVariant),
                                          tooltip: 'Update Subscription',
                                          onPressed: () => _updateSub(context, ref),
                                        ),
                                        _buildSettingsButton(context),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Divider(color: colorScheme.outlineVariant, height: 1),
                              Expanded(child: _buildServerList(ref, serverData, vpnState)),
                              if (serverData != null && serverData.availableServers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.surfaceContainerHighest,
                                        foregroundColor: colorScheme.onSurface,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.speed),
                                      label: const Text('Test Ping', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        ref.read(serverProvider.notifier).pingServers().catchError((e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString())),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      // Main View
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 450),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: hasSubLink 
                                      ? _buildConnectionCard(context, ref, vpnState, appSettings.subLink!, serverData)
                                      : _buildEmptyStateCard(context, colorScheme),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 56), // Avoid AppBar overlap
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: hasSubLink 
                                      ? _buildConnectionCard(context, ref, vpnState, appSettings.subLink!, serverData)
                                      : _buildEmptyStateCard(context, colorScheme),
                                ),
                              ),
                              if (hasSubLink) ...[
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.surfaceContainerHighest, foregroundColor: colorScheme.onSurface),
                                      icon: const Icon(Icons.sync),
                                      label: const Text('Update'),
                                      onPressed: () => _updateSub(context, ref),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.surfaceContainerHighest, foregroundColor: colorScheme.onSurface),
                                      icon: const Icon(Icons.speed),
                                      label: const Text('Ping'),
                                      onPressed: () {
                                        if (serverData != null && serverData.availableServers.isNotEmpty) {
                                          ref.read(serverProvider.notifier).pingServers().catchError((e) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ]
                            ],
                          ),
                        ),
                        if (hasSubLink)
                          _buildSliverServerList(ref, serverData, vpnState, colorScheme),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
      tooltip: 'Settings',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
    );
  }

  Widget _buildGlowingBlob(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildServerList(WidgetRef ref, ServerData? data, VpnConnectionState state) {
    if (data == null || data.availableServers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No servers found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            TextButton(
              onPressed: () => _updateSub(context, ref),
              child: const Text('Update Subscription'),
            )
          ],
        ),
      );
    }
    return Scrollbar(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: data.availableServers.length,
      itemBuilder: (context, index) {
        final serverName = data.availableServers[index];
        final isActive = serverName == data.activeServer;
        final ping = data.pingResults[serverName];
        
        Widget trailing;
        if (ping == -1) {
          trailing = const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        } else if (ping != null && ping > 0) {
          trailing = Text('${ping}ms', style: TextStyle(color: ping < 150 ? Colors.greenAccent : (ping < 300 ? Colors.orangeAccent : Colors.redAccent), fontWeight: FontWeight.bold));
        } else if (ping == 0) {
          trailing = const Text('×', style: TextStyle(color: Colors.white38, fontSize: 16));
        } else {
          trailing = const SizedBox();
        }

        final flag = FlagUtils.getFlag(serverName);
        final displayName = FlagUtils.cleanName(serverName);

        return ListTile(
          leading: CircleFlag(flag, size: 28),
          title: Text(
            displayName,
            style: TextStyle(
              color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: trailing,
          onTap: () {
            ref.read(serverProvider.notifier).selectServer(serverName);
          },
        );
      },
    ),
    );
  }

  Widget _buildSliverServerList(WidgetRef ref, ServerData? data, VpnConnectionState state, ColorScheme colorScheme) {
    if (data == null || data.availableServers.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text('No servers found', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final serverName = data.availableServers[index];
            final isActive = serverName == data.activeServer;
            final ping = data.pingResults[serverName];
            
            Widget trailing;
            if (ping == -1) {
              trailing = const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
            } else if (ping != null && ping > 0) {
              trailing = Text('${ping}ms', style: TextStyle(color: ping < 150 ? Colors.greenAccent : (ping < 300 ? Colors.orangeAccent : Colors.redAccent), fontWeight: FontWeight.bold));
            } else if (ping == 0) {
              trailing = const Text('×', style: TextStyle(color: Colors.white38, fontSize: 16));
            } else {
              trailing = const SizedBox();
            }

            final flag = FlagUtils.getFlag(serverName);
            final displayName = FlagUtils.cleanName(serverName);

            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: CircleFlag(flag, size: 28),
                title: Text(
                  displayName,
                  style: TextStyle(
                    color: isActive ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: trailing,
                onTap: () {
                  ref.read(serverProvider.notifier).selectServer(serverName);
                },
              ),
            );
          },
          childCount: data.availableServers.length,
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.link_off, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No Subscription', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Please add a subscription link in Settings to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, WidgetRef ref, VpnConnectionState state, String subLink, ServerData? serverData) {
    final isConnected = state == VpnConnectionState.connected;
    final isConnecting = state == VpnConnectionState.connecting;
    
    String statusText;
    Color statusColor;
    switch (state) {
      case VpnConnectionState.disconnected: statusText = 'Disconnected'; statusColor = Theme.of(context).colorScheme.outline; break;
      case VpnConnectionState.connecting: statusText = 'Connecting...'; statusColor = Theme.of(context).colorScheme.secondary; break;
      case VpnConnectionState.connected: statusText = 'Secured'; statusColor = const Color(0xFF00C853); break;
      case VpnConnectionState.error: statusText = 'Connection Error'; statusColor = Theme.of(context).colorScheme.error; break;
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isConnected ? Icons.check_circle_outline : Icons.shield_outlined, color: statusColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(statusText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: statusColor)),
            const SizedBox(height: 8),
            Text(
              isConnected && serverData != null ? 'Connected to: ${FlagUtils.cleanName(serverData.activeServer)}' : 'Your connection is protected with\nadvanced threat detection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
          GestureDetector(
            onTap: isConnecting ? null : () {
              if (isConnected) ref.read(vpnStateProvider.notifier).disconnect();
              else ref.read(vpnStateProvider.notifier).connect(subLink);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
                boxShadow: isConnected || isConnecting ? [] : [
                  BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Center(
                child: isConnecting
                    ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                    : Icon(Icons.power_settings_new, size: 60, color: isConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }
}
