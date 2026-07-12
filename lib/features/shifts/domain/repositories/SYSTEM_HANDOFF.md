# DUTYPAY — SYSTEM HANDOFF (MASTER)

## Cos'è DutyPay

DutyPay è un'app Flutter dedicata al personale delle Forze dell'Ordine.

Obiettivo:

* calcolo turni;
* straordinari;
* accessorie;
* basket;
* compensativi;
* stima cedolino;
* gestione multi reparto;
* modulo Break ("Chi offre?").

Principi fondamentali:

* accuratezza;
* comportamento reale;
* architettura modulare;
* singola Source of Truth;
* assenza di duplicazioni logiche;
* regression testing continuo.

---

# Release Baseline

Versione attuale:

**1.0.9 (Release Candidate)**

Reparti supportati:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Moduli aggiuntivi:

* Break ("Chi offre?")

Stato:

* motore multi reparto consolidato;
* Source of Truth unificata;
* regressioni automatiche complete;
* Flutter Analyze completamente pulito;
* suite automatica completamente verde.

---

# Architettura

## Presentation

Responsabilità:

* Flutter UI;
* schermate;
* dashboard;
* cards;
* calendario;
* preview;
* animazioni Break.

Vincoli:

* nessuna logica economica;
* nessun calcolo duplicato;
* visualizzazione esclusivamente dei risultati prodotti dal motore.

---

## Application

Responsabilità:

* orchestrazione;
* aggregazione risultati;
* costruzione summary;
* coordinamento tra Domain e Presentation.

UseCase principali:

* CalculateShiftUseCase
* BuildShiftComputationUseCase
* BuildDailyShiftResultUseCase
* BuildMonthlySummaryUseCase
* BuildCompensativeBasketMovementsUseCase

---

## Domain

Responsabilità:

* motore economico;
* policy reparto;
* regole operative;
* gestione basket;
* logica compensativi.

Department Policy attive:

* RepartoMobilePolicy
* PolferPolicy
* QuesturaPolicy

Ogni nuovo reparto dovrà essere implementato esclusivamente attraverso una nuova DepartmentPolicy.

---

# Source of Truth

La fonte di verità assoluta del sistema è:

**BuildDailyShiftResultUseCase**

Responsabile di:

* overtime;
* notturno;
* festivo;
* ordine pubblico;
* servizi esterni;
* benefit;
* basket;
* compensativi;
* breakdown;
* totale turno;
* totale giornata;
* dati utilizzati da dashboard e cedolino.

Nessun widget può eseguire calcoli economici autonomi.

---

# Pipeline di Calcolo

Il flusso ufficiale del motore è:

