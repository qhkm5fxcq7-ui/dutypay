# DUTYPAY — DUPLICATION GOVERNANCE

## Obiettivo

Prevenire la reintroduzione di duplicazioni logiche nel progetto.

Questo documento definisce:

* dove deve vivere ogni logica
* cosa è stato centralizzato
* cosa è temporaneamente tollerato
* cosa è vietato

---

# Principio Fondamentale

Una sola fonte della verità.

Qualsiasi regola di business deve avere un solo proprietario.

Sono vietate:

* duplicazioni
* fallback legacy
* calcoli paralleli

---

# Source of Truth

Fonte assoluta:

BuildDailyShiftResultUseCase

Responsabile di:

* overtime
* notturno
* festivo
* OP
* servizi esterni
* compensativi
* basket
* breakdown
* totale turno
* totale giorno

Nessun widget può eseguire logiche economiche autonome.

---

# Architettura Corretta

Shift (dati)
↓
BuildDailyShiftResultUseCase
↓
BuildShiftComputationUseCase
↓
DepartmentPolicy
↓
DailyShiftResult
↓
UI

---

# Classificazione Logica

## Shift

Consentito:

* serializzazione
* deserializzazione
* start/end
* crossesMidnight
* helper generici

Vietato:

* overtime
* breakdown economico
* notturno
* festivo
* logiche reparto

---

## Policy

Responsabili di:

* overtime
* notturno
* festivo
* classificazione giorno/notte
* logiche reparto
* importi

Policy attive:

* RepartoMobilePolicy
* PolferPolicy
* QuesturaPolicy

---

## UseCase

Responsabili di:

* orchestrazione
* aggregazione
* adattamento dati

Non devono:

* calcolare soldi
* implementare logiche reparto

---

# Centralizzazioni Completate

## Time Logic

Centralizzato in:

* ShiftTimeHelper
* TimeBandHelper

Copertura:

* normalizedEnd
* overlapMinutes
* night calculation
* band calculation

Status:

✅ CLEAN

---

## Holiday Logic

Centralizzato in:

* DateClassificationHelper

Copertura:

* holiday detection
* super holidays
* Easter calculation

Status:

✅ CLEAN

---

## Breakdown Logic

Prima:

* engine breakdown
* Shift breakdown
* UI merge

Ora:

* solo engine breakdown
* enrichment layer controllato

Status:

✅ CLEAN

---

## Overtime Logic

Prima:

* Shift
* RM
* Polfer

Ora:

* DepartmentPolicy
* BuildDailyShiftResultUseCase

Status:

✅ CLEAN

---

## Polfer Logic

Prima:

* contaminazione RM 6h

Ora:

* scheduled end
* chiusura teorica turno

Status:

✅ CLEAN

---

## Questura Logic

Implementata tramite:

QuesturaPolicy

Supporta:

* Uffici
* Volanti

Status:

✅ CLEAN

---

## Programmed Overtime

Prima:

* override turno

Ora:

* segmento temporale dedicato

Gestione:

* paid
* compensative

Status:

✅ CLEAN

---

## Basket RFI

Pipeline separata.

Mai trattato come accessoria.

Flusso:

OPEN
↓
PAID
↓
Cedolino

Status:

✅ CLEAN

---

## Basket Compensativo

Pipeline autonoma.

Separato da:

* overtime pagato
* RFI
* accessorie

Status:

✅ CLEAN

---

# Elementi Transitori Consentiti

## Shift Legacy Methods

Possono rimanere solo se:

* non utilizzati dal motore
* necessari per retrocompatibilità

Esempi tollerati:

* OP helper
* comfort helper
* servizio esterno helper

Status:

⚠ TEMPORARY

---

# Pattern Vietati

Mai introdurre:

❌ shift.getSalaryBreakdown

❌ shift.overtimeHours come source of truth

❌ logiche economiche in UI

❌ merge breakdown legacy

❌ monthlySummaries per RFI

❌ calcoli duplicati preview

❌ logiche Questura nei widget

❌ logiche Polfer nei widget

❌ logiche RM nei widget

---

# Checklist Anti-Duplicazione

Prima di aggiungere una nuova regola:

1. Esiste già nel motore?
2. Esiste già in una policy?
3. Esiste già in un helper condiviso?
4. Sto duplicando una logica esistente?
5. Sto creando una seconda fonte di verità?

Se una risposta è "sì":

fermarsi e centralizzare.

---

# Stato Baseline

Release:

DutyPay 1.0.5

Duplicazioni critiche:

✅ eliminate

Duplicazioni residue:

⚠ solo helper legacy non utilizzati come source of truth

Architettura:

✅ stabile
✅ multi reparto
✅ pronta per ulteriori espansioni
