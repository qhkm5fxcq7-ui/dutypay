# DutyPay — Chat Handoff

## Stato attuale
Il progetto DutyPay ha una logica considerata corretta per:
- Reparto Mobile
- Polfer

L’obiettivo attuale non è rifattorizzare il motore da zero, ma:
1. congelare la logica corretta
2. scrivere test canonici
3. sistemare i bug residui senza rompere i comportamenti validati
4. preparare il rilascio iOS / App Store
5. successivamente estendere ad altri reparti:
   - Questura
   - Polaria
   - Polstrada

---

## Regola strategica attuale
Non modificare la logica di calcolo “per pulizia” o per refactor generale.

Prima:
- si scrivono regole
- si scrivono test
- poi si correggono solo i bug reali

---

## Reparti attualmente consolidati

### Reparto Mobile
- soglia straordinario: 6 ore
- segmentazione valida:
  - diurno
  - notturno
  - festivo
  - notturno festivo
- OP, servizi esterni, festivo, festività particolare, comfort, CDG e ticket già integrati
- multi-turno stesso giorno già trattato come punto delicato

### Polfer
- straordinario dopo chiusura teorica turno:
  - mattina 13:08
  - pomeriggio 19:08
  - sera 00:08
  - notte 07:08
- controllo territorio serale/notturno
- scalo ferroviario con basket RFI separato
- turni standard Polfer non devono generare falsi 0.2h di straordinario

---

## Bug già risolti / aree già sistemate
- doppio filteredShifts
- doppio yearlySearchResults
- errore Object nei summary
- classe chiusa male con `}`
- preview turno sparita
- CDG non visibile nel calendario
- ticket non coerenti tra UI e logica
- multi-turno che dava sempre 0
- ricerca annuale implementata e cliccabile
- segmentazione straordinario RM validata sui casi reali
- gestione mezzanotte / 22:00 / festivo validata nei casi discussi

---

## Punti delicati da non rompere
- coerenza preview ↔ salvataggio
- breakdown economico
- multi-turno stesso giorno
- non duplicare logica in UI
- ticket fuori dal cedolino
- comfort e CDG separati
- Reparto Mobile resta a 6 ore
- Polfer non deve tornare a 6 ore fisse sui turni standard
- lo scalo RFI non deve sparire
- lo scalo RFI non deve finire nello stipendio/accessorie ordinarie

---

## Logica legacy da non reintrodurre
### Polfer
- NON usare la soglia fissa a 6 ore per i turni standard

### Basket RFI
- NON trattare lo scalo come semplice riga testuale priva di metadata
- NON mischiare basket RFI e accessorie ordinarie

---

## Prossimo step esatto
Scrivere i primi 10 test canonici:

### Reparto Mobile
1. 15:00 → 02:00 non festivo, OP fuori sede
2. 15:00 → 02:00 con passaggio a domenica/festivo
3. 05:30 → 18:30 con 0.5h notturno ordinario e 7h straordinario diurno
4. 06:55 → 13:08 RM con circa 0.2h straordinario
5. assenza con totale zero

### Polfer
6. 06:55 → 13:08 mattina standard, zero straordinario
7. 12:55 → 19:08 pomeriggio standard, zero straordinario
8. turno sera standard, zero straordinario e sola quota notturna ordinaria
9. turno notte standard, zero straordinario e sola quota notturna ordinaria
10. turno con scalo ridotto RFI separato da stipendio/accessorie ordinarie

---

## Dopo i test
Solo dopo che i test sono verdi:
- sistemare i bug residui
- ripulire eventuali incoerenze tra preview e salvataggio
- verificare TestFlight
- preparare rilascio App Store
- preparare pagina Facebook del progetto

---

## Prompt di ripartenza per la prossima chat
Prosegui da questo stato del progetto DutyPay.

Leggi prima:
- docs/CALCULATION_RULES.md
- docs/CHAT_HANDOFF.md

Contesto:
- la logica attuale di Reparto Mobile e Polfer è considerata corretta
- non bisogna rifattorizzare il motore da zero
- bisogna congelare il comportamento corretto con test canonici
- poi sistemare solo i bug reali
- poi preparare il lancio App Store

Task immediato:
scrivi i primi test canonici per Reparto Mobile e Polfer sulla base dei casi consolidati presenti nella documentazione.
# DUTYPAY – SYSTEM HANDOFF (SOURCE OF TRUTH)

## Stato attuale

Questo documento rappresenta la verità operativa del sistema.
Qualsiasi modifica deve rispettare queste regole.

---

## Architettura

Presentation → UseCase → Engine → Result → UI

