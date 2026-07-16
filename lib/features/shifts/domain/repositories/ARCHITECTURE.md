# DUTYPAY — ARCHITECTURE

## Obiettivo

Questo documento definisce l'architettura ufficiale di DutyPay.

Descrive:

* componenti;
* responsabilità;
* pipeline di calcolo;
* principi architetturali;
* flussi economici;
* vincoli progettuali.

Non descrive roadmap o backlog.

---

# Architettura Generale

DutyPay adotta una Clean Architecture suddivisa in tre livelli:

1. Presentation
2. Application
3. Domain

Ogni livello ha responsabilità ben definite e non deve contenere logiche appartenenti agli altri livelli.

---

# Presentation Layer

Responsabilità:

* Flutter UI;
* schermate;
* dashboard;
* cards;
* calendario;
* inserimento turni;
* preview;
* modulo Break;
* animazioni.

Può:

* leggere dati;
* mostrare dati;
* raccogliere input utente.

Non può:

* calcolare importi;
* classificare ore;
* determinare straordinari;
* applicare regole di reparto;
* modificare risultati economici.

La Presentation visualizza esclusivamente risultati provenienti dal motore centrale.

---

# Application Layer

Responsabilità:

* orchestrazione;
* coordinamento dei Use Case;
* aggregazione risultati;
* costruzione dei riepiloghi;
* pipeline economiche.

Use Case principali:

* CalculateShiftUseCase
* BuildShiftComputationUseCase
* BuildDailyShiftResultUseCase
* BuildMonthlySummaryUseCase
* BuildCompensativeBasketMovementsUseCase
* BuildCompensativeBasketSummaryFromMovementsUseCase

I Use Case non contengono regole specifiche dei reparti.

---

# Domain Layer

Responsabilità:

* motore economico;
* regole operative;
* policy dei reparti;
* classificazione ore;
* straordinari;
* notturno;
* festivo;
* gestione basket;
* compensativi.

Il Domain rappresenta il cuore dell'applicazione.

---

# Source of Truth

La Source of Truth ufficiale dell'intero sistema è:

**BuildDailyShiftResultUseCase**

È responsabile della costruzione dei risultati utilizzati da tutta l'applicazione.

Produce:

* overtime;
* notturno;
* festivo;
* Ordine Pubblico;
* servizi esterni;
* benefit;
* basket;
* compensativi;
* breakdown;
* totale turno;
* totale giornata.

Nessun widget può produrre risultati economici autonomi.

---

# Pipeline di Calcolo

Il flusso ufficiale del motore è:

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
Dashboard
Preview
Cedolino
Summary
```

Questa rappresenta l'unica pipeline autorizzata.

---

# Department Policy

La logica dei reparti è completamente isolata.

Factory:

* DepartmentPolicyFactory

Policy disponibili:

* RepartoMobilePolicy
* PolferPolicy
* QuesturaPolicy

Ogni nuova implementazione dovrà essere aggiunta esclusivamente tramite una nuova DepartmentPolicy.

---

# Reparto Mobile

Gestisce:

* soglia ordinaria 6h;
* straordinario;
* notturno;
* festivo;
* Ordine Pubblico;
* servizi esterni.

---

# Polfer

Gestisce:

* fine turno teorica;
* controllo territorio;
* notturno;
* scalo ferroviario (RFI);
* straordinario programmato.

Non utilizza la soglia ordinaria delle 6 ore.

---

# Questura

## Uffici

Supporta:

* ordinario 6h;
* ordinario 7h12;
* ordinario personalizzato;
* override manuale.

Lo straordinario viene calcolato esclusivamente oltre l'orario ordinario configurato.

---

## Volanti

Preset ufficiali:

* Mattina;
* Pomeriggio;
* Sera;
* Notte.

Regole:

* ordinario fino al termine del preset;
* straordinario oltre il preset;
* supporto allo straordinario programmato.

---

# Programmed Overtime

Lo straordinario programmato è gestito come segmento temporale indipendente.

Campi principali:

* programmedOvertimeEnabled;
* programmedOvertimeStart;
* programmedOvertimeEnd;
* overtimeDestination.

Pipeline:

```text
Shift
        ↓
