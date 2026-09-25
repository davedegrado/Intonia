/// Risultato di un test di estensione vocale.
class RangeRecord {
  const RangeRecord({
    required this.timestamp,
    required this.minMidi,
    required this.maxMidi,
  });

  factory RangeRecord.fromJson(Map<String, dynamic> json) {
    return RangeRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      minMidi: json['minMidi'] as int,
      maxMidi: json['maxMidi'] as int,
    );
  }

  final DateTime timestamp;
  final int minMidi;
  final int maxMidi;

  /// Ampiezza in semitoni.
  int get spanSemitones => maxMidi - minMidi;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'minMidi': minMidi,
        'maxMidi': maxMidi,
      };
}

/// Formatta un'ampiezza in semitoni come "N ottave + M semitoni".
/// Es. 31 → "2 ottave + 7 semitoni", 24 → "2 ottave", 7 → "7 semitoni".
String formatSpan(int semitones) {
  final octaves = semitones ~/ 12;
  final rest = semitones % 12;
  if (octaves == 0) {
    return rest == 1 ? '1 semitono' : '$rest semitoni';
  }
  final octavePart = octaves == 1 ? '1 ottava' : '$octaves ottave';
  if (rest == 0) {
    return octavePart;
  }
  return '$octavePart + ${rest == 1 ? '1 semitono' : '$rest semitoni'}';
}
