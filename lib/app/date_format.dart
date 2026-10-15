/// Data breve delle sessioni e dei test: "14/10 17:23".
String formatShortDate(DateTime timestamp) {
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${pad(timestamp.day)}/${pad(timestamp.month)} ${pad(timestamp.hour)}:${pad(timestamp.minute)}';
}
