# DUTYPAY – ARCHITETTURA

## Struttura generale

L'app è divisa in 3 livelli:

### 1. ENTITIES (core logico)
- Shift
- UserPayProfile

Contengono:
- dati
- logiche di base (calcoli grezzi)

---

### 2. ENGINE (logica per reparto)

Ogni reparto ha una sua policy:

- RepartoMobilePolicy
- PolferPolicy

Ogni policy:
- riceve Shift + UserPayProfile
- restituisce ShiftCalculationResult

NON deve:
- sapere nulla della UI
- duplicare logiche presenti in Shift

---

### 3. USE CASE

BuildShiftComputationUseCase

Serve per:
- trasformare il risultato dell’engine in dati per la UI
- unire:
  - risultato engine
  - logiche legacy Shift

---

## Flusso dati

UI → Shift → UseCase → Policy → Result → UI

---

## Regola fondamentale

- La logica vive nelle Policy
- La UI NON deve calcolare nulla
- Shift contiene solo logiche di base riutilizzabili

---

## Problemi attuali noti

- duplicazione logica tra Shift e Policy
- Polfer ha logica mista (6h vs orari teorici)
- basket RFI non completamente isolato

---

## Obiettivo architetturale

- ogni reparto completamente isolato
- nessuna duplicazione
- aggiunta nuovi reparti semplice (plug & play)
## Vincoli architetturali avanzati

### Separazione totale RFI
Il flusso RFI è completamente separato da:
- accessorie normali
- overtime standard
- reference month

### Pipeline doppia
- monthlySummaries → accessorie normali
- rfiMonthlySummaries → RFI

Questi flussi NON devono mai essere unificati.
# DUTYPAY — ARCHITECTURE (UPDATED)

## Core Principle
The system is built around a strict separation:

- UI → presentation only
- UseCases → orchestration only
- Engine (Policy) → single source of truth

NO business logic must live in:
- UI
- Shift model (legacy only allowed for transitional data)

---

## Calculation Flow (Final)

Shift → DepartmentPolicy → ShiftCalculationResult  
→ BuildShiftComputationUseCase  
→ BuildShiftMoneyComponentsUseCase  
→ Daily → Monthly → Payslip

---

## Source of Truth

### Overtime
ONLY from:
DepartmentPolicy → ShiftCalculationResult

Never from:
- Shift.overtimeHours
- legacy calculations

---

### Breakdown
Comes from:
result.breakdown (engine)

Then enriched ONLY with:
- order public
- external service
- comfort
- manual extra
- Polfer scalo (RFI basket)

NO legacy merge allowed.

---

## Basket Separation

### Overtime Basket (Reparto Mobile)
- generated only above monthly payable limit
- paid manually by user
- not immediate

### RFI Basket (Polfer)
- generated immediately at shift level
- excluded from:
  - stipendio
  - accessorie normali
- stored separately
- paid manually (≈ every 3 months)

---

## Money Flow Separation

Each shift is split into:

- overtimeGross
- nonOvertimeGross
- rfiBasketGross

These flows MUST remain separated until final aggregation.

---

## Monthly Aggregation

### MonthlySummary
- UI/analytics
- includes RFI for visibility

### MonthlyAccessorySummary
- economic aggregation
- still includes RFI (NOT filtered here)

Filtering for payslip happens later.

---

## Key Rule

RFI is NOT:
- overtime
- accessory PdS
- part of payslip projection

It is a separate financial flow.
# PAYSLIP UI — LINEE GUIDA

## OBIETTIVO

Mostrare una simulazione fiscale chiara e affidabile del mese.

---

## TERMINOLOGIA UFFICIALE

- Netto previsto → valore principale
- Accessorie lorde stimate → componenti accessorie
- Base netta stimata → stipendio fisso

---

## HERO CARD

Contiene:
- mese
- netto previsto (numero principale)
- indicatore precisione
- microcopy fiscale

Microcopy:
"Il netto previsto deriva da una proiezione fiscale basata sui cedolini caricati."

---

## SUMMARY

Sezione:
- Base netta stimata
- Accessorie lorde stimate
- Netto previsto (totale)

---

## BREAKDOWN

Mostra:
- Base netta
- Accessorie lorde stimate
- Trattenute
- Totale finale stimato

---

## DISCLAIMER

La pagina:
- NON sostituisce NoiPA
- è una proiezione fiscale
- migliora con calibrazione

---

## NOTA TECNICA (IMPORTANTE)

Attualmente:
- alcune voci mostrate come “lorde” derivano da valori netti stimati

Motivo:
- evitare refactor dell’engine in questa fase

Stato:
- accettato per release
- da riallineare in futura revisione engine
## RFI Basket Architecture

Il sistema RFI è separato dal basket straordinari.

### Componenti:
- MonthlyAccessorySummary.rfiBasketGross
- RfiBasketOpenEntry
- RfiBasketPaidEntry
- RfiBasketPayment

### Flusso:
Shift → MonthlySummary → RFI Basket

### Nota:
Non condivide logica con:
- overtime basket
- accessory delay system
## Stato dopo il fix parser cedolini

Dopo la correzione del parser e la validazione automatica:
- il caricamento dei cedolini reali produce valori coerenti
- la schermata delle rate derivate dai cedolini può basarsi su dati realmente letti
- la parte parser è da considerarsi stabilizzata e pronta per il rilascio, salvo nuovi bug emersi dai tester reali
## Segmented Programmed Overtime Architecture

Programmed overtime is not a global whole-shift flag anymore.

The calculation flow is:

```text
Shift
 ├─ actual worked interval
 ├─ optional programmed overtime interval
 ├─ optional ordinary-hours override
 └─ overtime destination

## 2. `ARCHITECTURE.md`

Aggiungi:

```md
## Compensative Basket Architecture

The Compensative Basket is an independent hours pipeline.

### Domain models

- `CompensativeBasketMovement`
- `CompensativeBasketSummary`

Movement types:
- `earned`
- `recovered`
- `adjustment`

### Movement sources

Automatic movements:
- generated from shifts at runtime
- `earned` comes from compensative overtime
- `recovered` comes from absence `Recupero compensativo`
- automatic movements are not persisted separately
- automatic movements are not manually deletable

Manual movements:
- persisted separately
- currently only `adjustment`
- can be positive or negative
- require a note
- can be deleted by the user

### Runtime merge

```text
BuildCompensativeBasketMovementsUseCase(shifts)
+
manualCompensativeBasketMovements from SharedPreferences
=
compensativeBasketMovements
DepartmentPolicyFactory

Reparti supportati:

- Reparto Mobile
- Polfer
- Questura Uffici
- Questura Volanti

Questura Volanti:

Preset:
- Mattina
- Pomeriggio
- Sera
- Notte

Calcolo:
- servizio ordinario fino a fine preset
- straordinario automatico dopo fine preset
- supporto override manuale
- supporto straordinario programmato

Source of truth:
BuildDailyShiftResultUseCase
