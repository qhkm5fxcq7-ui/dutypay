# DUTYPAY — CHAT HANDOFF

## Baseline Attuale

Release:

**1.0.9 (Release Candidate)**

Stato generale:

- motore multi-reparto consolidato;
- Source of Truth unificata;
- Break Core implementato;
- regression pack estesi;
- flutter analyze senza warning;
- suite completa di test superata.

---

# Stato del Progetto

DutyPay è composto da due macro-moduli indipendenti:

## Core Economico

Comprende:

- gestione turni;
- straordinari;
- indennità;
- basket;
- compensativi;
- parser cedolino;
- dashboard;
- riepiloghi;
- previsione stipendiale.

## Break

Feature sociale indipendente dedicata alla scelta sincronizzata di chi offre il caffè.

È completamente separata dal motore economico.

---

# Reparti Attivi

## Reparto Mobile

Validato:

- soglia ordinaria 6h;
- overtime automatico;
- notturno ordinario;
- festivo;
- notturno festivo;
- OP;
- servizi esterni;
- multi-turno.

Status:

✅ STABILE

---

## Polfer

Validato:

- mattina;
- pomeriggio;
- sera;
- notte;
- controllo territorio;
- RFI;
- scheduled end;
- overtime programmato.

Status:

✅ STABILE

---

## Questura Uffici

Validato:

- override 6h;
- override 7h12;
- override personalizzato;
- straordinario automatico.

Status:

✅ STABILE

---

## Questura Volanti

Preset attivi:

- Mattina
- Pomeriggio
- Sera
- Notte

Validato:

- straordinario automatico;
- straordinario programmato;
- notturno;
- servizio esterno;
- preview;
- dettaglio turno.

Status:

✅ STABILE

---

# Source of Truth

La fonte di verità assoluta è:

BuildDailyShiftResultUseCase

Responsabile di:

- overtime;
- notturno;
- festivo;
- accessorie;
- benefit;
- compensativi;
- basket;
- breakdown;
- totale turno;
- totale giorno.

Nessun widget può eseguire calcoli economici autonomi.

---

# Pipeline Ufficiale

```
Shift
↓
CalculateShiftUseCase
↓
DepartmentPolicy
↓
ShiftCalculationResult
↓
BuildShiftComputationUseCase
↓
BuildDailyShiftResultUseCase
↓
Dashboard
Preview
Dettaglio turno
Cedolino
Summary
```

Tutta la UI deve leggere esclusivamente il risultato di questa pipeline.

---

# Basket Straordinari

Sistema dedicato.

Supporta:

- pagamento;
- correzioni manuali;
- residuo;
- proiezione cedolino.

Pipeline indipendente.

---

# Basket Compensativo

Pipeline separata.

Supporta:

- earned;
- recovered;
- adjustment.

Caratteristiche:

- basato esclusivamente su ore;
- nessun impatto economico;
- nessun impatto sul cedolino.

---

# Basket RFI

Pipeline completamente indipendente.

Flusso:

```
Scalo
↓
OPEN
↓
PAID
↓
Cedolino
```

Regole:

- non è overtime;
- non è accessoria;
- non è compensativo.

Utilizza esclusivamente:

```
rfiMonthlySummaries
```

---

# Programmed Overtime

Implementazione consolidata.

Supporta:

- segmento temporale;
- clamp automatico;
- destinazione pagamento;
- destinazione compensativa.

La validazione RFI tiene conto anche dello straordinario programmato.

---

# Parser Cedolini

Validato tramite fixture reali.

Copertura:

- RM Febbraio 2026;
- RM Marzo 2026;
- Polfer Marzo 2026.

Regola fondamentale:

utilizzare sempre l'ultima occorrenza del blocco:

"Assegni accessori"

---

# Benefit

Categorie:

- ticket meal;
- comfort;
- comfort_cdg.

Regole:

- amount = 0;
- benefitAmount valorizzato;
- isBenefit = true.

Mai inclusi in:

- totalAmount;
- extraAmount;
- cedolino.

---

# Break

Implementato:

- Domain Models;
- DTO;
- Repository;
- Datasource;
- Local Identity;
- Dependency Container;
- Firestore Paths;
- Challenge Engine;
- Code Generator.

Regression pack disponibili:

- Break Domain;
- Break DTO;
- Break Challenge Engine.

Da completare:

