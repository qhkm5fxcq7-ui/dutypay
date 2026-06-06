# DEV RULES – DUTYPAY

## Scopo

Queste regole hanno priorità su qualsiasi implementazione.

Se una modifica viola una di queste regole, la modifica deve essere rifiutata o riprogettata.

---

# REGOLA 1

## Una sola fonte della verità

La source of truth assoluta è:

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

È vietato creare una seconda fonte della verità.

---

# REGOLA 2

## Nessuna logica economica in UI

I widget possono:

* leggere dati
* visualizzare dati

I widget NON possono:

* calcolare overtime
* calcolare importi
* segmentare ore
* classificare notturno
* classificare festivo

Qualsiasi calcolo economico deve vivere nel motore.

---

# REGOLA 3

## Nessuna duplicazione

È vietato duplicare logica tra:

* Shift
* Policy
* UseCase
* UI

Prima di aggiungere una regola verificare sempre:

1. esiste già?
2. può essere riutilizzata?
3. può essere centralizzata?

---

# REGOLA 4

## Le Policy sono proprietarie del reparto

Le logiche reparto devono vivere esclusivamente nelle Policy.

Policy attive:

* RepartoMobilePolicy
* PolferPolicy
* QuesturaPolicy

Le regole di un reparto non devono contaminare gli altri.

---

# REGOLA 5

## Reparti isolati

Reparto Mobile:

* soglia ordinaria 6h

Polfer:

* scheduled end
* logica territorio
* logica notturno

Questura Uffici:

* ordinario personalizzato

Questura Volanti:

* preset operativi

Nessuna regola deve propagarsi ad altri reparti senza esplicita progettazione.

---

# REGOLA 6

## RFI è una pipeline separata

RFI non è:

* overtime
* accessoria
* compensativo

Pipeline:

OPEN
↓
PAID
↓
Cedolino

Mai usare:

monthlySummaries

per gestire RFI.

Utilizzare sempre:

rfiMonthlySummaries

---

# REGOLA 7

## Basket Compensativo separato

Il basket compensativo:

* non è denaro
* non è RFI
* non è accessoria

Gestisce esclusivamente ore.

I compensativi non devono influenzare:

* cedolino
* overtime pagato
* accessorie

---

# REGOLA 8

## Programmed Overtime

Lo straordinario programmato è:

un segmento temporale

NON:

un override dell'intero turno

Regole:

* clamp al turno reale
* può essere pagato
* può essere compensativo

Destinazione compensativa:

* entra nel basket compensativo
* non entra nel totale economico

---

# REGOLA 9

## Preview = Reality

La preview deve sempre essere identica a:

* turno salvato
* dettaglio turno
* totale giorno

Se esiste una differenza:

è considerato un bug critico.

---

# REGOLA 10

## Breakdown = Totale

Il breakdown deve sempre ricostruire il totale.

Non devono esistere:

* righe fantasma
* importi nascosti
* componenti non rappresentate

---

# REGOLA 11

## UseCase non devono fare business logic

I UseCase possono:

* orchestrare
* aggregare
* adattare dati

I UseCase non devono:

* implementare logiche reparto
* classificare ore
* classificare festivi
* calcolare importi

---

# REGOLA 12

## Nessun fallback legacy

È vietato:

* recuperare vecchie logiche
* utilizzare metodi obsoleti
* usare risultati legacy come fallback

Ogni nuova implementazione deve utilizzare il motore corrente.

---

# REGOLA 13

## Ogni bug genera un test

Flusso obbligatorio:

bug
↓
test riproduzione
↓
fix
↓
validazione

Mai correggere un bug senza introdurre una protezione contro la regressione.

---

# REGOLA 14

## Parser Cedolini

Il parser deve utilizzare:

fixture reali

Ogni nuovo bug parser deve produrre:

* fixture reale
* test automatico
* correzione

Mai fare refactor del parser senza copertura test.

---

# REGOLA 15

## Release Gate

Prima di ogni release:

* flutter analyze
* flutter test
* smoke test multi reparto
* verifica preview ↔ dettaglio
* verifica totale giorno ↔ summary mese
* verifica basket RFI
* verifica basket compensativo

Solo dopo è consentita la pubblicazione.

---

# Baseline Attuale

Release:

DutyPay 1.0.5

Reparti supportati:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Queste regole rappresentano la costituzione tecnica del progetto.