Separazione obbligatoria:
- UI non calcola
- UseCase orchestra
- Engine calcola
- Shift NON è il motore principale

---

## Regole fondamentali NON VIOLABILI

### Reparto Mobile
- soglia 6h
- overtime oltre 6h
- basket solo su eccedenza non liquidabile

### Polfer
- turno standard può valere 0
- NO soglia 6h
- straordinario solo se reale
- notturno dalle 22:00

---

## Basket RFI (CRITICO)

- entra IMMEDIATAMENTE nel mese di maturazione
- NON usa reference month accessorie
- NON entra nello stipendio stimato
- NON entra nelle accessorie ordinarie
- viene scaricato SOLO manualmente

---

## Pipeline corretta RFI

NON usare:
- monthlySummaries

USARE:
- rfiMonthlySummaries

---

## Distinzione obbligatoria

### 1. Maturato mese
- rfiMaturedHoursForMonth
- rfiMaturedGrossForMonth

### 2. Residuo
- currentRfiBasketResidualHours
- currentRfiBasketResidualGrossEstimate

### 3. Pagato mese
- manualRfiBasketPaidHoursForMonth
- manualRfiBasketPaidGrossForMonth

---

## Errori da NON reintrodurre

- fallback su shift.overtimeHours per Polfer
- merge breakdown legacy
- uso monthlySummaries per RFI
- perdita scalo dopo salvataggio

---

## Stato validato

Caso reale:
- maturato 1.0h / 1,93€
- residuo 1.0h / 1,93€
- pagato 0

Questo è il comportamento corretto.
## Refactor phase 1
- Shift legacy methods remain in codebase but are no longer the intended source of truth.
- Source of truth is DepartmentPolicy -> ShiftCalculationResult.
- BuildShiftComputationUseCase must not reintroduce legacy overtime logic.
- Polfer legacy fallback must be reduced progressively.
## Engine base refactor completed
- technical helpers extracted:
  - ShiftTimeHelper
  - TimeBandHelper
  - DateClassificationHelper
- RepartoMobilePolicy and PolferPolicy no longer duplicate core time/band logic
- Shift still contains transitional legacy computation helpers
- next step: progressively remove legacy usage from application/usecase flow
# CURRENT SYSTEM STATE — FINAL

## Polfer

- standard shift can generate:
  - 0 overtime
  - 0 total

- overtime starts AFTER scheduled end
- night starts at 22:00

NO fallback to 6h rule allowed

---

## Reparto Mobile

- 6h daily threshold
- overtime after 6h
- basket overtime only above monthly cap

---

## RFI Basket

- generated at shift level
- goes immediately into basket
- NOT part of:
  - overtime
  - accessories
  - payslip projection

- tracked via:
  - isBasketItem = true
  - basketKey = 'rfi'

---

## Validated UI Behavior

Example:

Maturato: 1.0h / €1.93  
Residuo: 1.0h / €1.93  
Pagato mese: 0  

This is the correct behavior.

---

## Critical Rule

RFI must NEVER be:

- merged into total accessory flow
- delayed by reference month
- included in payslip estimation

---

## Engine Status

- helpers extracted ✔
- duplication removed ✔
- policy isolated ✔
- computation pipeline clean ✔

System is stable and scalable.
## Latest completed work
- engine technical helpers extracted and adopted
- daily/monthly usecases cleaned from duplicated technical logic
- shift money components now derive overtime and RFI from structured breakdown
- manual toggles added:
  - Compensazione
  - Reperibilita
- build restored successfully
## Latest validation
Manual UI validation confirms:
- RM overtime and OP breakdown are coherent
- Polfer standard evening shift produces no overtime
- RFI scalo is separated from extra and visible in breakdown
- RFI basket values (matured / paid / residual) update coherently after new scalo entries
DUTYPAY — HANDOFF TECNICO AGGIORNATO

STATO CHIUSO E VALIDATO
1. Reparto Mobile
- soglia ordinaria 6h confermata
- regressione RM passata
- overtime, OP, bordo notturno, assenze verificati

2. Polfer
- turni standard mattina/pomeriggio/sera/notte verificati
- zero straordinario sui turni standard
- quota notturna ordinaria fixata nel motore Polfer
- regressione Polfer passata
- scalo RFI separato e funzionante

3. Basket RFI
- maturazione corretta
- residuo corretto
- pagamento manuale corretto
- entra nel cedolino solo se pagato
- test RFI cedolino passati

4. Compensazione / Reperibilità
- aggiunti al model Shift
- presenti in persistenza
- integrati in QuickAddShiftPage
- preview corretta
- salvataggio corretto
- lista turni corretta
- breakdown corretto
- tests manual_accessories passati

