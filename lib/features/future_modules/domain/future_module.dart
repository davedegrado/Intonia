enum FutureModuleStatus { planned, architectureReady }

class FutureModule {
  const FutureModule({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
  });

  final String id;
  final String name;
  final String description;
  final FutureModuleStatus status;
}

class FutureModuleRegistry {
  const FutureModuleRegistry();

  List<FutureModule> get modules => const [
        FutureModule(
          id: 'intervals',
          name: 'Intervalli',
          description: 'Training su distanza tra due note e memoria intervallare.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'triads',
          name: 'Triadi',
          description: 'Studio di triadi maggiori, minori, aumentate e diminuite.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'arpeggios',
          name: 'Arpeggi',
          description: 'Sequenze arpeggiate con validazione vocale progressiva.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'chords',
          name: 'Accordi',
          description: 'Riconoscimento e canto delle componenti armoniche.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'progressions',
          name: 'Progressioni',
          description: 'Percorsi armonici estesi per ear training e intonazione.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'vocalises',
          name: 'Vocalizzi',
          description: 'Esercizi vocali guidati per riscaldamento e tecnica.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'ear_training',
          name: 'Ear Training',
          description: 'Esercizi di ascolto, memoria e riconoscimento musicale.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'advanced_stats',
          name: 'Statistiche avanzate',
          description: 'Trend, accuratezza per nota, range vocale e storico sessioni.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'profile',
          name: 'Profilo utente',
          description: 'Preferenze, range vocale e obiettivi personali.',
          status: FutureModuleStatus.architectureReady,
        ),
        FutureModule(
          id: 'cloud_sync',
          name: 'Cloud Sync',
          description: 'Sincronizzazione opzionale dei dati utente nelle versioni online.',
          status: FutureModuleStatus.planned,
        ),
        FutureModule(
          id: 'iap',
          name: 'Acquisti in-app',
          description: 'Catalogo commerciale e unlock di contenuti premium.',
          status: FutureModuleStatus.planned,
        ),
      ];
}
