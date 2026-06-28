# DutyPay Roadmap

## Visione

Costruire il punto di riferimento digitale per il personale delle Forze dell'Ordine.

DutyPay deve diventare uno strumento quotidiano:

* preciso;
* affidabile;
* semplice;
* riconoscibile;
* costruito sulle esigenze reali degli operatori.

Ogni evoluzione del prodotto dovrà rispettare questa gerarchia:

1. Precisione
2. Affidabilità
3. Stabilità
4. Esperienza utente
5. Brand Identity
6. Community
7. Innovazione

---

# Stato attuale

DutyPay è un ecosistema composto da quattro aree principali.

## Core Engine

Responsabile di:

* turni;
* straordinari;
* cedolino;
* basket;
* compensativi;
* parser;
* reparti;
* summary.

Il Core Engine rappresenta il cuore del prodotto.

La precisione del motore rimane la priorità assoluta.

Stato:

✅ Consolidato in RC 1.0.9

---

## Experience

Responsabile di:

* UX;
* Break;
* microinterazioni;
* animazioni;
* feedback visivi.

Obiettivo:

rendere l'utilizzo quotidiano semplice e piacevole.

Stato:

🟡 In evoluzione

---

## Brand

Componenti:

* VISION.md;
* DESIGN_SYSTEM.md;
* Agente DP;
* Tone of Voice.

Obiettivo:

costruire un'identità immediatamente riconoscibile.

Stato:

🟡 Avviato

---

## Community

Canali:

* Facebook;
* WhatsApp;
* feedback utenti;
* supporto;
* passaparola.

Obiettivo:

trasformare DutyPay in una community oltre che in un'app.

Stato:

🟡 Attivo

---

# Roadmap

## Fase 1 — Core Engine

Stato:

✅ Completata

Risultato:

* motore economico stabile;
* Source of Truth centralizzata;
* pipeline multi reparto consolidata;
* regression pack estesi.

---

## Fase 2 — Reparti attuali

Stato:

✅ Completata

Reparti consolidati:

* Reparto Mobile;
* Polfer;
* Questura Uffici;
* Questura Volanti.

L'architettura consente l'aggiunta di nuovi reparti tramite DepartmentPolicy dedicate.

---

## Fase 3 — Regression Strategy

Stato:

✅ Completata per RC 1.0.9

Copertura:

* Core Calculation Engine;
* Reparto Mobile;
* Polfer;
* Questura;
* Multi Department;
* Basket Straordinari;
* Basket Compensativi;
* Basket RFI;
* Monthly Summary;
* Break Domain;
* Break DTO;
* Break Challenge Engine.

Suite attuale:

**156 test PASS**

---

## Fase 4 — Break

Stato:

🟡 In completamento

Completato:

* architettura;
* Domain;
* DTO;
* Repository;
* Datasource;
* Challenge Engine;
* regression pack.

Da completare:

* UI definitiva;
* validazione multiplayer reale;
* Firestore Security Rules;
* rifiniture UX.

---

## Fase 5 — Stabilità Release

Stato:

🟡 In corso

Priorità:

* Crashlytics;
* Analytics;
* monitoraggio release;
* zero regressioni;
* smoke test multi reparto;
* verifica store.

Ogni release deve aumentare l'affidabilità del prodotto.

---

## Fase 6 — Nuovi Reparti

Stato:

🔵 Futuro controllato

Possibili candidati:

* Polaria;
* Frontiera;
* Digos;
* Squadra Mobile;
* altri reparti specialistici.

Regola:

nessun nuovo reparto deve introdurre pipeline alternativa al Core Engine.

---

## Fase 7 — Brand Identity

Stato:

🟡 Avviata

Documenti:

* VISION.md;
* DESIGN_SYSTEM.md.

Obiettivo:

trasformare DutyPay da semplice applicazione a prodotto riconoscibile.

---

## Fase 8 — Agente DP

Stato:

🔵 Concept

Agente DP diventerà la mascotte ufficiale di DutyPay.

Utilizzi futuri:

* onboarding;
* empty state;
* loading;
* Break;
* statistiche;
* achievement;
* marketing;
* community.

---

## Fase 9 — Design System completo

Da sviluppare:

* component library;
* palette definitiva;
* motion;
* typography;
* iconografia;
* asset Agente DP.

---

## Fase 10 — Community

Obiettivi:

* maggiore coinvolgimento;
* feedback continui;
* crescita organica;
* contenuti dedicati;
* supporto utenti.

---

## Fase 11 — DutyPay 2.0

Obiettivo finale:

un ecosistema completo composto da:

* Core Engine;
* Experience;
* Brand;
* Community.

Tutti integrati in un unico prodotto.

---

# Regola fondamentale

Ogni nuova funzionalità dovrà rispondere a questa domanda:

"Questa funzione rende DutyPay più precisa, affidabile o utile per l'utente?"

Se la risposta è no, probabilmente non è una priorità.
