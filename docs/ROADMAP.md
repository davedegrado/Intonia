# Roadmap

La panoramica per fasi è in [`intonia_roadmap_v2.svg`](intonia_roadmap_v2.svg)
(Karaoke Mode: [`karaoke-architecture.md`](karaoke-architecture.md)). Qui sono
elencati i miglioramenti puntuali decisi ma rimandati.

## Miglioramenti pianificati

### Nota guida senza pausa d'ascolto

**Stato:** pianificato, non in sviluppo.

**Problema.** Mentre suona la nota guida l'app non ascolta il microfono:
altrimenti il piano verrebbe riconosciuto come voce e convaliderebbe la nota da
solo. La pausa dura circa 1,1 s per ogni nota guida (650 ms di nota + 450 ms di
coda per il rilascio del piano e il buffering del microfono; vedi
`_guideNoteDuration` e `_detectionMuteTail` in `TrainerController` e
`RangeTestController`). Con la guida su ogni nota gli esercizi risultano lenti.

**Perché non si può semplicemente filtrare il piano.** La nota guida ha la
stessa altezza di quella da cantare, quindi un filtro in frequenza non la
distingue dalla voce. La cancellazione dell'eco di sistema è già attiva
(`echoCancel: true` in `MicrophonePitchService`), ma è tarata sul parlato e non
è affidabile quando voce e piano suonano insieme alla stessa altezza.

**Soluzioni proposte**, anche combinabili:

1. **Cuffie collegate → nessuna pausa.** Con cuffie (cablate o Bluetooth) il
   microfono non capta il piano. Rilevare l'uscita audio attiva con una piccola
   funzione nativa (Android: `AudioManager.getDevices`; iOS:
   `AVAudioSession.currentRoute`), senza nuove dipendenze, e saltare la pausa.
2. **Pausa più corta in vivavoce.** Nota guida ~400 ms e coda ~250 ms (da
   1,1 s a ~0,65 s). Da verificare su dispositivi reali che la coda del piano
   non venga convalidata come voce.
3. *(Esplorativo)* Distinguere piano e voce dal timbro (decadimento del piano
   contro voce sostenuta/vibrato). Complesso e a rischio di falsi positivi:
   solo se 1 e 2 non bastano.