Segment overlap
        ↓
Clamp automatico
        ↓
Overtime certo
```

Destinazioni possibili:

* pagamento;
* compensativo.

---

# Basket Straordinari

Pipeline dedicata.

Gestisce:

* movimenti;
* pagamenti;
* saldo residuo;
* proiezione cedolino;
* correzioni manuali.

È indipendente da tutti gli altri basket.

---

# Basket RFI

Pipeline autonoma.

Flusso:

```text
Turno con Scalo
        ↓
Basket OPEN
        ↓
Pagamento
        ↓
Basket PAID
        ↓
Cedolino
```

Separato da:

* straordinari;
* compensativi;
* accessorie.

---

# Basket Compensativo

Pipeline indipendente basata esclusivamente sulle ore.

Domain Model:

* CompensativeBasketMovement
* CompensativeBasketSummary

Tipologie:

* earned;
* recovered;
* adjustment.

Regole:

* earned automatico;
* recovered automatico;
* adjustment modificabile;
* nota obbligatoria;
* earned e recovered non eliminabili.

---

# Cedolino

Pipeline:

```text
Breakdown Giornaliero
        ↓
Aggregazione Mensile
        ↓
Esclusione Benefit
        ↓
Esclusione Basket RFI
        ↓
Lordo Stimato
        ↓
Fiscalità Stimata
        ↓
Netto Previsto
```

---

# Benefit

Categorie:

* Ticket Meal;
* Comfort;
* Comfort CDG.

Regole:

* amount = 0;
* benefitAmount valorizzato;
* isBenefit = true.

Mai inclusi nel totale economico.

---

# Parser Cedolini

Validazione effettuata tramite fixture reali.

Copertura:

* RM Febbraio 2026;
* RM Marzo 2026;
* Polfer Marzo 2026.

Regola fondamentale:

nei cedolini NoiPA il parser utilizza sempre l'ultima occorrenza del blocco:

"Assegni accessori"

---

# Break Architecture

Il modulo Break è completamente indipendente dal motore economico.

Architettura:

```text
Presentation
        ↓
Use Case
        ↓
Repository
        ↓
Datasource
        ↓
Firestore
```

Componenti principali:

* Identity;
* Room;
* Participant;
* Challenge Engine;
* Animation Engine.

Il Challenge Engine è deterministico e completamente separato dalle logiche economiche.

---

# Vincoli Architetturali

È vietato:

* introdurre logica economica nella UI;
* duplicare regole del motore;
* utilizzare pipeline alternative;
* bypassare CalculateShiftUseCase;
* eseguire calcoli economici nella Presentation;
* mescolare Basket Straordinari, Basket Compensativi e Basket RFI;
* introdurre codice legacy.

---

# Stato Architetturale

Versione:

**DutyPay 1.0.9 (Release Candidate)**

Architettura consolidata.

Componenti validati:

* Core Calculation Engine;
* Multi Department Engine;
* Parser Cedolini;
* Basket Straordinari;
* Basket Compensativi;
* Basket RFI;
* Dashboard;
* Break.

Validazione:

* **160 test PASS**
* **Flutter Analyze: 0 warning / 0 errori**

L'architettura è considerata stabile e costituisce la baseline tecnica per le future evoluzioni del progetto.
## Preview Engine

La preview della modifica turno non implementa alcuna logica di calcolo dedicata.

Per garantire la completa coerenza con il motore applicativo viene costruito un contesto temporaneo della giornata.

Schema:

Turni giornata

↓

sostituzione del turno in modifica

↓

BuildDailyShiftResultUseCase

↓

Preview UI

Questo garantisce che:

- preview e salvataggio producano gli stessi risultati;
- eventuali modifiche future al motore vengano automaticamente riflesse nella preview;
- non esistano duplicazioni della logica di calcolo.
