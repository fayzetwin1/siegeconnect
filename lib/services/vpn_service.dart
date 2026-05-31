import 'dart:io';
import 'package:flutter/services.dart';
import 'vpn_service_windows.dart';

class VpnService {
  static const MethodChannel _channel = MethodChannel('com.siegeconnect/vpn_control');
  final _windowsService = VpnServiceWindows();

  Future<void> startVpn(String configPath, {Function(String)? onLog}) async {
    if (Platform.isWindows) {
      await _windowsService.startVpn(configPath, onLog: onLog);
      return;
    }

    try {
      await _channel.invokeMethod('startVpn', {'configPath': configPath});
    } on PlatformException catch (e) {
      throw Exception('Failed to start VPN: ${e.message}');
    }
  }

  Future<void> stopVpn() async {
    if (Platform.isWindows) {
      await _windowsService.stopVpn();
      return;
    }

    try {
      await _channel.invokeMethod('stopVpn');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop VPN: ${e.message}');
    }
  }

  Future<void> updateAllowedApps(List<String> packageNames) async {
    if (Platform.isWindows) {
      // Split tunneling for Windows is done via core rules or WinTun routing.
      return;
    }

    try {
      await _channel.invokeMethod('updateAllowedApps', {'packages': packageNames});
    } on PlatformException catch (e) {
      throw Exception('Failed to update allowed apps: ${e.message}');
    }
  }

  Future<void> startTestMode(String configPath) async {
    if (Platform.isWindows) {
      await _windowsService.startTestMode(configPath);
    } else {
      // For MVP Android test offline is not implemented via intent yet. 
      // We assume the user is using Windows as requested.
    }
  }

  /// Waits until the Mihomo REST API is ready to accept requests.
  Future<void> waitForReady() async {
    if (Platform.isWindows) {
      await _windowsService.waitForReady();
    }
  }

  Future<void> stopTestMode() async {
    if (Platform.isWindows) {
      await _windowsService.stopTestMode();
    }
  }
}
