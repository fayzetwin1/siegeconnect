import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogEntry {
  final DateTime timestamp;
  final String message;
  final bool isError;

  LogEntry(this.message, {this.isError = false}) : timestamp = DateTime.now();

  @override
  String toString() {
    final time = "\${timestamp.hour.toString().padLeft(2, '0')}:\${timestamp.minute.toString().padLeft(2, '0')}:\${timestamp.second.toString().padLeft(2, '0')}";
    return "[\$time] \$message";
  }
}

class LogNotifier extends Notifier<List<LogEntry>> {
  @override
  List<LogEntry> build() {
    return [];
  }

  void addLog(String message, {bool isError = false}) {
    // Keep max 1000 logs to prevent memory issues
    if (state.length >= 1000) {
      state = [...state.skip(1), LogEntry(message, isError: isError)];
    } else {
      state = [...state, LogEntry(message, isError: isError)];
    }
    // Also print to console for development
    if (isError) {
      print('\x1B[31m[APP LOG ERR] \$message\x1B[0m');
    } else {
      print('[APP LOG] \$message');
    }
  }

  void clearLogs() {
    state = [];
  }
}

final logProvider = NotifierProvider<LogNotifier, List<LogEntry>>(() {
  return LogNotifier();
});
