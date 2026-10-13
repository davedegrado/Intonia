# SoundFont

Il player (`lib/services/audio/piano_audio_service.dart`) carica
`assets/soundfonts/piano.sf2` tramite `flutter_midi_pro`, banco 0, programma 0.

## Stato licenza: NON VERIFICATA ⚠️ — blocco per la pubblicazione

Analisi del file attuale (ottobre 2026):

| Campo | Valore |
|---|---|
| SHA-256 | `ebe131b54d897d88bf1ed3936c044ba2d0c9282bfbf2ca22aab6c993865889a0` |
| Dimensione | 5.288.994 byte |
| `INAM` (nome banco) | `User Bank` |
| `isng` / `ISFT` | `E-mu 10K1` / `SFEDT v1.29:SFEDT v1.28:` |
| Preset | `Piano` (banco 0, programma 0) |
| Strumenti | `Dampers`, `Piano CF 111 forte` |
| Campioni | 38 (stereo, es. `Gb4LF`/`Gb4RF`) |
| Copyright / commenti (`ICOP`, `ICMT`, `IENG`) | assenti |

Il file non contiene autore, copyright né licenza. Il nome dello strumento
suggerisce campioni di un pianoforte da concerto, ma una ricerca sul nome non
ha individuato una fonte pubblica identificabile. **Origine e licenza non sono
verificabili: il file non va considerato distribuibile commercialmente.**
È mantenuto solo per non rompere l'app durante lo sviluppo.

## Come sostituirlo

1. Scegliere un SoundFont di pianoforte la cui licenza, letta **alla fonte
   ufficiale**, consenta esplicitamente redistribuzione all'interno di
   un'app commerciale (inclusi store a pagamento / con acquisti in-app).
   Candidati da verificare (le condizioni non sono state confermate da questo
   ambiente perché i siti non erano raggiungibili):
   - *GeneralUser GS* (S. Christian Collins) — licenza propria che, secondo
     l'autore, permette l'uso in software anche commerciale; leggere il file
     di licenza incluso nella versione scaricata.
   - *FluidR3_GM* — distribuito come MIT (es. pacchetto Debian
     `fluid-soundfont-gm`); verificare il file `copyright` del pacchetto.
   - *Salamander Grand Piano* (Alexander Holm) — CC-BY 3.0: attribuzione
     obbligatoria; richiede conversione in SF2.
2. Estrarre solo il preset di pianoforte (es. con Polyphone) per contenere la
   dimensione, salvandolo come banco 0 / programma 0, oppure aggiornare
   `bank`/`program` in `PianoAudioService`.
3. Sostituire `piano.sf2` mantenendo lo stesso nome (o aggiornare
   `_assetPath` in `PianoAudioService` e `pubspec.yaml`).
4. Conservare accanto al file la licenza originale (es. `piano.LICENSE.txt`)
   e aggiornare questa pagina con fonte, versione, URL e SHA-256.
5. Aggiornare i crediti in *Impostazioni → Info*
   (`lib/features/settings/presentation/settings_screen.dart`) con autore e
   licenza, se richiesto (obbligatorio per CC-BY).
6. Verificare su dispositivo i punti "Riproduzione" di
   `docs/AUDIO_MANUAL_TEST_CHECKLIST.md` (estensione delle note, volume,
   note ripetute).
