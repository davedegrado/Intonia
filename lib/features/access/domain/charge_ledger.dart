/// Cariche del piano Free: ogni sessione di un esercizio strutturato ne
/// consuma una; se ne rigenera una ogni [interval] fino a [max].
///
/// La rigenerazione è calcolata solo da timestamp ([regenStartedAt]), quindi
/// continua ad app chiusa e non dipende da timer attivi. Classe immutabile e
/// senza I/O: lo stato viene persistito da ChargesRepository.
class ChargeLedger {
  const ChargeLedger({required this.charges, this.regenStartedAt});

  /// Prima installazione: cariche piene.
  static const full = ChargeLedger(charges: max);

  static const max = 7;
  static const interval = Duration(hours: 3);

  /// Cariche disponibili, 0..[max].
  final int charges;

  /// Istante da cui matura la prossima carica; null quando le cariche sono
  /// piene (la rigenerazione è ferma).
  final DateTime? regenStartedAt;

  bool get isFull => charges >= max;

  /// Stato aggiornato a [now]: aggiunge le cariche maturate (senza superare
  /// [max]) e conserva il tempo già maturato verso la carica successiva.
  ///
  /// Orologio spostato indietro (o timestamp nel futuro): la rigenerazione
  /// riparte da [now] senza assegnare cariche. Un orologio spostato in avanti
  /// non si può distinguere da tempo realmente trascorso offline: al massimo
  /// riempie le cariche fino a [max].
  ChargeLedger refreshed(DateTime now) {
    final count = charges.clamp(0, max);
    if (count >= max) {
      return const ChargeLedger(charges: max);
    }
    final started = regenStartedAt;
    if (started == null || started.isAfter(now)) {
      return ChargeLedger(charges: count, regenStartedAt: now);
    }
    final elapsed = now.difference(started);
    final gained = elapsed.inMicroseconds ~/ interval.inMicroseconds;
    if (gained <= 0) {
      return ChargeLedger(charges: count, regenStartedAt: started);
    }
    final total = count + gained;
    if (total >= max) {
      return const ChargeLedger(charges: max);
    }
    return ChargeLedger(charges: total, regenStartedAt: started.add(interval * gained));
  }

  /// Consuma una carica a [now]. Ritorna null se non ce ne sono.
  ChargeLedger? consumed(DateTime now) {
    final current = refreshed(now);
    if (current.charges <= 0) {
      return null;
    }
    return ChargeLedger(
      charges: current.charges - 1,
      // Da piene la rigenerazione parte ora; altrimenti prosegue il tempo
      // già maturato.
      regenStartedAt: current.regenStartedAt ?? now,
    );
  }

  /// Tempo alla prossima carica (null se piene). Da usare su uno stato
  /// aggiornato con [refreshed].
  Duration? timeToNext(DateTime now) {
    final started = regenStartedAt;
    if (isFull || started == null) {
      return null;
    }
    final remaining = started.add(interval).difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'charges': charges,
        if (regenStartedAt != null) 'regenStartedAt': regenStartedAt!.toUtc().toIso8601String(),
      };

  /// Lettura tollerante: valori mancanti o non validi non regalano cariche
  /// oltre il limite e non bloccano l'app.
  factory ChargeLedger.fromJson(Map<String, dynamic> json) {
    final rawCharges = json['charges'];
    final charges = rawCharges is int ? rawCharges.clamp(0, max) : max;
    final rawStarted = json['regenStartedAt'];
    final started = rawStarted is String ? DateTime.tryParse(rawStarted) : null;
    return ChargeLedger(charges: charges, regenStartedAt: started);
  }

  @override
  bool operator ==(Object other) =>
      other is ChargeLedger && other.charges == charges && other.regenStartedAt == regenStartedAt;

  @override
  int get hashCode => Object.hash(charges, regenStartedAt);
}
