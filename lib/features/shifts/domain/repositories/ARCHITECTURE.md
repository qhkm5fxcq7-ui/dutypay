# DUTYPAY — ARCHITECTURE

## Obiettivo

Definire l'architettura ufficiale di DutyPay.

Questo documento descrive:

- componenti
- responsabilità
- pipeline dati
- vincoli architetturali

Non descrive roadmap o backlog.

---

# Architettura Generale

DutyPay è organizzata in tre livelli:

1. Presentation
2. Application
3. Domain

---

# Presentation Layer

Responsabilità:

- Flutter UI
- schermate
- cards
- dashboard
- calendario
- form inserimento turno
- preview

Può:

- leggere dati
- visualizzare dati

Non può:

- calcolare overtime
- calcolare importi
- classificare ore
- classificare festivi
- implementare logiche reparto

---

# Application Layer

Responsabilità:

- orchestrazione
- aggregazione
- costruzione summary
- costruzione pipeline economiche

UseCase principali:

- BuildDailyShiftResultUseCase
- BuildShiftComputationUseCase
- BuildMonthlySummaryUseCase
- BuildCompensativeBasketMovementsUseCase
- BuildCompensativeBasketSummaryFromMovementsUseCase

I UseCase NON devono contenere regole reparto.

---

# Domain Layer

Responsabilità:

- logiche reparto
- regole economiche
- classificazione ore
- overtime
- notturno
- festivo

---

# Source of Truth

La fonte di verità assoluta è:

BuildDailyShiftResultUseCase

Responsabile di:

- overtime
- notturno
- festivo
- OP
- servizi esterni
- compensativi
- breakdown
- totale turno
- totale giorno

Regola:

Qualsiasi schermata deve derivare dai risultati di questo motore.

---

# Pipeline Principale

Shift
↓
BuildDailyShiftResultUseCase
↓
BuildShiftComputationUseCase
↓
DepartmentPolicy
↓
DailyShiftResult
↓
UI / Summary / Cedolino

---

# Policy Reparto

Factory:

DepartmentPolicyFactory

Policy attive:

- RepartoMobilePolicy
- PolferPolicy
- QuesturaPolicy

---

# Reparto Mobile

Gestisce:

- soglia 6h
- overtime
- OP
- servizi esterni
- notturno
- festivo

---

# Polfer

Gestisce:

- scheduled end
- controllo territorio
- notturno
- scalo ferroviario

Regola:

nessuna soglia fissa 6h.

---

# Questura Uffici

Gestisce:

- ordinario configurabile
- overtime automatico

Supportati:

- 6h
- 7h12
- custom

---

# Questura Volanti

Preset:

- Mattina
- Pomeriggio
- Sera
- Notte

Regola:

servizio ordinario fino a fine preset

overtime dopo fine preset

Supporta:

- override ordinario
- straordinario programmato

---

# Programmed Overtime Architecture

Lo straordinario programmato è gestito come:

segmento temporale

Campi:

- programmedOvertimeEnabled
- programmedOvertimeStart
- programmedOvertimeEnd
- overtimeDestination

Pipeline:

Shift
↓
segment overlap
↓
clamp
↓
certain overtime

Destinazioni:

- payment
- compensative

---

# Basket RFI Architecture

Pipeline indipendente.

Flusso:

Turno con scalo
↓
rfiBasketGross
↓
OPEN
↓
PAID
↓
Cedolino

Separato da:

- overtime
- accessorie
- compensativi

Storage:

rfiMonthlySummaries

Mai utilizzare:

monthlySummaries

---

# Basket Compensativo Architecture

Pipeline indipendente basata su ore.

Domain Models:

- CompensativeBasketMovement
- CompensativeBasketSummary

Tipi:

- earned
- recovered
- adjustment

---

## Earned

Origine:

compensative overtime

---

## Recovered

Origine:

assenza Recupero compensativo

---

## Adjustment

Origine:

utente

Regole:

- nota obbligatoria
- positivo o negativo
- eliminabile

---

## Runtime Merge

BuildCompensativeBasketMovementsUseCase(shifts)
+
manualCompensativeBasketMovements
=
compensativeBasketMovements

---

# Cedolino Architecture

Pipeline:

Breakdown turno
↓
Aggregazione mensile
↓
Esclusione benefit
↓
Esclusione RFI
↓
Totale lordo
↓
Fiscalità stimata
↓
Netto previsto

---

# Benefit Architecture

Categorie:

- ticket_meal
- comfort
- comfort_cdg

Regole:

- amount = 0
- benefitAmount valorizzato
- isBenefit = true

Mai inclusi in:

- totalAmount
- extraAmount
- cedolino

---

# Parser Cedolini

Validato tramite fixture reali.

Copertura:

- RM Febbraio 2026
- RM Marzo 2026
- Polfer Marzo 2026

Regola:

utilizzare sempre l'ultima occorrenza del blocco:

"Assegni accessori"

---

# Vincoli Architetturali

È vietato:

- logica economica in UI
- duplicazione Shift/Policy
- fallback legacy
- merge breakdown legacy
- uso monthlySummaries per RFI
- calcoli paralleli nella preview

---

# Baseline

Release:

DutyPay 1.0.5

Reparti:

- Reparto Mobile
- Polfer
- Questura Uffici
- Questura Volanti

Stato:

ARCHITETTURA STABILE