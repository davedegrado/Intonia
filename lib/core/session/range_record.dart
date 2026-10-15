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