```
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

Questa pipeline rappresenta l'unico percorso autorizzato per il calcolo economico.

---

# Regole Fondamentali

1. Nessuna logica economica nella UI.
2. Nessuna duplicazione dei calcoli.
3. Nessuna reintroduzione di codice legacy.
4. Preview e turno salvato devono essere identici.
5. Breakdown e totale devono essere coerenti.
6. Ogni nuova regola passa dal motore centrale.
7. Ogni DepartmentPolicy gestisce esclusivamente il proprio reparto.
8. Ogni bug corretto genera almeno un regression test.
9. Ogni nuova funzionalità deve preservare la Source of Truth.

---

# Flussi Economici

Ogni turno può generare:

* straordinario;
* notturno;
* accessorie;
* ordine pubblico;
* servizi esterni.

Tutti questi valori confluiscono nel totale economico del turno.

---

# Basket Straordinari

Sistema dedicato.

Caratteristiche:

* gestione indipendente;
* pagamenti manuali;
* proiezione cedolino;
* storico movimenti;
* correzioni manuali.

---

# Basket RFI

Pipeline completamente separata.

Caratteristiche:

* generazione automatica da scalo;
* stato OPEN;
* pagamento manuale;
* stato PAID;
* incluso nel cedolino soltanto nel mese del pagamento.

Mai mescolato con:

* straordinari;
* compensativi;
* accessorie.

---

# Basket Compensativo

Pipeline autonoma.

Caratteristiche:

* basato esclusivamente sulle ore;
* non rappresenta denaro;
* indipendente dal basket RFI;
* indipendente dagli straordinari.

Supporta:

* earned automatico;
* recovered automatico;
* adjustment manuali.

Vincoli:

* earned non eliminabile;
* recovered non eliminabile;
* adjustment unico movimento modificabile.

---

# Benefit Flow

Benefit completamente separati dai flussi economici.

Categorie:

* ticket meal;
* comfort;
* comfort CDG.

Regole:

* amount = 0;
* benefitAmount valorizzato;
* isBenefit = true.

Mai inclusi in:

* totalAmount;
* extraAmount;
* cedolino.

---

# Programmed Overtime

Implementazione segmentata.

Caratteristiche:

* segmento programmato considerato overtime certo;
* clamp automatico sul turno reale;
* pagamento o compensativo;
* integrazione nel basket compensativo quando previsto.

Il segmento compensativo:

* entra nel basket compensativo;
* non incrementa il totale pagato.

---

# Questura Uffici

Supporta:

* ordinario personalizzato;
* override 6h;
* override 7h12;
* override libero.

Straordinario:

solo oltre l'orario ordinario configurato.

---

# Questura Volanti

Preset disponibili:

* Mattina;
* Pomeriggio;
* Sera;
* Notte.

Regola:

* ordinario fino al termine del preset;
* straordinario soltanto oltre il preset.

---

# Parser Cedolini

Regola fondamentale.

Nei cedolini NoiPA il blocco

"Assegni accessori"

può comparire più volte.

Il parser deve utilizzare sempre l'ultima occorrenza.

Motivazione:

solo il dettaglio finale contiene le righe realmente valide.

---

# Modulo Break

Architettura indipendente.

Comprende:

* gestione identità locale;
* stanze multiplayer;
* sincronizzazione Firestore;
* challenge engine;
* animazioni deterministiche;
* DTO dedicati;
* Domain separato.

Il modulo Break non deve mai interferire con il motore economico di DutyPay.

---

# Stato Validazione

Reparti validati:

* Reparto Mobile;
* Polfer;
* Questura Uffici;
* Questura Volanti.

Regression Pack disponibili:

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

Copertura funzionale:

* Engine di calcolo;
* Parser cedolini;
* Basket;
* Summary mensili;
* Multi reparto;
* Break.

Suite automatica:

**160 / 160 PASS**

Flutter Analyze:

* 0 warning;
* 0 errori.

---

# Handoff Finale Release Candidate 1.0.9

Stato generale:

* motore multi reparto consolidato;
* Source of Truth centralizzata su BuildDailyShiftResultUseCase;
* CalculateShiftUseCase introdotto come punto di accesso unico;
* pipeline economica completamente unificata;
* eliminati gli ultimi punti di duplicazione tra UI e Domain;
* preview, turno salvato, dashboard e riepiloghi completamente allineati;
* consolidata la gestione indipendente di:
  * Basket Straordinari;
  * Basket Compensativi;
  * Basket RFI;
* corretta la validazione dello scalo manuale RFI con straordinario programmato;
* modulo Break coperto da regression pack dedicati.

---

# Vincoli Assoluti

NON ROMPERE:

* soglia RM 6h;
* logica notturna Polfer;
* controllo territorio Polfer;
* override Questura Uffici;
* preset Questura Volanti;
* Basket Straordinari;
* Basket Compensativi;
* Basket RFI;
* Preview ↔ Turno salvato;
* Breakdown ↔ Totale;
* Totale giornata ↔ Summary mese;
* Source of Truth;
* Pipeline CalculateShiftUseCase → BuildDailyShiftResultUseCase;
* separazione Domain ↔ Presentation;
* determinismo del Challenge Engine Break.

---

# Regola Finale

Qualsiasi modifica al motore di calcolo deve rispettare quattro condizioni obbligatorie:

1. aggiornare il motore centrale;
2. aggiungere almeno un regression test;
3. mantenere verde l'intera suite automatica;
4. preservare la coerenza tra Preview, Dashboard, Cedolino e Summary.

Questo documento rappresenta la baseline architetturale ufficiale della Release Candidate **DutyPay 1.0.9**.
---

# Handoff Release 1.0.13+43

Stato:

- release pubblicata su iOS e Android;
- flutter analyze PASS;
- 160/160 test PASS;
- AAB Android generato e pubblicato;
- archivio iOS 1.0.13 build 43 generato e caricato.

## Basket Straordinari

Corretto il calcolo del riepilogo mensile nei giorni con servizi multipli.

Il Basket Straordinari non deve più usare come ore effettive la trasformazione
cumulativa giornaliera quando il singolo turno non possiede straordinario
proprio.

Regola protetta:

- ore legacy manuali: prioritarie;
- turni moderni: usare le ore straordinarie proprie del turno;
- servizi accessori separati non devono diventare straordinario per il solo
  fatto di condividere la stessa data servizio.

Regression case ufficiale:

- OP notturno: 8h;
- pranzo: 0h;
- cena: 0h;
- totale basket: 8h.

## Turni cross-midnight

Scenario validato:

- data servizio 04/07;
- inizio reale 03/07 ore 20:00;
- fine 04/07 ore 10:00;
- durata 14h;
- straordinario 8h.

Il raggruppamento mensile e giornaliero deve usare `serviceDate`.

## Break

La validazione dei codici stanza personalizzati deve restare coerente con il
generatore automatico.

Formati validi:

- MAZ123;
- BRL-12;
- BRK-ABCDE.

Vincoli:

- lunghezza da 3 a 12 caratteri;
- lettere e numeri;
- massimo un trattino;
- errori di validazione mostrati all'utente;
- errori Firestore registrati tramite logging tecnico.

## Baseline corrente

- DutyPay 1.0.13;
- build 43;
- suite automatica 160/160 PASS;
- Flutter Analyze pulito;
- iOS e Android pubblicati.
