# Karaoke Mode ("SingStar") — Architettura a step

> Stato: **in roadmap, non in sviluppo**. Decisione presa: partire dai file
> locali dell'utente (unica strada legale e offline); Spotify escluso (ToS),
> YouTube solo come eventuale sorgente di riproduzione in fase K3.

## Idea

L'utente sceglie un brano, l'app estrae la melodia vocale di riferimento,
parte un karaoke con piano-roll stile SingStar; a fine brano: note prese su
totali, errori, e **consigli con esercizi mirati** presi dalla libreria
esistente (il vero valore aggiunto rispetto a SingStar).

Requisito d'uso: **cuffie** (altrimenti il mic sente il brano oltre alla voce).

---

## Fase K0 — Spike di fattibilità (go/no-go)

Obiettivo: validare la qualità dell'estrazione melodica on-device prima di
investire nel resto.

- Candidati per la trascrizione: **Basic Pitch** (Spotify, Apache-2.0, esiste
  in versione leggera) o **CREPE tiny** via `tflite_flutter`.
- Test su 8–10 brani reali di generi diversi (pop voce in evidenza, rock,
  ballad, rap come caso negativo atteso).
- Metriche: % note corrette vs trascrizione manuale di un ritornello,
  tempo di elaborazione su un device medio, dimensione del modello in app.
- Soglia di go: melodia "cantabile" (≥80% note giuste su pop/ballad),
  elaborazione < 1 min per brano da 3–4 min.

## Fase K1 — MVP: karaoke da file locali

1. **Import**: file picker (mp3/m4a/wav/flac), metadati, libreria brani locale.
2. **Pipeline di analisi** (one-shot, on-device, risultato in cache):
   - (opzionale, se K0 lo richiede) separazione vocale leggera;
   - pitch tracking frame-by-frame sul brano;
   - segmentazione in note (onset/offset, filtro durate minime, quantizzazione
     leggera) → **melody track** JSON: `[{startMs, durMs, midi}]`;
   - salvataggio in cache per i replay istantanei.
3. **Player sincronizzato**: `just_audio`, posizione ↔ melody track,
   offset di latenza calibrabile (riuso della calibrazione esistente).
4. **UI piano-roll**: note in arrivo che scorrono (CustomPainter, riuso
   dell'esperienza del pentagramma), linea "now", pitch dell'utente disegnato
   sopra in tempo reale, colori presa/mancata.
5. **Scoring**: per nota (% di copertura entro tolleranza, cent medi),
   per frase, combo; punteggio finale.
6. **Risultati**: prese/totali, sbagliate, grafico per sezione del brano.
7. **Check cuffie**: warning bloccante se non rilevate.

Riuso dall'app attuale: YIN + banda bassa, anti-feedback, calibrazione rumore,
state machine di validazione (adattata: qui il tempo lo detta il brano).

## Fase K2 — Report intelligente + esercizi suggeriti

- Classificazione degli errori: calante sugli acuti / crescente sui gravi,
  salti d'intervallo mancati, attacchi imprecisi, discese strascicate.
- Mapping pattern → categorie della libreria (estensione alta → arpeggi 8ª e
  test estensione; salti → salti di terza; discese → scale discendenti).
- Schermata consigli con deep-link agli esercizi; risultato salvato nello
  storico sessioni del profilo.

## Fase K3 — Catalogo esteso (valutazione legale caso per caso)

- Import file **UltraStar** (.txt) forniti dall'utente: melodia+testo pronti,
  niente analisi.
- **YouTube embed** come sola sorgente di riproduzione (player ufficiale),
  melody track da file utente o precalcolata: da validare sui ToS.
- Testi sincronizzati: file LRC dell'utente; Musixmatch API solo se si va
  su licenze a pagamento.

## Fase K4 — Cloud (opzionale, cambia il modello di costi)

- Separazione vocale di qualità (Demucs) server-side, catalogo condiviso di
  melody track tra utenti (solo dati derivati, da validare legalmente),
  account e sync.

---

## Rischi principali

| Rischio | Mitigazione |
|---|---|
| Qualità estrazione su generi difficili | K0 decide; UI mostra "confidenza" della trascrizione |
| Latenza audio Android (sync brano/mic) | offset calibrabile + compensazione per-device |
| Peso modelli ML (10–40 MB) | download on-demand al primo uso |
| Mic sente il brano | obbligo cuffie + AEC già attivo |
| Store review (sorgenti audio) | K1 usa solo file dell'utente: nessun problema |

## Posizione in roadmap

- **K0** può partire in qualsiasi momento (è uno spike isolato).
- **K1–K2** dopo la Fase 3 (apertura al pubblico).
- Il Karaoke Mode è il candidato naturale a **modulo premium** della Fase 4
  (monetizzazione): è la feature "wow" che giustifica l'acquisto.
