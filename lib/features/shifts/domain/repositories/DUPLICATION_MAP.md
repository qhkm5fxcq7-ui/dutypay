# DUTYPAY — DUPLICATION GOVERNANCE

## Obiettivo

Prevenire la reintroduzione di duplicazioni logiche nel progetto.

Questo documento definisce:

* dove deve vivere ogni logica;
* cosa è stato centralizzato;
* cosa è temporaneamente tollerato;
* cosa è vietato.

---

# Baseline

Release:

**DutyPay 1.0.9 (Release Candidate)**

Stato:

* architettura consolidata;
* Source of Truth unificata;
* Core Engine stabile;
* 160 test automatici PASS;
* flutter analyze pulito.

---

# Principio Fondamentale

Una sola fonte della verità.

Qualsiasi regola di business deve avere un solo proprietario.

Sono vietati:

* duplicazioni;
* fallback legacy;
* calcoli paralleli;
* logica economica nella UI.

---

# Source of Truth

Fonte assoluta:

**BuildDailyShiftResultUseCase**

Responsabile di:

* overtime;
* notturno;
* festivo;
* OP;
* servizi esterni;
* accessorie;
* benefit;
* compensativi;
* basket;
* breakdown;
* totale turno;
* totale giorno.

Nessun widget può eseguire logiche economiche autonome.

---

# Pipeline Corretta

```text
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
UI / Dashboard / Cedolino / Summary
```

Questa è l'unica pipeline autorizzata.

---

# Classificazione Logica

## Shift

Consentito:

* serializzazione;
* deserializzazione;
* start/end;
* crossesMidnight;
* helper generici non economici.

Vietato:

* overtime;
* breakdown economico;
* notturno;
* festivo;
* regole reparto;
* importi.

---

## Policy

Responsabili di:

* overtime;
* notturno;
* festivo;
* classificazione giorno/notte;
* logiche reparto;
* importi di reparto.

Policy attive:

* RepartoMobilePolicy;
* PolferPolicy;
* QuesturaPolicy.

---

## UseCase

Responsabili di:

* orchestrazione;
* aggregazione;
* adattamento dati;
* summary.

Non devono:

* duplicare regole reparto;
* creare calcoli paralleli;
* bypassare DepartmentPolicy.

---

## UI

Responsabile solo di:

* input;
* visualizzazione;
* navigazione;
* stato grafico.

Mai responsabile di calcoli economici.

---

# Centralizzazioni Completate

## Time Logic

Centralizzato in:

* ShiftTimeHelper;
* TimeBandHelper.

Copertura:

* normalizedEnd;
* overlapMinutes;
* night calculation;
* band calculation.

Status:

✅ CLEAN

---

## Holiday Logic

Centralizzato in:

* DateClassificationHelper.

Copertura:

* holiday detection;
* super holidays;
* Easter calculation.

Status:

✅ CLEAN

---

## Breakdown Logic

Prima:

* engine breakdown;
* Shift breakdown;
* UI merge.

Ora:

* engine breakdown;
* enrichment layer controllato;
* nessuna source of truth parallela.

Status:

✅ CLEAN

---

## Overtime Logic

Prima:

* Shift;
* RM;
* Polfer;
* UI.

Ora:

* DepartmentPolicy;
* CalculateShiftUseCase;
* BuildDailyShiftResultUseCase.

Status:

✅ CLEAN

---

## Polfer Logic

Prima:

* contaminazione RM 6h.

Ora:

* scheduled end;
* chiusura teorica turno;
* RFI separato.

Status:

✅ CLEAN

---

## Questura Logic

Implementata tramite:

* QuesturaPolicy.

Supporta:

* Uffici;
* Volanti.

Status:

✅ CLEAN

---

## Programmed Overtime

Prima:

* override turno.

Ora:

* segmento temporale dedicato.

Gestione:

* paid;
* compensative.

Status:

✅ CLEAN

---

## Basket RFI

Pipeline separata.

Mai trattato come accessoria.

Flusso:

```text
OPEN
↓
PAID
↓
Cedolino
```

Status:

✅ CLEAN

---

## Basket Compensativo

Pipeline autonoma.

Separato da:

* overtime pagato;
* RFI;
* accessorie.

Status:

✅ CLEAN

---

## Basket Straordinari

Pipeline dedicata.

Separato da:

* RFI;
* compensativi;
* benefit.

Supporta:

* pagamenti;
* adjustment;
* residuo.

Status:

✅ CLEAN

---

## Break

Feature separata dal Core Economico.

Contenuta in:

```text
lib/features/break/
```

Non deve dipendere da:

* turni;
* cedolino;
* basket;
* profili stipendiali;
* DepartmentPolicy.

Status:

✅ CLEAN

---

# Elementi Transitori Consentiti

## Shift Legacy Methods

Possono rimanere solo se:

* non utilizzati dal motore come Source of Truth;
* necessari per retrocompatibilità;
* non producono pipeline alternativa.

Esempi tollerati:

* OP helper;
* comfort helper;
* servizio esterno helper.

Status:

⚠ TEMPORARY

---

# Pattern Vietati

Mai introdurre:

❌ `shift.getSalaryBreakdown`

❌ `shift.overtimeHours` come Source of Truth

❌ logiche economiche in UI

❌ merge breakdown legacy

❌ `monthlySummaries` per RFI

❌ calcoli duplicati preview

❌ logiche Questura nei widget

❌ logiche Polfer nei widget

❌ logiche RM nei widget

❌ dipendenze Break → Core Economico

❌ pipeline alternativa al motore

---

# Checklist Anti-Duplicazione

Prima di aggiungere una nuova regola:

1. Esiste già nel motore?
2. Esiste già in una policy?
3. Esiste già in un helper condiviso?
4. Sto duplicando una logica esistente?
5. Sto creando una seconda fonte di verità?
6. Sto portando logica economica nella UI?
7. Sto contaminando un reparto con regole di un altro?

Se una risposta è "sì", fermarsi e centralizzare.

---

# Stato Finale

Duplicazioni critiche:

✅ eliminate

Duplicazioni residue:

⚠ solo helper legacy non utilizzati come Source of Truth

Architettura:

✅ stabile
✅ multi reparto
✅ coperta da regression test
✅ pronta per ulteriori espansioni controllate
