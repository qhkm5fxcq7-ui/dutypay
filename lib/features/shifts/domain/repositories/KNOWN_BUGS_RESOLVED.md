# DUTYPAY — KNOWN BUGS RESOLVED

## Obiettivo

Questo documento raccoglie tutte le regressioni critiche risolte nel progetto.

Ogni bug riportato è stato:

- riprodotto;
- corretto;
- validato tramite test automatici o verifica funzionale;
- protetto da regression test quando applicabile.

---

# Stato Generale

Release:

**1.0.9 (Release Candidate)**

Stato:

- Core Engine consolidato;
- Source of Truth unificata;
- nessun bug critico aperto;
- regressioni automatiche complete.

---

# CORE ENGINE

## CORE-001 — Preview diversa dal turno salvato

### Sintomo

La preview mostrava importi differenti rispetto al turno realmente salvato.

### Causa

Calcoli duplicati nella UI.

### Soluzione

Preview collegata direttamente al motore centrale.

### Esito

Preview e turno salvato sono identici.

Status:

✅ RISOLTO

---

## CORE-002 — Breakdown incoerente

### Sintomo

Breakdown corretto ma totale errato.

### Soluzione

Il totale viene ricostruito esclusivamente dal Breakdown del motore.

Status:

✅ RISOLTO

---

## CORE-003 — Duplicazione della logica economica

### Sintomo

Parte dei calcoli veniva eseguita nei widget.

### Soluzione

Centralizzazione definitiva della logica nel Core Engine.

Status:

✅ RISOLTO

---

# REPARTO MOBILE

## RM-001 — Perdita notturno con straordinario

Status:

✅ RISOLTO

Separazione definitiva tra:

- ordinary night;
- overtime night.

---

## RM-002 — Multi-turno non coerente

Status:

✅ RISOLTO

La soglia delle 6 ore viene mantenuta correttamente anche con più turni nello stesso giorno.

---

# POLFER

## POLFER-001 — Falso straordinario

Status:

✅ RISOLTO

Lo straordinario viene calcolato esclusivamente dopo la fine teorica del turno.

---

## POLFER-002 — Breakdown non allineato

Status:

✅ RISOLTO

Il breakdown deriva esclusivamente dal motore.

---

## POLFER-003 — Validazione RFI con overtime programmato

### Sintomo

Lo scalo manuale poteva risultare non valido in presenza di straordinario programmato.

### Soluzione

La validazione considera anche il segmento di overtime programmato.

### Regression Test

Dedicated Regression Pack.

Status:

✅ RISOLTO

---

# QUESTURA

## QUESTURA-001 — Override ordinario errato

Status:

✅ RISOLTO

Supportati:

- 6h;
- 7h12;
- custom.

---

## QUESTURA-002 — Totale preview errato

Status:

✅ RISOLTO

Totale ricostruito dal Breakdown.

---

## QUESTURA-003 — Preview diversa dal dettaglio

Status:

✅ RISOLTO

Entrambi utilizzano il motore centrale.

---

# BASKET STRAORDINARI

## BASKET-001 — Pagamenti non aggiornavano il residuo

Status:

✅ RISOLTO

Il residuo viene aggiornato correttamente.

---

## BASKET-002 — Correzioni manuali assenti

Status:

✅ RISOLTO

Introdotto:

- OvertimeBasketAdjustment;
- persistenza dedicata;
- integrazione nel Cedolino.

---

## BASKET-003 — Persistenza non separata

Status:

✅ RISOLTO

Storage dedicato:

dutypay_overtime_basket_adjustments_<department>

---

# BASKET COMPENSATIVO

## COMP-001 — Adjustment senza nota

Status:

✅ RISOLTO

Le correzioni richiedono nota obbligatoria.

---

## COMP-002 — Eliminazione movimenti automatici

Status:

✅ RISOLTO

Solo gli adjustment possono essere eliminati.

---

## COMP-003 — Formula residuo

Status:

✅ RISOLTO

Formula consolidata:

earned

-

recovered

+

adjustments

---

# RFI

## RFI-001 — Basket RFI a zero

Status:

✅ RISOLTO

Utilizzo esclusivo di:

rfiMonthlySummaries

---

## RFI-002 — RFI mostrato come ore

Status:

✅ RISOLTO

Visualizzazione esclusivamente economica.

---

## RFI-003 — Pipeline condivisa con overtime

Status:

✅ RISOLTO

RFI completamente separato da:

- overtime;
- accessorie;
- compensativi.

---

# BENEFIT

## BENEFIT-001 — Benefit conteggiati nel totale

Status:

✅ RISOLTO

Benefit esclusi dai flussi economici.

---

## BENEFIT-002 — Ticket non persistente

Status:

✅ RISOLTO

Serializzazione allineata.

---

## BENEFIT-003 — Comfort duplicato

Status:

✅ RISOLTO

Pipeline normalizzata.

---

# PARSER CEDOLINI

## PARSER-001 — Blocco accessorie errato

Status:

✅ RISOLTO

Utilizzata sempre l'ultima occorrenza.

---

## PARSER-002 — Parsing PDF incompleto

Status:

✅ RISOLTO

Fixture reali introdotte.

---

## PARSER-003 — Tariffe straordinario errate

Status:

✅ RISOLTO

Profilo dinamico ricostruito correttamente.

---

# BREAK

## BREAK-001 — Architettura non isolata

Status:

✅ RISOLTO

Break completamente indipendente dal Core Economico.

---

## BREAK-002 — Serializzazione DTO

Status:

✅ RISOLTO

Regression Pack dedicato.

---

## BREAK-003 — Challenge Engine

Status:

✅ RISOLTO

Challenge deterministica tramite seed condiviso.

---

# UI

## UI-001 — Reset turno errato

Status:

✅ RISOLTO

Gestione dello stato corretta.

---

## UI-002 — Quick Add Preview

Status:

✅ RISOLTO

La preview utilizza esclusivamente il motore centrale.

---

# REGRESSION PACK INTRODOTTI

Proteggono attualmente:

- Core Calculation Engine;
- Reparto Mobile;
- Polfer;
- Questura;
- Multi Department;
- Monthly Summary;
- Basket Straordinari;
- Basket Compensativi;
- RFI;
- Break Domain;
- Break DTO;
- Break Challenge Engine.

---

# Stato Validazione

Suite automatica:

**156/156 PASS**

flutter analyze:

✅ PASS

Nessun warning.

Nessun errore.

---

# Regola Permanente

Ogni nuovo bug deve seguire questo workflow:

1. riproduzione;
2. correzione;
3. regression test dedicato;
4. aggiornamento di questo documento.

Una regressione non protetta da test è considerata incompleta.