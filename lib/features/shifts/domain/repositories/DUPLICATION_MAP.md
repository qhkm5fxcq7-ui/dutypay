# DUTYPAY – DUPLICATION MAP

## Obiettivo

Identificare e rimuovere tutte le duplicazioni logiche tra:
- Shift (entity)
- Policy (engine)
- UseCase (application)

---

## PROBLEMA ATTUALE

Oggi esistono duplicazioni critiche tra:

### Shift
- _buildOvertimeSegments
- _calculateNightOnlyHours
- _calculateBandHours
- overtimeHours
- segmentedOvertime*

### RepartoMobilePolicy
- _buildOvertimeSegments
- _calculateNightHours
- _overlapMinutes
- _isNightMoment
- _isHolidayDate

### PolferPolicy
- _calculateBandHours
- _overlapMinutes
- gestione ore giorno/notte
- logica simile ma non identica a Shift

---

## RISCHIO

- bug silenziosi
- incoerenza tra preview e salvataggio
- regressioni quando si modifica una sola parte
- comportamento diverso tra reparti
- difficoltà nel debugging

---

## PRINCIPIO ARCHITETTURALE

UNA SOLA FONTE DELLA VERITÀ

### Regola chiave:
- Shift NON deve contenere logica di business di reparto
- Policy è il cervello del calcolo
- UseCase orchestra, NON calcola

---

## CLASSIFICAZIONE LOGICA

### 1. LOGICA BASE (deve stare in Shift o helper condivisi)

✔ consentita in Shift:
- normalizzazione date
- start/end
- crossesMidnight
- serializzazione JSON
- helper generici senza logica di business

❌ NON deve stare in Shift:
- straordinario
- segmentazione notte/giorno
- logica festivi avanzata
- breakdown economico
- logiche Polfer/RM

---

### 2. LOGICA DI CALCOLO (deve stare SOLO nelle Policy)

✔ deve stare in Policy:
- soglia straordinario
- segmentazione ore
- classificazione notte/giorno
- classificazione festivo
- calcolo importi
- logiche specifiche reparto

---

### 3. ORCHESTRAZIONE (UseCase)

✔ deve stare nei UseCase:
- merge breakdown
- esclusione basket da extraAmount
- adattamento dati per UI

❌ NON deve fare:
- calcoli complessi
- logiche reparto

---

## DUPLICAZIONI IDENTIFICATE

### 🔴 BLOCCO 1 — OVERTIME SEGMENTATION

Duplicata in:
- Shift._buildOvertimeSegments
- RepartoMobilePolicy._buildOvertimeSegments

👉 DESTINAZIONE CORRETTA:
➡ Policy

👉 AZIONE:
- rimuovere da Shift
- mantenere solo in Policy

---

### 🔴 BLOCCO 2 — NIGHT HOURS

Duplicata in:
- Shift._calculateNightOnlyHours
- RepartoMobilePolicy._calculateNightHours

👉 DESTINAZIONE:
➡ Policy

---

### 🔴 BLOCCO 3 — BAND HOURS (giorno/notte)

Duplicata in:
- Shift._calculateBandHours
- PolferPolicy._calculateBandHours

👉 DESTINAZIONE:
➡ helper condiviso nel dominio OPPURE Policy

---

### 🔴 BLOCCO 4 — HOLIDAY LOGIC

Duplicata in:
- Shift._isHolidayDate
- Policy

👉 DESTINAZIONE:
➡ helper condiviso (es: date_utils.dart)

---

### 🔴 BLOCCO 5 — OVERTIME HOURS

In Shift:
- overtimeHours
- segmentedOvertime*

In Policy:
- overtimeHours calcolato diversamente

👉 PROBLEMA:
2 verità diverse

👉 DESTINAZIONE:
➡ SOLO Policy

---

### 🔴 BLOCCO 6 — BREAKDOWN

Duplicazione tra:
- Shift.getBreakdown
- Policy breakdown

👉 DESTINAZIONE:
➡ SOLO Policy

---

## STRATEGIA DI RISOLUZIONE

### FASE 1 (SICURA)
- NON cancellare subito codice da Shift
- smettere di usarlo nei UseCase

### FASE 2
- far usare SOLO:
  Policy → Result → UseCase

### FASE 3
- eliminare gradualmente metodi da Shift

---

## REGOLE OPERATIVE

1. Se una logica riguarda:
   - RM o Polfer → deve stare in Policy

2. Se una logica calcola soldi → Policy

3. Se una logica segmenta ore → Policy

4. Shift deve diventare:
   👉 puro contenitore dati + helper base

---

## OBIETTIVO FINALE

Arrivare a questo flusso:

Shift (dati)
    ↓
Policy (calcolo completo)
    ↓
ShiftCalculationResult
    ↓
UseCase (adattamento)
    ↓
UI

---

## STATO ATTUALE

Sistema funzionante ma con duplicazioni.

Priorità:
1. eliminare duplicazioni overtime
2. eliminare duplicazioni notte/giorno
3. eliminare breakdown da Shift
## Stato dopo refactor engine base

Completata la centralizzazione degli helper tecnici nel dominio engine:

### Helper introdotti
- ShiftTimeHelper
- TimeBandHelper
- DateClassificationHelper

### Engine pulito
RepartoMobilePolicy:
- non duplica più normalizedEnd / workedHours / overlapMinutes
- non duplica più isNightMoment / nextBoundary / calculateNightHours
- non duplica più isHolidayDate / superHolidayDates / easter calculation

PolferPolicy:
- non duplica più normalizedEnd / workedHours / overlapMinutes
- non duplica più calculateBandHours

### Shift
Shift mantiene ancora metodi legacy di computation e money breakdown.
Questi metodi restano solo per compatibilità transitoria e non devono essere usati come source of truth nei nuovi flussi.
# DUPLICATION MAP — FINAL STATE

## RESOLVED DUPLICATIONS

### Time logic
- _normalizedEnd → ShiftTimeHelper
- _overlapMinutes → TimeBandHelper
- night calculation → TimeBandHelper
- holiday detection → DateClassificationHelper

Status: CLEAN

---

### Breakdown logic
Before:
- engine breakdown
- Shift legacy breakdown
- UI merge

Now:
- ONLY engine breakdown
- + controlled enrichment layer

Status: CLEAN

---

### Polfer overtime logic
Before:
- mixed with RM 6h rule
- fallback from Shift

Now:
- based on scheduled end
- no fallback

Status: CLEAN

---

### RFI Basket
Before:
- treated as accessory
- lost in pipeline

Now:
- explicit flags:
  - isBasketItem = true
  - basketKey = 'rfi'

- separate flow in:
  - Daily
  - Monthly
  - Payslip

Status: CLEAN

---

## REMAINING (INTENTIONAL)

### Transitional accessory methods in Shift
Used only for:
- order public
- comfort
- external service

Status: TEMPORARY (acceptable)

---

## FORBIDDEN PATTERNS

❌ shift.getSalaryBreakdown  
❌ shift.overtimeHours as source  
❌ merging legacy breakdown  
❌ using monthlySummaries for RFI  