5. Allineamento pipeline
- BuildShiftComputationUseCase aggiornato
- BuildDailyShiftResultUseCase aggiornato
- preview e lista turni ora leggono dati coerenti
- nessuna contaminazione con basket RFI
- nessuna generazione di overtime falso

FILE CHIAVE MODIFICATI
- lib/features/shifts/presentation/models/shift.dart
- lib/features/shifts/presentation/quick_add_shift_page.dart
- lib/features/shifts/application/usecases/build_shift_computation_usecase.dart
- lib/features/shifts/application/usecases/build_daily_shift_result_usecase.dart
- lib/features/shifts/presentation/services/payslip_projection_service.dart
- test/scenarios/canonical_shift_scenarios.dart
- test/unit/usecases/manual_accessories_test.dart
- test/unit/usecases/payslip_projection_rfi_test.dart
- test/unit/reparto_mobile/reparto_mobile_regression_test.dart
- test/unit/polfer/polfer_regression_test.dart

TEST PASSATI
- manual_accessories_test.dart
- payslip_projection_rfi_test.dart
- reparto_mobile_regression_test.dart
- polfer_regression_test.dart

STEP IMMEDIATO DA CHIUDERE ORA
- verificare con test dedicato se Compensazione/Reperibilità sono già dentro il cedolino previsto:
  test/unit/usecases/payslip_projection_manual_accessories_test.dart

LOGICA DA NON ROMPERE
- RM e Polfer separati
- RFI separato dalle accessorie ordinarie
- compensazione e reperibilità NON vanno nel basket
- preview, salvataggio e lista turni devono restare allineati
DUTYPAY — HANDOFF TECNICO DEFINITIVO

STATO ATTUALE
La fase attuale di consolidamento logico è chiusa con successo.
Stato finale test suite: ALL TESTS PASSED.

OBIETTIVO CHIUSO IN QUESTA FASE
Consolidare e blindare:
- logica Reparto Mobile
- logica Polfer
- basket straordinari
- basket RFI
- cedolino previsto
- compensazione / reperibilità
- allineamento completo tra preview, salvataggio, lista turni e cedolino

BLOCCHI CHIUSI E VALIDATI

1. REPARTO MOBILE
- soglia ordinaria 6h confermata
- overtime oltre 6h confermato
- regressione RM passata
- casi coperti:
  - turno standard
  - overtime
  - OP fuori sede
  - bordo notturno
  - assenze

2. POLFER
- turni standard mattina/pomeriggio/sera/notte corretti
- zero straordinario sui turni standard confermato
- quota notturna ordinaria corretta e fixata nel motore Polfer
- regressione Polfer passata
- controllo territorio corretto
- scalo ridotto/intero corretto

3. BASKET RFI
- maturazione corretta
- residuo corretto
- pagamento manuale corretto
- entra nel cedolino solo se pagato
- riduce il residuo quando pagato
- completamente separato dalle accessorie ordinarie
- test RFI cedolino passati

4. COMPENSAZIONE / REPERIBILITÀ
- aggiunte nel model Shift
- persistenza corretta
- integrate in QuickAddShiftPage
- preview corretta
- salvataggio corretto
- lista turni corretta
- breakdown corretto
- extra generati corretti
- entrano nel cedolino previsto
- NON entrano nel basket RFI
- NON generano overtime
- test automatici passati

5. ALLINEAMENTO PIPELINE
La pipeline è coerente tra:
- form turno
- preview turno
- persistenza
- lista turni
- riepilogo giornaliero
- cedolino

FILE CHIAVE MODIFICATI
- lib/features/shifts/presentation/models/shift.dart
- lib/features/shifts/presentation/quick_add_shift_page.dart
- lib/features/shifts/application/usecases/build_shift_computation_usecase.dart
- lib/features/shifts/application/usecases/build_daily_shift_result_usecase.dart
- lib/features/shifts/application/usecases/build_shift_money_components_usecase.dart
- lib/features/shifts/application/usecases/build_monthly_accessory_summary_usecase.dart
- lib/features/shifts/presentation/services/payslip_projection_service.dart
- lib/features/shifts/domain/engine/policies/polfer_policy.dart
- test/scenarios/canonical_shift_scenarios.dart
- test/unit/build_shift_money_components_usecase_test.dart
- test/unit/usecases/manual_accessories_test.dart
- test/unit/usecases/payslip_projection_rfi_test.dart
- test/unit/usecases/payslip_projection_manual_accessories_test.dart
- test/unit/reparto_mobile/reparto_mobile_regression_test.dart
- test/unit/polfer/polfer_regression_test.dart