- integrazione UI finale;
- validazione multiplayer;
- Firestore Security Rules.

---

# Regression Pack

Disponibili:

- Core Calculation Engine;
- Reparto Mobile;
- Polfer;
- Questura;
- Multi Department;
- Basket Straordinari;
- Basket Compensativi;
- Basket RFI;
- Monthly Summary;
- Break Domain;
- Break DTO;
- Break Challenge Engine.

Ogni nuovo bug corretto deve introdurre almeno un nuovo regression test.

---

# Stato Validazione

Suite automatica:

**160/160 PASS**

Verifiche:

- flutter test ✅
- flutter analyze ✅

Nessun warning.

Nessun errore bloccante.

---

# Bug Aperti

Attualmente non risultano bug critici sul motore economico.

Restano da completare:

- test end-to-end Break;
- Firestore Security Rules;
- rifiniture UX Break.

---

# Cose da Non Rompere

- RM soglia 6h;
- Polfer scheduled end;
- Questura override ordinario;
- Preset Volanti;
- Basket Straordinari;
- Basket Compensativo;
- Basket RFI;
- Preview ↔ dettaglio;
- Breakdown ↔ totale;
- Totale giorno ↔ summary mese;
- Source of Truth centralizzata.

---

# Regole di Sviluppo

Qualsiasi modifica ai calcoli economici deve:

1. passare dal motore centrale;
2. evitare duplicazioni in UI;
3. mantenere coerenti preview e turno salvato;
4. aggiornare il regression pack interessato;
5. mantenere verde l'intera suite.

---

# Prompt di Ripartenza

Prima di qualsiasi sviluppo leggere:

1. SYSTEM_HANDOFF.md
2. ARCHITECTURE.md
3. CALCULATION_RULES.md
4. WORKFLOW_MASTER.md
5. CHAT_HANDOFF.md

Assumere sempre che:

- il motore economico sia consolidato;
- BuildDailyShiftResultUseCase sia la Source of Truth;
- Break sia una feature indipendente;
- ogni nuova modifica debba preservare la suite completa di regressione.

Obiettivo:

proseguire lo sviluppo senza introdurre regressioni, mantenendo la coerenza architetturale e la separazione tra Core Economico e Break.
## Break Validation

La feature Break è stata validata sia tramite test automatici che tramite test manuale multi-client.

Scenario verificato:

Host:
- crea stanza

Client:
- entra tramite codice

Entrambi:
- visualizzano gli stessi partecipanti
- sincronizzano il countdown
- sincronizzano la gara
- ricevono lo stesso vincitore

Stato:

✅ VALIDATO
## Stato corrente

Release stabile:

1.0.15 (45)

Validazioni completate:

- flutter analyze → PASS
- flutter test → 164 PASS
- flutter build appbundle → PASS
- flutter build ipa → PASS

Pubblicazione:

Android:
upload Google Play completato.

iOS:
IPA generata e caricata su App Store Connect.

Ultime correzioni:

- preview modifica turno con contesto giornaliero;
- ripristino toggle Servizio esterno Reparto Mobile.

Entrambe protette da regression test dedicati.

---

## AGGIORNAMENTO — FIX BASKET DOPPI/TRIPLI SERVIZI

Dopo la release 1.0.15 build 45 è stato diagnosticato un problema nel calcolo mensile del basket per servizi multipli appartenenti alla stessa `serviceDate`.

Il motore giornaliero context-aware calcolava correttamente lo straordinario, ma il riepilogo mensile non preservava completamente quel risultato nella ricostruzione del basket.

Il problema è stato riprodotto tramite backup reale di un tester.

Risultato diagnostico:

- basket precedente: 187.00 h
- basket corretto: 201.00 h
- differenza recuperata: 14.00 h

È stato corretto `BuildMonthlyAccessorySummaryUseCase` affinché utilizzi il risultato context-aware della `DailyShiftComputation`.

La regola architetturale da preservare è:

**stessa serviceDate → una sola quota ordinaria giornaliera → Daily Engine → Monthly Summary → Basket**

È stato aggiunto:

`test/regression/monthly_summary_daily_context_regression_test.dart`

Validazione completa successiva al fix:

- Flutter Analyze: PASS — No issues found
- Flutter Test: PASS — 165/165

Questo fix deve essere considerato candidato per la release 1.0.16.
