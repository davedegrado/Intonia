# Localizzazione

L'interfaccia usa il sistema standard di Flutter (`flutter_localizations` +
`gen_l10n`, configurato in `l10n.yaml`). Tutte le traduzioni sono incluse
nell'app e funzionano offline.

- Testi: `lib/l10n/app_en.arb` (riferimento e fallback) e `lib/l10n/app_it.arb`.
  Le classi `AppLocalizations` vengono generate con `flutter gen-l10n` (anche
  automaticamente da `flutter pub get` / build).
- Nei widget: `context.l10n.chiave` (`lib/app/l10n.dart`); dove non c'è un
  `BuildContext` (controller): `ref.read(l10nProvider)`.
- Ampiezze ("2 ottave + 7 semitoni"): `l10n.span(semitoni)`. Esercizi
  predefiniti, categorie e obiettivi: `lib/l10n/exercise_l10n.dart` (i dati
  interni e le sessioni salvate restano invariati).

## Lingua

Ordine di scelta (`appLocaleProvider`): lingua scelta nelle Impostazioni
(salvata in `app_settings.json`, chiave `language`) → lingua del dispositivo se
supportata → inglese.

Il widget della schermata Home usa la stessa lingua dell'app: l'app la salva
nei dati condivisi (`intonia_language`, vedi `HomeWidgetService`) a ogni avvio
e a ogni cambio; finché non l'ha mai salvata, il widget segue la lingua del
dispositivo.

## Notazione delle note

Indipendente dalla lingua. Default per chi non ha mai salvato una scelta:
C D E (internazionale); una scelta già salvata (anche DO RE MI) resta.
La conversione è centralizzata in `NoteSpeller` / `NoteText`.

## Aggiungere una lingua (es. spagnolo)

1. Copiare `lib/l10n/app_en.arb` in `lib/l10n/app_es.arb`, impostare
   `"@@locale": "es"` e tradurre **tutte** le chiavi (senza le voci `@chiave`).
2. Aggiungere il caso `'es'` in `exercise_l10n.dart` se servono eccezioni
   (di norma no: usa le chiavi ARB).
3. Aggiungere l'opzione nella sezione Lingua delle Impostazioni
   (`settings_screen.dart`) e la chiave `languageSpanish` negli ARB.
4. Widget nativo: `android/app/src/main/res/values-es/strings.xml` e il ramo
   corrispondente in `WidgetStrings` (`ios/IntoniaWidget/IntoniaWidget.swift`).
5. `flutter gen-l10n`, `flutter analyze`, `flutter test`.

Per pt_BR il file è `app_pt_BR.arb` (`"@@locale": "pt_BR"`).
