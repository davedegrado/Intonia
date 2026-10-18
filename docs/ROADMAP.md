# Roadmap

La panoramica per fasi è in [`intonia_roadmap_v2.svg`](intonia_roadmap_v2.svg)
(Karaoke Mode: [`karaoke-architecture.md`](karaoke-architecture.md)). Questo
file è la fonte testuale dello stato; le attività per la pubblicazione sono in
[`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md). Il foglio
`outputs/roadmap-vocal-scale-trainer/` è un artefatto della prima
impostazione del progetto e non è aggiornato.

## Stato verificato (audit del 18/10/2026, commit `65b92a7`)

Legenda: `[x]` completato e verificato (codice + test automatici; i test non
coprono microfono e altoparlante reali) · `[ ]` da fare · `[!]` richiede una
verifica esterna · `[?]` non determinabile.

**Fondamenta**
- [x] Motore di riconoscimento YIN con rilevamento delle note gravi
  (`yin_pitch_detector.dart`; `pitch_recognition_test`, `low_pitch_test`).
- [x] Libreria di esercizi ed editor di sequenze personalizzate, con modalità
  Ascendente/Discendente/Completo (`exercise_test`, `exercise_copy_test`,
  `playback_direction_test`).
- [x] Test di estensione vocale (`range_record_test`, `range_result_test`).
- [x] Icona, splash e mascotte (`mascot_test`, `splash_overlay_test`).

**Pre-lancio**
- [x] Impostazioni: tema, notazione, lingua (`localization_test`).
- [x] Profilo, statistiche, serie giornaliera, widget Home
  (`session_record_test`, `widget_streak_test`, `home_widget_sync_test`).
- [x] Calibrazione del rumore di fondo (`measureAmbientRms`); efficacia reale
  non verificata su dispositivo.
- [x] SoundFont con licenza: FluidR3 (MIT), notice nell'app
  (`soundfont_asset_test`).
- [!] Test su dispositivi reali: solo avvio e microfono apparentemente
  funzionante su un iPhone (TestFlight) e un Samsung Android, confermati dal
  titolare; checklist audio non eseguita.
- [x] Distribuzione di test iOS: workflow TestFlight riuscito dal run #3
  (ultimo #26, 16/10/2026).
- [ ] Build Android pubblicabile (AAB con upload key).

**Apertura al pubblico**
- [x] Localizzazione inglese (app e widget, `docs/LOCALIZATION.md`).
- [ ] Onboarding con obiettivo: esiste la *Guida di Intonia* (tutorial delle
  funzioni, `lib/features/guide/`), ma nessuna scelta di obiettivo.
- [ ] Percorsi guidati per principianti: non esistono.
- [ ] Spike K0 di fattibilità del Karaoke Mode: non avviato.

**Karaoke Mode (K1–K3)** — [ ] non avviato, vedi `karaoke-architecture.md`.

**Store e monetizzazione**
- Il modello è cambiato: non più "acquisto unico", ma **Free con cariche +
  abbonamento Pro** (mensile/annuale). Sistema delle cariche ed entitlement
  implementati e testati (`charge_ledger_test`, `free_pro_access_test`,
  `free_pro_ui_test`); acquisti reali [ ] non integrati (sotto).
- [ ] Privacy policy pubblica e link nell'app.
- [ ] Schede store, screenshot e dichiarazioni (vedi `RELEASE_CHECKLIST.md`).

**Futuro (opzionale)** — ear training, intervalli, accordi, altri strumenti,
K4 cloud, cloud sync: [ ] non avviati; `lib/features/future_modules/`
contiene solo il registro dei moduli, senza funzionalità.

---

Di seguito i miglioramenti puntuali decisi ma rimandati.

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

### Intonia Pro: acquisti reali

**Stato:** architettura pronta, acquisti non integrati.

Oggi `entitlementSourceProvider` usa `NoPurchasesEntitlementSource`, che
restituisce sempre il piano Free. Il paywall (`ProScreen`) mostra i prezzi
(Mensile €4,99, Annuale €39,99) con i pulsanti disattivati
(`ProScreen.purchasesAvailable = false`): nessun acquisto è simulato.

Per attivare gli abbonamenti:

1. Creare i prodotti in abbonamento su App Store Connect e Google Play Console
   (stesso gruppo, piani mensile e annuale) e aggiornare i prezzi per paese.
2. Aggiungere un plugin di acquisti in-app (`in_app_purchase` o RevenueCat) e
   un `EntitlementSource` che legga lo stato dell'abbonamento, con
   `Entitlement.expiresAt` e la cache offline dell'ultimo stato verificato.
3. Verificare le ricevute lato server (App Store Server API / Google Play
   Developer API) o tramite RevenueCat; senza verifica l'abbonamento resta
   aggirabile.
4. Collegare "Abbonati" e "Ripristina acquisti", chiamare
   `EntitlementNotifier.refresh()` dopo acquisto e ripristino, aggiungere
   termini d'uso e informativa privacy richiesti dagli store.

Il sistema delle cariche non cambia: un utente Pro semplicemente non le consuma.

### Funzioni Pro in arrivo

- **Statistiche avanzate e grafici dei progressi**: non esistono ancora; oggi il
  profilo mostra solo le statistiche essenziali (gratuite) e lo storico
  (completo per Pro, ultime 8 sessioni per Free).
- **Percorsi personalizzati**: richiedono un modello di "percorso" (sequenza di
  esercizi con obiettivi) che l'app non ha ancora.

Quando esisteranno, si aggiungono a `ProFeature` e si controllano con
`Entitlement.allows`.

**Limite noto delle cariche:** senza backend, un orologio di sistema portato
avanti offline non è rilevabile; al massimo riempie le cariche fino a 7. Un
orologio portato indietro non fa guadagnare cariche (il riferimento si
riallinea a "adesso").
