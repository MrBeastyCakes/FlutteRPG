enum LogType {
  info,
  success,
  warning,
  error,
  levelUp,
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  const LogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
  });

  String get formattedTime {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final seconds = timestamp.second.toString().padLeft(2, '0');
    return '[$hours:$minutes:$seconds]';
  }
}
