# DutyPay Releases

## Obiettivo

Tenere traccia delle release principali di DutyPay, delle modifiche introdotte e delle decisioni tecniche rilevanti.

Questo documento non sostituisce Git, ma offre una vista leggibile dell'evoluzione del prodotto.

---

## 1.0.7

### Stato

In stabilizzazione.

### Novità principali

- Break / Chi offre? v1.
- Stanze multiplayer.
- Codici personalizzati.
- Countdown.
- Gara.
- Suspense.
- Risultato condiviso.
- Card finale rifinita.
- Firebase Analytics.
- Firebase Crashlytics.
- Monitoraggio release Android.

### Fix critici

- Correzione crash Android `[core/duplicate-app]`.
- Rimozione FirebaseOptions manuali su Android.
- Uso di `Firebase.initializeApp()` automatico con `google-services.json`.

### Note

La build `1.0.7+26` è la release di riferimento per verificare la stabilità Android dopo il fix Firebase.

---

## 1.0.5

### Stato

Base stabile precedente.

### Novità principali

- Consolidamento del motore multi-reparto.
- Espansione Questura.
- Supporto Volanti.
- Miglioramento preview economica.
- Rifiniture dashboard.

---

## 1.0.4

### Stato

Release di espansione iniziale.

### Novità principali

- Introduzione Questura.
- Preset Uffici.
- Preset Volanti.
- Calendario turnazione.
- Miglioramento gestione notturni.

---

## Regole release

Ogni release deve avere:

- version bump corretto;
- test verdi;
- build generata;
- changelog sintetico;
- monitoraggio post-release;
- verifica Crashlytics;
- verifica Android Vitals / App Store Connect dove applicabile.

---

## Monitoraggio post-release

Dopo ogni release controllare:

- Crashlytics;
- Analytics;
- Android Vitals;
- feedback utenti;
- recensioni store.

---

## Nota strategica

Le release non devono essere valutate solo per le funzionalità introdotte.

Ogni release deve migliorare almeno uno di questi aspetti:

- precisione;
- affidabilità;
- esperienza utente;
- stabilità;
- coerenza del prodotto.
## 1.0.9

### Stato

Release Candidate.

### Novità principali

- Consolidamento definitivo del motore multi-reparto.
- `BuildDailyShiftResultUseCase` confermato come unica Source of Truth per il calcolo economico.
- Introduzione del `CalculateShiftUseCase` come punto di accesso unico al motore di calcolo.
- Eliminazione delle ultime duplicazioni di logica tra motore e UI.
- Allineamento completo tra preview, turno salvato, dashboard e riepiloghi mensili.
- Miglioramento della validazione dello scalo manuale RFI in presenza di straordinario programmato.
- Rifiniture del modulo Break e del Challenge Engine.

### Copertura di test

Nuovi regression pack dedicati per:

- Core Calculation Engine
- Reparto Mobile
- Polfer
- Questura
- Multi Department
- Basket Compensativi
- Basket RFI
- Monthly Summary
- Break Domain
- Break DTO
- Break Challenge Engine

### Qualità della release

- Flutter Analyze: **0 issues**
- Flutter Test: **156 test automatici superati**
- Working tree pulito
- Regressioni critiche coperte

### Note

Questa release rappresenta il consolidamento dell'architettura introdotta con il motore multi-reparto e costituisce la nuova baseline tecnica del progetto. L'obiettivo principale è garantire coerenza dei calcoli, ridurre il rischio di regressioni e facilitare l'estensione futura verso nuovi reparti e nuove funzionalità.