TEST AUTOMATICI PASSATI
- test/unit/build_shift_money_components_usecase_test.dart
- test/unit/usecases/manual_accessories_test.dart
- test/unit/usecases/payslip_projection_rfi_test.dart
- test/unit/usecases/payslip_projection_manual_accessories_test.dart
- test/unit/reparto_mobile/reparto_mobile_regression_test.dart
- test/unit/polfer/polfer_regression_test.dart

NOTE SULLA SUITE TEST
- alcuni test legacy RM/Polfer con import obsoleti sono stati disattivati/archiviati
- la suite attiva è ora allineata all’architettura corrente
- stato finale confermato: ALL TESTS PASSED

PRINCIPI DA NON ROMPERE
- RM e Polfer devono restare separati logicamente
- RFI deve restare separato dalle accessorie ordinarie
- compensazione e reperibilità NON devono entrare nel basket
- preview, salvataggio, lista turni e cedolino devono restare coerenti
- il cedolino deve usare la pipeline nuova e non funzioni legacy

PROSSIMA FASE CONSIGLIATA
Non tornare sul motore.
La prossima fase deve riguardare uno di questi macro-blocchi:
1. release engineering Apple / TestFlight / App Store
2. agents.md + LESSONS.md + disciplina di progetto
3. CI / automazione test / runner scenari
4. UX finale / rifiniture prodotto
5. Android o espansione funzionale solo dopo aver mantenuto stabile questa base

OBIETTIVO DELLA NUOVA CHAT
Proseguire in continuità assoluta con questo stato, senza riaprire i punti già chiusi e senza rompere la base attuale.
# DutyPay — Chat Handoff

## Stato progetto

- RM: completato e stabile
- Polfer: stabile
- Test: PASS
- App pronta per fase pre-release iOS

---

## Punto chiuso definitivamente

BUG:
RM perdeva il notturno quando presente straordinario

FIX:
- separazione completa tra:
  - ordinary night
  - overtime night
- rimozione logica errata di compensazione
- introduzione hours nel breakdown

---

## Test introdotti

Coperti:

- 6h standard
- overtime semplice
- OP lungo
- bordo notturno
- overtime misto
- 17:00 → 23:00
- 17:00 → 01:00
- attraversamento festivo

---

## Regola chiave da NON rompere

Il notturno è indipendente dallo straordinario.

---

## Stato attuale qualità

- Engine: affidabile
- UI: coerente con engine
- Test: solidi

---

## Prossima fase

- Bug reali da utenti
- Micro UX improvements
- Preparazione App Store

NO:
- nuove feature complesse
- refactor non necessari
- benefit allineati tra preview e salvataggio
- ticket reintegrato nel post-salvataggio
- duplicazioni comfort eliminate
- ticket, comfort e comfort_cdg normalizzati come benefit non economici:
  - amount = 0.0
  - benefitAmount valorizzato
  - isBenefit = true
- totalAmount ed extraAmount non includono più i benefit
- test automatico benefit_alignment_test.dart introdotto e passato
### ✅ Benefit alignment completato

- ticket meal visibile ma non economico
- genere di conforto visibile ma non economico
- nessuna duplicazione
- preview e post-salvataggio allineati
### ✅ Parser cedolini blindato

- fixture reali RM e Polfer utilizzate
- accessorie estratte correttamente
- derivazione rate straordinario coerente
- fix: uso ultima occorrenza "Assegni accessori"
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
## Stato attuale sistema (RFI incluso)

- RFI basket attivo e separato
- Preview calcolo allineata 1:1 con engine
- Nessuna incoerenza tra preview e salvataggio
- UI semplificata (RFI solo €)

Sistema stabile e pronto per rilascio
## Stato per nuove chat

Sistema stabilizzato.

Non introdurre nuove feature.

Focus:
- mantenere stabilità
- evitare regressioni

Prossimo step:
→ pubblicazione App Store
## Fix critico — parser accessorie cedolini reali

È stato corretto un bug critico nel parsing delle competenze accessorie da cedolino che impediva la costruzione corretta delle `accessoryEntries` e delle `operationalAccessoryEntries`.

### Problema reale emerso
Con cedolini reali caricati nell’app:
- il conteggio cedolini risultava corretto
- lo snapshot storico veniva valorizzato
- ma `accessoryEntries` e `operationalAccessoryEntries` risultavano vuoti
- la UI continuava quindi a mostrare fallback/stime invece dei valori reali derivati dai cedolini

