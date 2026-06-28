# DUTYPAY – WORKFLOW MASTER

## Obiettivo

Coordinare lo sviluppo di DutyPay mantenendo un'unica architettura coerente, evitando regressioni, duplicazioni e divergenze tra le diverse aree del progetto.

DutyPay è un'app Flutter dedicata al personale delle Forze dell'Ordine.

Baseline attuale:

**Release Candidate 1.0.9**

Reparti supportati:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti
* Polstrada

Macro-moduli:

* Core Economico
* Break

---

# Gerarchia della documentazione

Ordine di priorità:

1. SYSTEM_HANDOFF.md
2. CALCULATION_RULES.md
3. ARCHITECTURE.md
4. TEST_STRATEGY.md
5. CHAT_HANDOFF.md
6. codice esistente

Il codice è considerato fonte di verità solo se conforme all'architettura documentata.

Qualsiasi logica legacy o duplicata nella UI non deve essere riutilizzata.

---

# Source of Truth

L'intero motore economico ruota attorno a due livelli.

## CalculateShiftUseCase

Responsabile di:

* eseguire il calcolo del singolo turno;
* selezionare automaticamente la DepartmentPolicy corretta;
* produrre lo ShiftCalculationResult.

## BuildDailyShiftResultUseCase

È la Source of Truth dell'intera applicazione.

Responsabile di:

* breakdown;
* totale turno;
* totale giornata;
* overtime;
* notturno;
* festivo;
* Ordine Pubblico;
* servizi esterni;
* compensativi;
* basket;
* dati utilizzati da dashboard, preview e cedolino.

Nessun widget può implementare logiche economiche autonome.

---

# Pipeline di sviluppo

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

↓

Preview

↓

Cedolino

↓

Summary Mensile

---

# Regole di sviluppo

Ogni modifica deve rispettare le seguenti regole.

1. Modificare il minor numero possibile di file.
2. Evitare qualsiasi duplicazione di logica.
3. Nessuna logica economica nella UI.
4. Nessun fallback legacy.
5. Ogni nuova regola passa dal motore centrale.
6. Ogni DepartmentPolicy gestisce esclusivamente il proprio reparto.
7. Ogni bug corretto deve produrre almeno un regression test.
8. Ogni modifica significativa aggiorna la documentazione tecnica.

---

# Organizzazione delle chat

## Cervello

Responsabile di:

* architettura;
* roadmap;
* documentazione;
* handoff;
* decisioni tecniche.

---

## Operativa

Responsabile di:

* implementazione;
* refactoring;
* bug fixing;
* test;
* commit.

---

## Product / Growth

Responsabile di:

* UX;
* prodotto;
* marketing;
* community;
* roadmap funzionale.

---

# Workflow obbligatorio

Per ogni modifica:

1. leggere SYSTEM_HANDOFF;
2. identificare il modulo corretto;
3. verificare la Source of Truth;
4. applicare la modifica minima necessaria;
5. eseguire i regression test interessati;
6. eseguire flutter analyze;
7. aggiornare l'handoff se necessario.

---

# Regression First

Ogni bug segue sempre questa sequenza.

1. Riprodurre il problema.
2. Scrivere il regression test.
3. Correggere il codice.
4. Verificare che il test passi.
5. Verificare che l'intera suite resti verde.

Mai il contrario.

---

# Blocchi che non devono rompersi

## Reparto Mobile

* soglia ordinaria 6h;
* doppio turno;
* Ordine Pubblico;
* servizi esterni;
* notturno;
* festivo.

---

## Polfer

* fine turno teorica;
* controllo territorio;
* notturno;
* RFI;
* scalo ferroviario;
* separazione basket.

---

## Questura Uffici

* ordinario configurabile;
* override;
* straordinario oltre soglia.

---

## Questura Volanti

* preset;
* straordinario post preset;
* notturno ordinario;
* override;
* straordinario programmato.

---

## Polstrada

* stessa pipeline di Questura Pattuglia;
* preset dedicati;
* futura indennità autostradale.

---

## Basket

Devono rimanere indipendenti:

* Basket Straordinari;
* Basket Compensativi;
* Basket RFI.

Non devono mai contaminarsi.

---

## Break

Il modulo Break è completamente indipendente dal motore economico.

Ogni evoluzione deve rispettare la seguente architettura:

Presentation

↓

Use Cases

↓

Repository

↓

Datasource

↓

Firestore

La logica Break non deve introdurre dipendenze verso il Core Economico.

---

# Checklist pre-release

Prima di ogni release devono essere eseguiti:

* flutter analyze;
* flutter test;
* regression pack completo;
* verifica preview ↔ turno salvato;
* verifica dashboard ↔ summary;
* verifica cedolino;
* smoke test multi reparto.

---

# Stato attuale

Release Candidate:

**1.0.9**

Stato:

* motore multi-reparto consolidato;
* Source of Truth centralizzata;
* pipeline unificata;
* Break stabilizzato lato Domain;
* suite completa di regressione;
* flutter analyze senza warning;
* 156 test automatici PASS.

---

# Obiettivo del workflow

Ogni nuova funzionalità deve aumentare almeno uno dei seguenti aspetti:

* precisione;
* affidabilità;
* stabilità;
* copertura dei test;
* semplicità dell'architettura;
* esperienza utente.

La qualità dell'architettura ha sempre priorità rispetto alla velocità di sviluppo.
