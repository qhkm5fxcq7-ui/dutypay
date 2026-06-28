# DUTYPAY — BACKLOG

## Stato Attuale

Release corrente:

**1.0.9 (Release Candidate)**

Stato generale:

- motore economico consolidato;
- architettura stabilizzata;
- regressioni automatiche complete;
- flutter analyze pulito;
- suite completa di test superata.

---

# PRIORITÀ CRITICA

Attualmente nessun task critico aperto sul Core Engine.

Il motore di calcolo è considerato stabile.

---

# PRIORITÀ ALTA

## Break — UI Finale

Completare:

- dialog nickname;
- creazione stanza;
- join tramite codice;
- BreakRoomPage definitiva;
- gestione Ready;
- gestione Start;
- card risultato finale;
- UX definitiva.

Status:

IN CORSO

---

## Break — Multiplayer Reale

Validare:

- sincronizzazione Firestore;
- partecipanti realtime;
- round sincronizzati;
- reset stanza;
- recovery dopo disconnessione.

Status:

TODO

---

## Break — Firestore Security Rules

Completare:

- regole di accesso;
- validazione scritture;
- protezione documenti;
- protezione roomCode.

Status:

TODO

---

# PRIORITÀ MEDIA

## Export / Import

Completare:

- backup completo;
- restore completo;
- esportazione selettiva;
- importazione con validazione.

Status:

TODO

---

## Turnario Annuale

Implementare:

- generazione automatica;
- supporto reparti;
- integrazione calendario.

Status:

TODO

---

## Missioni Evolute

Espandere:

- missioni multi-giorno;
- riepiloghi dedicati;
- gestione indennità.

Status:

TODO

---

## Feedback In-App

Implementare:

- invio bug;
- suggerimenti;
- feedback utenti.

Status:

TODO

---

# PRIORITÀ BASSA

## Cedolino Pro

Valutare:

- simulazioni avanzate;
- scenari fiscali;
- statistiche annuali;
- comparazione mensile.

Status:

BACKLOG

---

## Dashboard Evoluta

Possibili estensioni:

- grafici;
- trend;
- statistiche;
- KPI personali.

Status:

BACKLOG

---

## Ottimizzazioni Performance

Da eseguire solo se emergono problemi reali.

Possibili attività:

- profiling;
- riduzione rebuild;
- caching;
- ottimizzazione stream.

Status:

BACKLOG

---

# FUTURE RELEASES

Nuovi reparti saranno sviluppati solo dopo il completamento della Release 1.0.9.

Possibili candidati:

- Digos;
- Squadra Mobile;
- Frontiera;
- Reparti specialistici.

L'implementazione dovrà riutilizzare il motore multi-reparto esistente senza introdurre nuove duplicazioni.

---

# ATTIVITÀ COMPLETATE (NON PIÙ IN BACKLOG)

Completate durante la Release Candidate 1.0.9:

- motore multi-reparto;
- CalculateShiftUseCase;
- Source of Truth centralizzata;
- QuickAddShiftPage allineata al motore;
- regressioni Core Engine;
- regressioni Reparto Mobile;
- regressioni Polfer;
- regressioni Questura;
- regressioni Multi Department;
- regressioni Basket Straordinari;
- regressioni Basket Compensativi;
- regressioni Monthly Summary;
- regressioni Break Domain;
- regressioni Break DTO;
- regressioni Break Challenge Engine;
- validazione RFI con straordinario programmato;
- consolidamento pipeline economiche.

---

# Regole del Backlog

Ogni nuovo task deve:

- indicare la priorità;
- specificare il modulo coinvolto;
- riportare eventuali regression test richiesti.

Ogni bug corretto deve:

1. essere aggiunto a `KNOWN_BUGS_RESOLVED.md`;
2. introdurre almeno un nuovo regression test;
3. mantenere verde l'intera suite automatica.

---

# Stato Finale

Core Economico:

✅ Consolidato

Break Backend:

✅ Consolidato

Break UI:

🟡 In completamento

Release Candidate:

🟢 Stabile e pronta per il completamento della fase finale di integrazione.