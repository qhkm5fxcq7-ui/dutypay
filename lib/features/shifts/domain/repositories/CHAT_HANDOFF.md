# DUTYPAY — CHAT HANDOFF

## Baseline Attuale

Release:

**1.0.5**

Stato:

* Android build 18 inviata a Google Play
* iOS build 18 inviata ad Apple
* Test automatici PASS
* Sistema stabile

---

# Reparti Attivi

## Reparto Mobile

Validato:

* soglia ordinaria 6h
* overtime automatico
* notturno ordinario
* festivo
* notturno festivo
* OP
* servizi esterni
* multi-turno

Status:

✅ STABILE

---

## Polfer

Validato:

* mattina standard
* pomeriggio standard
* sera standard
* notte standard
* territorio serale
* territorio notturno
* scalo RFI

Regole:

* overtime dopo fine turno teorica
* notturno dalle 22:00
* nessuna soglia 6h

Status:

✅ STABILE

---

## Questura Uffici

Validato:

* override 6h
* override 7h12
* override personalizzato
* straordinario automatico

Status:

✅ STABILE

---

## Questura Volanti

Preset attivi:

* Mattina
* Pomeriggio
* Sera
* Notte

Validato:

* straordinario automatico
* straordinario programmato
* notturno ordinario
* servizio esterno
* preview
* dettaglio turno

Status:

✅ STABILE

---

# Source of Truth

Fonte assoluta:

BuildDailyShiftResultUseCase

Responsabile di:

* overtime
* notturno
* festivo
* breakdown
* totale turno
* totale giorno
* accessorie
* compensativi

Nessun widget può eseguire calcoli paralleli.

---

# Pipeline

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
UI

---

# Basket RFI

Pipeline separata.

Flusso:

Scalo
↓
OPEN
↓
PAID
↓
Cedolino

Regole:

* non è overtime
* non è accessoria
* non è compensativo

Mai usare:

monthlySummaries

Usare:

rfiMonthlySummaries

---

# Basket Compensativo

Pipeline autonoma.

Supporta:

* earned automatico
* recovered automatico
* adjustment manuali

Regole:

* basato su ore
* non è denaro
* non entra nel cedolino
* non entra nel basket RFI

Storage:

dutypay_compensative_basket_movements_<department>

---

# Programmed Overtime

Implementazione attiva.

Caratteristiche:

* overtime come segmento temporale
* clamp automatico
* supporto compensativo
* supporto overtime pagato

Se compensativo:

* entra nel basket compensativo
* non entra nel totale economico

---

# Parser Cedolini

Validato con fixture reali.

Copertura:

* RM Febbraio 2026
* RM Marzo 2026
* Polfer Marzo 2026

Regola critica:

utilizzare sempre l'ultima occorrenza del blocco:

"Assegni accessori"

---

# Benefit

Supportati:

* ticket meal
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

# Test Status

flutter test

PASS

flutter analyze

0 errori bloccanti

Baseline validata:

* RM
* Polfer
* Questura Uffici
* Questura Volanti
* RFI
* Compensativi
* Programmed Overtime
* Parser Cedolini

---

# Bug Noti

## Export macOS

Errore:

Bytes are not supported on macOS

Impatto:

nessuno su Android/iOS

Target:

Release 1.0.6

---

# Cose da Non Rompere

* RM soglia 6h
* Polfer scheduled end
* Questura override ordinario
* Preset Volanti
* Basket RFI
* Basket Compensativo
* Preview ↔ dettaglio
* Breakdown ↔ totale
* Totale giorno ↔ summary mese

---

# Priorità 1.0.6

1. Fix export macOS.
2. Miglioramento export/import dati.
3. Turnario annuale.
4. Missioni evolute.
5. Feedback utenti in-app.
6. Cedolino Pro.

---

# Prompt di Ripartenza

Leggere:

1. SYSTEM_HANDOFF.md
2. CALCULATION_RULES.md
3. ARCHITECTURE.md
4. CHAT_HANDOFF.md

Assumere che:

* la release 1.0.5 sia stabile
* i reparti attuali siano validati
* il motore centrale non debba essere rifattorizzato

Obiettivo:

proseguire l'evoluzione senza introdurre regressioni.
## Handoff post RC-BASKET – 10/06/2026

Stato:
- suite completa: `+86 All tests passed`;
- aggiunti test regressione basket ordinario e compensativo;
- implementata correzione manuale basket straordinari;
- confermata separazione:
  - basket straordinari ordinario;
  - basket compensativo;
  - basket RFI.

Fix rilevanti:
- `OvertimeBasketAdjustment`;
- storage scoped `dutypay_overtime_basket_adjustments_<department>`;
- `PayslipProjectionService.projectPayslip()` riceve `overtimeBasketAdjustments`;
- UI Cedolino: pulsante “Correzione basket” nella card basket straordinari.

Regola confermata:
RFI resta sistema separato e non viene accorpato a straordinari/accessorie standard.
# AGGIORNAMENTO GIUGNO 2026 – POLSTRADA

## Stato attuale

Framework stabile.

Reparti supportati:

- Reparto Mobile
- Polfer
- Questura Uffici
- Questura Pattuglia
- Polstrada (staging)

## Test

flutter test

86/86 PASS

## Community

Community WhatsApp DutyPay attiva:

- Bacheca
- Domande e Suggerimenti
- Segnalazioni Bug

## Release

Polstrada NON rilasciata.

Motivazione:

Mancano le tabelle ufficiali delle indennità autostradali.

Decisione:

Mantenere Polstrada in staging fino alla disponibilità dei valori ufficiali.
---

# BREAK FEATURE — HANDOFF

È iniziato lo sviluppo della nuova feature sociale **Break**.

## Obiettivo

Aumentare:

- frequenza d'utilizzo quotidiana;
- viralità dell'app;
- passaparola tra colleghi.

Funzione principale prevista:

```text
☕ Chi paga il caffè
