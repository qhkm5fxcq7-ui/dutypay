# DUTYPAY — SYSTEM HANDOFF (MASTER)

## Cos'è DutyPay

DutyPay è un'app Flutter dedicata al personale delle Forze dell'Ordine.

Obiettivo:

* calcolo turni
* straordinari
* accessorie
* basket
* compensativi
* stima cedolino

Principi:

* accuratezza
* comportamento reale
* architettura modulare
* assenza di duplicazioni logiche

---

# Release Baseline

Versione attuale:

**1.0.5**

Reparti supportati:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Stato:

* Android build 18
* iOS build 18

---

# Architettura

## Presentation

Responsabilità:

* Flutter UI
* schermate
* cards
* dashboard
* calendario
* preview

Vincolo:

Nessuna logica economica.

---

## Application

Responsabilità:

* orchestrazione
* aggregazione risultati
* costruzione summary

UseCase principali:

* BuildDailyShiftResultUseCase
* BuildMonthlySummaryUseCase
* BuildShiftComputationUseCase
* BuildCompensativeBasketMovementsUseCase

---

## Domain

Responsabilità:

* policy reparto
* motore di calcolo
* regole operative

Policy attive:

* RepartoMobilePolicy
* PolferPolicy
* QuesturaPolicy

---

# Source of Truth

La fonte di verità assoluta è:

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

Nessun widget può eseguire calcoli paralleli.

---

# Pipeline Calcolo

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
Summary / Dashboard / Cedolino

---

# Regole Fondamentali

1. Nessuna logica economica in UI.
2. Nessuna duplicazione dei calcoli.
3. Nessuna reintroduzione di codice legacy.
4. Preview e turno salvato devono essere identici.
5. Breakdown e totale devono essere coerenti.
6. Ogni nuova regola passa dal motore centrale.

---

# Flussi Economici

Ogni turno può generare:

* straordinario
* notturno
* accessorie
* OP
* servizi esterni

Questi valori confluiscono nel totale turno.

---

# Basket RFI

Flusso separato.

Caratteristiche:

* generazione da scalo
* stato OPEN
* pagamento manuale
* stato PAID
* incluso nel cedolino solo nel mese di pagamento

Mai mescolato con:

* overtime
* compensativi
* accessorie

---

# Basket Compensativo

Pipeline autonoma.

Caratteristiche:

* basato su ore
* non è denaro
* non è RFI
* non è accessoria

Supporta:

* earned automatico
* recovered automatico
* adjustment manuali

Vincoli:

* earned non eliminabile
* recovered non eliminabile
* adjustment unico movimento modificabile

---

# Benefit Flow

Benefit separati dal denaro.

Categorie:

* ticket_meal
* comfort
* comfort_cdg

Regole:

* amount = 0
* benefitAmount valorizzato
* isBenefit = true

Mai inclusi in:

* totalAmount
* extraAmount
* cedolino

---

# Programmed Overtime

Implementazione segmentata.

Caratteristiche:

* il segmento programmato è overtime certo
* viene clamped al turno reale
* può essere pagato
* può diventare compensativo

Destinazione compensativa:

* entra nel basket compensativo
* non entra nel totale pagato

---

# Questura Uffici

Supportato:

* ordinario personalizzato
* override 6h
* override 7h12
* override libero

Straordinario:

solo oltre l’ordinario configurato.

---

# Questura Volanti

Preset supportati:

* Mattina
* Pomeriggio
* Sera
* Notte

Regola:

* ordinario fino a fine preset
* overtime dopo fine preset

---

# Parser Cedolini

Regola critica:

Nei cedolini NoiPA il blocco:

"Assegni accessori"

può comparire più volte.

Il parser deve utilizzare:

sempre l'ultima occorrenza.

Motivazione:

solo il dettaglio contiene le righe reali.

---

# Stato Validazione

Validato:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Test automatici:

78/78 PASS

flutter analyze:

0 errori bloccanti

---

# Bug noto

Export dati macOS

Errore:

Bytes are not supported on macOS

Impatto:

nessuno su Android/iOS

Target fix:

Release 1.0.6

---

# Vincoli Assoluti

NON ROMPERE:

* RM soglia 6h
* Polfer notturno e territorio
* Questura Uffici override ordinario
* Questura Volanti preset
* Basket RFI
* Basket Compensativo
* Preview ↔ turno salvato
* Breakdown ↔ totale
* Totale giorno ↔ summary mese
