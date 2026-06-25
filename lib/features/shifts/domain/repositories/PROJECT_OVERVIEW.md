# DUTYPAY

## Cos'è

DutyPay è un'app sviluppata per il personale delle Forze dell'Ordine.

Permette di:

* calcolare straordinari
* monitorare indennità e accessorie
* gestire basket tecnici
* monitorare compensativi
* stimare il cedolino futuro
* tenere traccia della propria attività operativa

---

## Problema

Gli strumenti attualmente disponibili presentano spesso:

* calcoli imprecisi
* logiche non aderenti ai reparti reali
* gestione manuale complessa
* scarsa trasparenza sui compensi

Molti operatori sono costretti a verifiche manuali o fogli Excel personali.

---

## Soluzione

DutyPay offre:

* calcolo automatico delle competenze
* logiche specifiche per reparto
* gestione straordinari e accessorie
* breakdown dettagliato dei risultati
* simulazione stipendiale
* monitoraggio basket e compensativi

---

## Reparti supportati

Attualmente implementati:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Ogni reparto utilizza regole operative dedicate e indipendenti.

---

## Architettura

Principi fondamentali:

* motore centralizzato
* singola fonte di verità
* assenza di logica economica nella UI
* separazione dei flussi economici

Source of truth:

`BuildDailyShiftResultUseCase`

---

## Moduli completati

### Calcolo turni

* straordinario automatico
* straordinario programmato
* notturno ordinario
* festivo
* servizi esterni
* Ordine Pubblico

### Basket

* basket straordinari
* basket RFI
* basket compensativo

### Cedolino

* parser NoiPA
* accessorie reali
* profilo dinamico
* previsione cedolino

### Dashboard

* riepiloghi giornalieri
* riepiloghi settimanali
* riepiloghi mensili
* netto stimato

---

## Stato progetto

Release corrente:

**1.0.5**

Stato:

* Android build 18 inviata a Google Play
* iOS build 18 inviata ad Apple

Validazione:

* 78/78 test automatici PASS
* smoke test multi reparto PASS
* validazione utenti reali completata

---

## Roadmap

Priorità successive:

* Fix export dati macOS
* Export / Import avanzato
* Turnario annuale
* Missioni evolute
* Feedback utenti in-app
* Cedolino Pro
* Ulteriori reparti specialistici

---

## Visione

Diventare il punto di riferimento nazionale per il calcolo stipendiale e la gestione operativa del personale delle Forze dell'Ordine.

Obiettivo:

offrire uno strumento preciso, affidabile e costruito sulle esigenze reali degli operatori.
## Stato Giugno 2026

Reparti disponibili:

✅ Reparto Mobile
✅ Polfer
✅ Questura Uffici
✅ Questura Pattuglia
✅ Polstrada (staging)

Framework consolidato:

- overtime automatico
- overtime programmato segmentato
- basket straordinari
- basket compensativo
- compensativo parziale
- reperibilità
- missioni
- servizio esterno
- ticket
- OP

Community WhatsApp ufficiale attiva.
Reparti disponibili

✅ Reparto Mobile
✅ Polfer
✅ Questura Uffici
✅ Questura Pattuglia
✅ Polstrada
---

## Nuova Feature: Break

DutyPay ora include una seconda macro-area sperimentale oltre al core economico.

### Macro-moduli

1. **Core Economico**
   - turni
   - straordinari
   - indennità
   - cedolino
   - basket
   - compensativi

2. **Break**
   - feature sociale collaborativa
   - stanze realtime
   - scelta casuale/sincronizzata di chi paga il caffè

### Scopo Break

Break nasce per aumentare:

- engagement quotidiano;
- uso spontaneo dell'app;
- viralità nei gruppi di colleghi;
- senso di community intorno a DutyPay.

### Tecnologie Break

- Firebase Firestore
- SharedPreferences
- UUID
- stream realtime
- identità anonima locale

### Stato Break

Core/backend implementato.

UI operativa ancora da collegare.