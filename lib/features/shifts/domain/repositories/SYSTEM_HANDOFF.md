# DUTYPAY — SYSTEM HANDOFF (MASTER)

## What this system is

A modular calculation engine for Police salary components.

Focus:
- accuracy
- separation of concerns
- real-world behavior

---

## Architecture Layers

### Engine
- DepartmentPolicy
- helpers
- pure calculation

### Application
- UseCases
- orchestration only

### Presentation
- UI
- no business logic

---

## Key Design Rules

1. Engine is the ONLY source of truth
2. No legacy fallback allowed
3. No logic in UI
4. No duplication of time calculations
5. Basket flows must stay separated

---

## Financial Flows

Each shift produces:

- overtime
- non-overtime
- RFI basket

These flows NEVER mix prematurely.

---

## Special Case: RFI

RFI is:

- immediate basket
- not part of salary
- not part of accessory delay system

Handled separately across entire pipeline.

---

## Current State

System is:

- consistent
- deterministic
- ready for scaling
- ready for production refinement

---

## Next Possible Evolutions

- smarter payslip prediction
- multi-department expansion
- Android release
- UI clarity improvements
## Manual accessory toggles
Two manual accessory flags are now supported at shift level:
- hasCompensazione → €12.00
- hasReperibilita → €17.50 gross

They:
- enter normal accessories flow
- do not enter basket flows
- use standard accessory taxation logic
## Validated business behavior
- RM daily and multi-shift totals are coherent
- Polfer evening standard shift: no overtime, only night allowance
- RFI scalo contributes to basket, not to extra liquidabili
- Basket RFI values update correctly after new scalo insertions
## Canonical shift scenarios
Reparto Mobile canonical scenarios must use real 6-hour shifts.
Shifts like 06:55 -> 13:08 belong to turnazione in 5 logic and must not be used as RM baseline scenarios.
# DutyPay — System Handoff

## Stato attuale

Reparto Mobile:
- Engine stabile
- Segmentazione giorno/notte corretta
- Segmentazione festivo corretta
- Notturno indipendente dallo straordinario

Test:
- Copertura completa casi critici RM
- Tutti i regression test PASS

---

## Architettura

Flusso:

UI
↓
BuildShiftComputationUseCase
↓
CalculateShiftUseCase
↓
DepartmentPolicy (RM / Polfer)
↓
Engine

---

## Source of Truth

UNICA fonte:
→ DepartmentPolicy

In particolare:
- RepartoMobilePolicy

---

## Responsabilità

### Engine (Policy)
- calcolo ore
- classificazione day/night
- classificazione festivo
- breakdown completo

### UseCase
- mapping verso UI
- aggiunta accessori

### UI
- visualizzazione
- ZERO logica

---

## Stato RM

✔ RISOLTO:
- perdita notturno con overtime
- conflitto notturno vs straordinario
- breakdown incompleto (mancavano hours)

✔ GARANTITO:
- ordinary night sempre preservato
- overtime night separato
- gestione corretta festivi

---

## Vincoli

NON TOCCARE:
- logica RM validata
- struttura breakdown
- distinzione day/night

MODIFICHE future:
→ solo con test obbligatori
## Benefit flow separato

I benefit non economici devono restare separati dai flussi economici.

Categorie:
- ticket_meal
- comfort
- comfort_cdg

Regola tecnica:
- amount = 0.0
- benefitAmount valorizzato
- isBenefit = true

Vincoli:
- mai sommati a totalAmount
- mai sommati a extraAmount
- mai sommati al cedolino
- devono restare visibili nel breakdown preview e post-salvataggio
## Benefit Flow

I benefit sono separati dal flusso economico.

Struttura:
- amount = 0.0
- benefitAmount valorizzato
- isBenefit = true

Vincoli:
- mai inclusi in totalAmount
- mai inclusi in extraAmount
- mai inclusi nella pipeline cedolino
## Parser Cedolini — Regola critica

Nei cedolini NoiPA:

- Il blocco "Assegni accessori" compare almeno due volte
  1. riepilogo (pagina 1)
  2. dettaglio retribuzione (pagina successiva)

Il parser deve utilizzare SEMPRE:
→ l'ultima occorrenza

Motivazione:
- solo il dettaglio contiene le righe accessorie reali
## Update — Segmented Programmed Overtime Baseline

A new stable baseline has been created after implementing segmented programmed overtime.

Stable commit:
- `b9d9f06` — `Implement segmented programmed overtime and archive legacy files`

Current validation:
- `flutter test`: passed, 61/61
- `flutter analyze`: no blocking errors; remaining items are warnings/info

Implemented:
- Programmed overtime is now a time segment, not a whole-shift override.
- `programmedOvertimeEnabled` with valid `programmedOvertimeStart` / `programmedOvertimeEnd` calculates only the overlapping segment inside the shift.
- The programmed segment is treated as certain overtime.
- If `overtimeDestination == compensative`, the programmed overtime hours enter `compensativeHours` and do not enter paid `totalAmount`.
- Out-of-range programmed segments are safely clamped to the shift range.
- Legacy/orphaned files no longer used by runtime were removed from active build.
- `payslip_projection_service.dart` was repaired after legacy/stash corruption.

Architectural rule:
- Shift stores the operational configuration.
- BuildDailyShiftResultUseCase owns daily/segment orchestration.
- UI must not calculate overtime economics.
- Basket Compensativo must build on `compensativeHours`, not on paid overtime gross.
