# Checklist manuale audio

I test automatici coprono la logica (rilevamento pitch su segnali sintetici,
macchina a stati, ciclo di vita di microfono e piano con servizi finti).
Latenza reale, precisione dell'intonazione e interazione tra riproduzione e
microfono **non sono verificabili senza hardware**: eseguire questa checklist
su almeno un dispositivo Android e un iPhone (idealmente anche un Android di
fascia bassa e un iPad) prima di ogni rilascio.

Annotare per ogni prova: dispositivo, versione OS, build, esito, note.

## Permessi

1. Installazione pulita → *Riconoscimento in tempo reale → Avvia*: compare la
   richiesta di permesso; concedendolo il tuner parte senza dover premere di
   nuovo *Avvia*.
2. Installazione pulita → negare il permesso: il tuner mostra "Permesso
   microfono negato"; nel Trainer (modalità Allenamento) *Play* mostra il
   messaggio di errore e lo stato torna "Pronta"; idem nel Test estensione.
3. Revocare il permesso dalle impostazioni di sistema con l'app aperta, poi
   tornare all'app e premere *Play*: nessun crash, messaggio di errore.

## Riproduzione (SoundFont)

4. Modalità Ascolto, una scala a 72 BPM: tutte le note suonano, la nota
   evidenziata segue l'audio, a fine sequenza lo stato torna "Pronta".
5. Ascolto con Loop: *Stop* ferma subito il suono; premere *Stop* e subito
   *Play* più volte di fila: mai due sequenze sovrapposte.
6. Sequenza custom con note ripetute (es. DO-DO-DO): ogni ripetizione si
   sente per intero, senza troncamenti.
7. Volume: la guida si sente dall'altoparlante (non dalla capsula auricolare
   su iPhone) anche mentre il microfono è attivo.

## Riconoscimento

8. Tuner: cantare/suonare LA4 (440 Hz, es. da un'app accordatore o un
   diapason) → mostra LA4 con scarto entro ±5 cent.
9. Note gravi: DO2 (65 Hz) e, se possibile, MI1 (41 Hz, vocal fry) vengono
   riconosciute senza salti d'ottava.
10. Note acute: DO6 (1047 Hz) riconosciuta; oltre ~1100 Hz nessun valore
    spurio.
11. Silenzio in stanza tranquilla: nessuna nota rilevata. Con rumore di fondo
    (ventola, TV bassa): eseguire *Calibra rumore di fondo* e verificare che
    non compaiano note fantasma.
12. Errori d'ottava: cantare la nota giusta un'ottava sopra/sotto → segnata
    come errore (non corretta).

### Voce reale: tolleranza e stabilità

Parametri in `lib/core/pitch/pitch_recognition_config.dart` (tolleranza
esercizi ±35 cent, test di estensione ±40, cambio al semitono vicino dopo
80 ms, cadute di segnale fino a 100 ms ignorate). Da provare con più voci
(maschile/femminile, con e senza vibrato):

- 12a. Nota tenuta con vibrato naturale: nella Home la nota mostrata non
  cambia; negli esercizi viene convalidata.
- 12b. Nota leggermente calante/crescente (circa 25–30 cent): negli esercizi
  è convalidata con la tolleranza predefinita; con tolleranza ±10 no.
- 12c. Passaggio legato tra due note vicine (DO→DO#, MI→FA): la nota mostrata
  segue la voce senza ritardo fastidioso e non resta "attaccata" alla
  precedente.
- 12d. Scala cantata a tempo sostenuto (72–100 BPM): ogni nota viene convalidata
  e non si saltano note.
- 12e. Consonanti e attacchi (cantare su "da", "la", "ma"): la nota non sparisce
  a ogni consonante.
- 12f. Nella Home il nome della nota (DO, RE…) è l'elemento principale;
  l'ottava è leggibile ma secondaria.

## Allenamento e ciclo di vita

13. Allenamento con "Suona la guida su ogni nota" attivo: la guida suonata
    dall'app **non** viene convalidata come voce (non deve avanzare da sola).
14. Completare un esercizio: la sessione compare nel Profilo con le
    statistiche corrette.
15. Durante un allenamento: tornare indietro alla Home → l'indicatore di
    registrazione del sistema (pallino arancione/verde) si spegne.
16. Durante un allenamento: mandare l'app in background (Home del telefono) →
    microfono spento; al rientro lo stato è "Pronta" e la sessione parziale è
    nello storico.
17. Telefonata o allarme durante l'allenamento: nessun crash; dopo
    l'interruzione *Play* riparte normalmente.
18. Cuffie cablate/Bluetooth collegate e scollegate durante l'uso: nessun
    crash; annotare eventuale latenza percepita (Bluetooth).
19. Test estensione: completare discesa e salita; uscire a metà test o
    mandare l'app in background → microfono spento, test non salvato.

## Prestazioni

20. Dieci minuti di allenamento continuo: nessun rallentamento dell'interfaccia,
    nessun riscaldamento anomalo; annotare la latenza percepita tra voce e
    feedback.
