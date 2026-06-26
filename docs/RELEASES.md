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
