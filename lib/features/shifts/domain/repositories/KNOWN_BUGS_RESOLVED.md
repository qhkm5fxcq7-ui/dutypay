# DUTYPAY — KNOWN BUGS RESOLVED

## Obiettivo

Mantenere traccia delle regressioni critiche risolte nel progetto.

Ogni bug riportato in questo documento:

* è stato riprodotto
* è stato corretto
* è stato validato tramite test o verifica manuale

---

# Reparto Mobile

## RM-001 — Perdita notturno con straordinario

### Sintomo

La quota di notturno ordinario veniva ridotta o persa in presenza di straordinario notturno.

### Causa

Errore nella segmentazione tra:

* ordinary night
* overtime night

### Soluzione

Separazione completa delle due componenti.

### Esito

* ordinary night sempre preservato
* overtime night indipendente
* breakdown corretto

Status:

✅ RISOLTO

---

## RM-002 — Utilizzo scenari Volanti come baseline RM

### Sintomo

Venivano utilizzati turni tipo:

06:55 → 13:08

come riferimento RM.

### Causa

Confusione tra logiche Reparto Mobile e turnazione in quinta.

### Soluzione

Formalizzazione scenari canonici RM:

* soglia ordinaria 6h

### Esito

Regole RM isolate.

Status:

✅ RISOLTO

---

# Polfer

## POLFER-001 — Falso straordinario

### Sintomo

Turni standard producevano straordinario non dovuto.

### Causa

Utilizzo della soglia RM 6h.

### Soluzione

Utilizzo della fine turno teorica Polfer.

### Esito

* mattina standard corretta
* sera standard corretta
* notte standard corretta

Status:

✅ RISOLTO

---

## POLFER-002 — Breakdown incoerente

### Sintomo

Breakdown diverso dal risultato reale.

### Causa

Merge con logica legacy.

### Soluzione

Breakdown generato esclusivamente dal motore.

### Esito

Preview e dettaglio coerenti.

Status:

✅ RISOLTO

---

# RFI

## RFI-001 — Scalo spariva dopo il salvataggio

### Sintomo

Lo scalo risultava corretto in preview ma non dopo il salvataggio.

### Causa

Pipeline mista engine/serializzazione.

### Soluzione

Separazione completa:

* calcolo
* persistenza

### Esito

Preview e turno salvato identici.

Status:

✅ RISOLTO

---

## RFI-002 — Basket RFI a zero

### Sintomo

Importi RFI non visualizzati correttamente.

### Causa

Uso errato di:

monthlySummaries

invece di:

rfiMonthlySummaries

### Soluzione

Pipeline dedicata.

### Esito

Basket aggiornato correttamente.

Status:

✅ RISOLTO

---

## RFI-003 — RFI mostrato come ore

### Sintomo

Il basket RFI mostrava valori orari.

### Soluzione

Visualizzazione esclusivamente economica.

### Esito

Solo importi in euro.

Status:

✅ RISOLTO

---

# Benefit

## BENEFIT-001 — Benefit sommati al totale

### Sintomo

Ticket e comfort venivano sommati agli importi economici.

### Causa

Mancata distinzione tra:

* benefit
* importi monetari

### Soluzione

Introduzione struttura standard:

* amount = 0.0
* benefitAmount valorizzato
* isBenefit = true

### Esito

Benefit visibili ma non conteggiati.

Status:

✅ RISOLTO

---

## BENEFIT-002 — Duplicazione comfort

### Sintomo

Comfort visualizzato due volte.

### Soluzione

Normalizzazione pipeline benefit.

Status:

✅ RISOLTO

---

## BENEFIT-003 — Ticket assente post-salvataggio

### Sintomo

Ticket visibile in preview ma non dopo il salvataggio.

### Soluzione

Allineamento serializzazione.

Status:

✅ RISOLTO

---

# Parser Cedolini

## PARSER-001 — Lettura blocco accessorie errato

### Sintomo

Accessorie incomplete.

### Causa

Parser utilizzava il riepilogo iniziale.

### Soluzione

Utilizzo dell'ultima occorrenza del blocco accessorie.

### Esito

Parsing corretto.

Status:

✅ RISOLTO

---

## PARSER-002 — PDF reali non estratti correttamente

### Sintomo

Accessorie mancanti.

### Soluzione

Introduzione fixture reali e copertura test.

Status:

✅ RISOLTO

---

## PARSER-003 — Derivazione rate straordinario errata

### Sintomo

Profilo dinamico non corretto.

### Soluzione

Parsing completo delle accessorie.

Status:

✅ RISOLTO

---

# Questura

## QUESTURA-001 — Preview override ordinario errata

### Sintomo

Preview mostrava valori overtime diversi dal motore.

### Soluzione

Preview collegata direttamente al computation del motore.

### Esito

Override 6h, 7h12 e custom corretti.

Status:

✅ RISOLTO

---

## QUESTURA-002 — Totale turno a zero con breakdown valorizzato

### Sintomo

Preview:

€0.00

nonostante breakdown corretto.

### Causa

TotalAmount non ricostruito dal breakdown.

### Soluzione

Ricostruzione del totale dai valori del motore.

### Esito

Preview coerente.

Status:

✅ RISOLTO

---

## QUESTURA-003 — Preview diversa dal dettaglio turno

### Sintomo

Valori differenti tra:

* preview
* turno salvato

### Soluzione

Entrambi leggono la stessa computation.

### Esito

Allineamento completo.

Status:

✅ RISOLTO

---

# UI

## UI-001 — Reset turno dopo selezione assenza

### Sintomo

Campi turno azzerati in modo errato.

### Soluzione

Correzione gestione stato.

Status:

✅ RISOLTO

---

# Baseline 1.0.5

Tutti i bug sopra riportati risultano:

✅ corretti

✅ validati

✅ inclusi nella release 1.0.5
## RC-BASKET-OVERTIME-01 – Risolto

Corretto e stabilizzato il sistema basket straordinari ordinario.

Interventi:
- aggiunto modello `OvertimeBasketAdjustment`;
- aggiunta persistenza scoped per correzioni basket straordinari;
- collegata la correzione manuale alla projection cedolino;
- aggiunto pulsante UI “Correzione basket” nella card basket straordinari;
- verificato che i pagamenti basket riducano correttamente il residuo;
- mantenuta separazione tra basket straordinari, basket compensativo e basket RFI.

Test:
- `test/regression/basket_regression_test.dart`
- suite completa PASS: `+86 All tests passed`
# GIUGNO 2026

## Fix preset sera Polstrada

Problema:

La chiusura teorica utilizzava il comportamento delle Volanti.

Effetto:

Generazione errata dello straordinario.

Fix:

Chiusura teorica corretta a 01:08.

Risultato:

18:55 → 01:08

0 ore straordinario.

---

## Fix preset notte Polstrada

Problema:

Calcolo errato delle ore notturne.

Effetto:

13h05 di notturno.

Fix:

Correzione della normalizzazione tra scheduled end e gestione giorni.

Risultato:

00:55 → 07:08

Notturno corretto.
Straordinario corretto.

---

## Basket Straordinari

Corrette:

- correzioni manuali
- persistenza
- residuo
- scarico basket
- controvalore economico

Regression test aggiunti.

flutter test

86/86 PASS
## Polstrada – Servizio esterno bloccato

Problema:

Il servizio esterno risultava non selezionabile.

Causa:

Condizione condivisa con Questura Pattuglia.

Fix:

Abilitata la selezione contemporanea di:

- Servizio autostradale
- Servizio esterno

Risultato:

Entrambe le indennità vengono correttamente sommate.
