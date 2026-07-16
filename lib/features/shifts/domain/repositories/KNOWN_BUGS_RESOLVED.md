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

**160/160 PASS**

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
## Basket Straordinari (1.0.12)

Problema:
Il basket poteva perdere coerenza dopo modifiche retroattive ai turni o dopo registrazioni manuali.

Soluzione:
Il basket viene ricostruito dinamicamente dai riepiloghi mensili e dai movimenti manuali, senza dipendere da stati persistenti.

Sono inoltre disponibili:

- eliminazione pagamenti basket;
- eliminazione correzioni basket.

Stato:
RISOLTO
---

## BASKET-013 — Sovrastima nei giorni con più servizi distinti

Versione risoluzione: 1.0.13+43

Problema:

Il riepilogo mensile utilizzato dal Basket Straordinari poteva trasformare
impropriamente in straordinario i servizi aggiuntivi registrati nella stessa
data servizio.

Caso reale riprodotto:

- OP 03/07 20:00 → 04/07 10:00: 8h di straordinario;
- pranzo 04/07 13:00 → 15:00: 0h;
- cena 04/07 19:00 → 21:00: 0h.

Risultato precedente:

- 12h nel riepilogo basket.

Risultato corretto:

- 8h nel riepilogo basket.

Soluzione:

`BuildMonthlyAccessorySummaryUseCase` usa ora:

- le ore straordinarie legacy quantificate manualmente, quando presenti;
- altrimenti le ore straordinarie proprie del singolo turno.

Il contesto cumulativo giornaliero non può più creare ore basket su servizi
distinti che non possiedono straordinario proprio.

Test:

- regression test sul caso OP + pranzo + cena;
- aggiornamento del test sui servizi multipli;
- suite completa 160/160 PASS.

Stato:

RISOLTO

---

## SHIFT-013 — Turno notturno con data servizio successiva

Versione verifica: 1.0.13+43

Scenario validato:

- data servizio: 04/07/2026;
- data reale di inizio: 03/07/2026;
- orario: 20:00 → 10:00;
- durata: 14h;
- straordinario: 8h.

Il turno resta associato alla data servizio selezionata e non viene aggregato
al precedente turno del 3 luglio.

È stato aggiunto un test di regressione dedicato.

Stato:

VALIDATO

---

## BREAK-013 — Codice stanza personalizzato non coerente con quello automatico

Versione risoluzione: 1.0.13+43

Problema:

Il generatore automatico produce codici con trattino, ad esempio
`BRK-ABCDE`, mentre la validazione dei codici personalizzati accettava
inizialmente soltanto lettere e numeri.

Soluzione:

- codici da 3 a 12 caratteri;
- lettere e numeri consentiti;
- ammesso un trattino;
- gestione specifica degli errori di validazione;
- logging tecnico degli errori Firestore durante la creazione stanza.

Verifica manuale:

- `MAZ123`: PASS;
- `BRL-12`: PASS;
- codice non valido: messaggio specifico mostrato.

Stato:

RISOLTO

---

## BASKET-014 — Maturazione ritardata del mese corrente

Versione risoluzione: 1.0.14+44

Problema:

Le ore eccedenti la soglia mensile configurata dall'utente entravano nel
basket solo quando il mese diventava mese di riferimento delle competenze
accessorie.

Soluzione:

La maturazione del basket è stata separata dal ritardo del cedolino.

Regola:

- il basket include immediatamente l'eccedenza del mese corrente;
- il cedolino continua a rispettare il ritardo delle accessorie;
- la soglia è quella configurata dal singolo utente tramite
  `monthlyOvertimePayableHoursLimit`.

Test:

- 55h configurate, 60h maturate → 5h basket;
- 40h configurate, 46h maturate → 6h basket;
- nessuna anticipazione delle accessorie nel cedolino;
- suite completa 162/162 PASS;
- verifica manuale su app PASS.

Stato:

RISOLTO
