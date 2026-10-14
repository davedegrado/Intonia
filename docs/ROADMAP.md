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
