import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class VpnServiceWindows {
  Process? _mihomoProcess;
  Process? _testProcess;

  String _findMihomoExe() {
    final executableDir = p.dirname(Platform.resolvedExecutable);
    final exePath = p.join(executableDir, 'data', 'flutter_assets', 'assets', 'mihomo', 'mihomo-windows-amd64.exe');
    final devPath = p.join(Directory.current.path, 'assets', 'mihomo', 'mihomo-windows-amd64.exe');
    final targetExe = File(exePath).existsSync() ? exePath : devPath;
    if (!File(targetExe).existsSync()) {
      throw Exception('Mihomo executable not found at $targetExe');
    }
    return targetExe;
  }

  Future<void> startVpn(String configPath, {Function(String)? onLog}) async {
    if (_mihomoProcess != null) {
      await stopVpn();
    }

    try {
      final targetExe = _findMihomoExe();

      print('Starting Mihomo Core: $targetExe with config $configPath');
      if (onLog != null) onLog('Starting Mihomo Core...');
      
      _mihomoProcess = await Process.start(
        targetExe,
        ['-f', configPath],
        workingDirectory: p.dirname(targetExe),
        mode: ProcessStartMode.normal,
      );

      _mihomoProcess?.stdout.listen((data) {
        final msg = String.fromCharCodes(data).trim();
        if (msg.isNotEmpty) {
          print('Mihomo: $msg');
          if (onLog != null) onLog(msg);
        }
      });
      _mihomoProcess?.stderr.listen((data) {
        final msg = String.fromCharCodes(data).trim();
        if (msg.isNotEmpty) {
          print('Mihomo ERR: $msg');
          if (onLog != null) onLog('ERR: $msg');
        }
      });

    } catch (e) {
      if (onLog != null) onLog('Failed to start Windows VPN: $e');
      throw Exception('Failed to start Windows VPN: $e');
    }
  }

  Future<void> stopVpn() async {
    try {
      if (_mihomoProcess != null) {
        _mihomoProcess?.kill();
        _mihomoProcess = null;
        print('Mihomo core stopped.');
      }
    } catch (e) {
      throw Exception('Failed to stop Windows VPN: $e');
    }
  }

  Future<void> startTestMode(String configPath) async {
    if (_testProcess != null) {
      await stopTestMode();
    }
    try {
      final targetExe = _findMihomoExe();

      print('Starting Mihomo Test Mode: $targetExe with config $configPath');

      _testProcess = await Process.start(
        targetExe,
        ['-f', configPath],
        workingDirectory: p.dirname(targetExe),
        mode: ProcessStartMode.normal,
      );

      // Attach listeners for debugging
      _testProcess?.stdout.listen((data) {
        print('Mihomo Test: ${String.fromCharCodes(data)}');
      });
      _testProcess?.stderr.listen((data) {
        print('Mihomo Test ERR: ${String.fromCharCodes(data)}');
      });

      _testProcess?.exitCode.then((code) {
        print('Mihomo test process exited with code $code');
      });

    } catch (e) {
      throw Exception('Failed to start test mode: $e');
    }
  }

  /// Polls the Mihomo REST API until it responds, or times out.
  Future<void> waitForReady({Duration timeout = const Duration(seconds: 10)}) async {
    final deadline = DateTime.now().add(timeout);
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 500),
      receiveTimeout: const Duration(milliseconds: 500),
    ));

    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await dio.get('http://127.0.0.1:9090');
        if (response.statusCode != null) return; // API is up
      } catch (_) {
        // Not ready yet
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw Exception('Mihomo API not ready after ${timeout.inSeconds}s');
  }

  Future<void> stopTestMode() async {
    try {
      if (_testProcess != null) {
        _testProcess?.kill();
        _testProcess = null;
        print('Mihomo test core stopped.');
      }
    } catch (e) {
      print('Failed to stop test mode: $e');
    }
  }
}