### Causa tecnica
Il parser prendeva la sezione sbagliata oppure non riusciva a interpretare correttamente le righe accessorie in presenza di:
- occorrenze multiple del marker "Assegni accessori"
- testo OCR/estratto con formati diversi
- spaziature variabili nelle righe tipo `- Qta.`, `- Imp.`, `- Rif.`

### Fix applicati
- `_extractAccessoryBlock()` aggiornato per prendere il blocco dettagliato corretto delle accessorie
- `_extractAccessoryEntries()` reso robusto rispetto a:
  - spazi multipli
  - OCR sporco
  - varianti del marker `Assegni accessori`
  - codici e righe accessorie in formato reale da PDF

### Effetto del fix
Ora il parser popola correttamente:
- `accessoryEntries`
- `operationalAccessoryEntries`

Questo consente a `buildDynamicProfile()` di usare i dati reali dei cedolini e non più i fallback predefiniti.
## Latest Operational Handoff — After Commit b9d9f06

The project is now on a stable baseline after segmented programmed overtime.

Completed:
- Compensative base flow
- Ordinary-hours override
- Preset persistence
- Night cross-midnight service date
- Polfer false-overtime regression tests
- Programmed overtime as explicit segment
- Programmed compensative overtime
- Clamp for programmed segment outside shift range
- Legacy orphan file cleanup
- Payslip projection service repair

Current stable commit:
- `b9d9f06`

Current validation:
- `flutter test`: 61/61 passed
- repository status after cleanup: clean

Next recommended implementation:
Basket Compensativo complete flow:
1. compensative hours matured
2. compensative hours recovered/discharged
3. residual balance
4. history of movements
5. absence type “Recupero compensativo”
6. monthly/yearly UI summary
7. strict exclusion from payslip payment, RFI basket, and payment basket
## Latest Operational Handoff — Complete Compensative Basket

The Compensative Basket is now implemented as a complete autonomous hours pipeline.

Completed:
- domain models
- summary model
- movement history
- automatic earned movements
- automatic recovered movements
- manual adjustments
- positive/negative corrections
- mandatory note validation
- delete policy limited to adjustments
- SharedPreferences scoped persistence
- dashboard card
- latest movement history
- live residual update

Key files:
- `lib/features/shifts/application/models/compensative_basket_movement.dart`
- `lib/features/shifts/application/models/compensative_basket_summary.dart`
- `lib/features/shifts/application/usecases/build_compensative_basket_movements_usecase.dart`
- `lib/features/shifts/application/usecases/build_compensative_basket_summary_from_movements_usecase.dart`
- `lib/features/shifts/application/usecases/build_compensative_basket_summary_usecase.dart`
- `lib/features/shifts/application/usecases/manage_compensative_basket_adjustments_usecase.dart`
- `lib/main.dart`

Current rules:
- automatic earned/recovered movements are generated from shifts
- manual adjustments are persisted
- only adjustments can be deleted
- automatic movements are protected
- final UI state is automatic movements + manual persisted adjustments

Storage:
- `dutypay_compensative_basket_movements_<department>`

Current validation:
- `flutter test`: passed
- `flutter analyze`: no blocking errors; remaining items are warnings/info

Next possible steps:
1. UX refinement for correction dialog
2. export/import compensative basket data
3. recovery wizard
4. yearly compensative analytics
5. documentation polish
## 1.0.5 - Questura / Volanti Stabilization

### Nuove funzionalità
- Introduzione QuesturaMode.volanti
- Introduzione QuesturaMode.uffici
- Preset Volanti:
  - Mattina
  - Pomeriggio
  - Sera
  - Notte
- Calcolo automatico straordinario su fine turno preset
- Supporto straordinario programmato personalizzato
- Supporto orario ordinario personalizzato

### Fix
- Corretto conteggio straordinario Volanti
- Corretto conteggio straordinario Polfer preset
- Corretto totale preview QuickAddShiftPage
- Corretto totale servizio nei turni con sole indennità
- Corretto breakdown preview con override orario ordinario
- Eliminata discrepanza tra dettaglio turno e totale preview
STATO ATTUALE

Questura:
✅ Uffici
✅ Volanti

Volanti validato:

- servizio esterno
- notturno ordinario
- straordinario automatico
- straordinario programmato
- override orario ordinario
- preview calcolo
- dettaglio turno
- totale turno

BUG RISOLTI:

1. Preview totale = 0 con sole indennità
2. Straordinario override mostrato in modo errato
3. Polfer preset conteggiati come straordinario errato
4. Disallineamento preview/dettaglio turno

Release candidate:
RC-QUESTURA-VOLANTI-01
