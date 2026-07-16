# DUTYPAY — PROJECT OVERVIEW

## Cos'è DutyPay

DutyPay è un'app Flutter sviluppata per il personale delle Forze dell'Ordine.

L'obiettivo è fornire un unico strumento per la gestione economica e operativa del servizio, sostituendo fogli Excel, calcoli manuali e strumenti non aggiornati.

L'app permette di:

* calcolare automaticamente straordinari;
* monitorare indennità e accessorie;
* gestire Basket Straordinari, Basket RFI e Basket Compensativi;
* stimare il cedolino futuro;
* monitorare la propria attività operativa;
* gestire servizi, turnazioni e benefit.

---

# Problema

Gli strumenti tradizionalmente utilizzati dagli operatori presentano spesso:

* calcoli imprecisi;
* regole non aderenti ai singoli reparti;
* gestione manuale complessa;
* scarsa trasparenza sui compensi;
* impossibilità di simulare scenari futuri.

Molti operatori sono costretti ad utilizzare fogli Excel personali o verifiche manuali.

---

# Soluzione

DutyPay centralizza tutte le logiche economiche in un unico motore di calcolo.

L'app offre:

* calcolo automatico delle competenze;
* regole dedicate per ogni reparto;
* simulazione economica completa;
* breakdown dettagliato dei risultati;
* proiezione del cedolino;
* gestione dei basket;
* monitoraggio compensativi;
* riepiloghi giornalieri, settimanali e mensili.

---

# Reparti supportati

Attualmente sono implementati:

* Reparto Mobile;
* Polfer;
* Questura Uffici;
* Questura Volanti.

L'architettura è progettata per consentire l'aggiunta di nuovi reparti attraverso DepartmentPolicy dedicate, senza modificare il motore centrale.

---

# Architettura

DutyPay adotta una Clean Architecture con separazione rigorosa delle responsabilità.

Principi fondamentali:

* Source of Truth unica;
* nessuna logica economica nella UI;
* motore di calcolo centralizzato;
* separazione Domain ↔ Presentation;
* pipeline di calcolo unificata;
* assenza di duplicazioni.

La Source of Truth dell'intero sistema è:

`BuildDailyShiftResultUseCase`

---

# Moduli principali

## Core Economico

Comprende:

* calcolo turni;
* straordinari;
* straordinario programmato;
* notturno;
* festivo;
* servizi esterni;
* Ordine Pubblico;
* accessorie;
* benefit;
* riepiloghi;
* previsione cedolino.

---

## Basket

Comprende:

* Basket Straordinari;
* Basket Compensativi;
* Basket RFI.

Ogni basket è completamente indipendente dagli altri.

---

## Cedolino

Comprende:

* parser NoiPA;
* estrazione accessorie;
* profilo dinamico;
* proiezione stipendiale;
* simulazione economica.

---

## Dashboard

Comprende:

* riepilogo giornaliero;
* riepilogo settimanale;
* riepilogo mensile;
* netto stimato;
* breakdown economico.

---

## Break

DutyPay include anche un modulo sociale indipendente dal motore economico.

Funzionalità:

* stanze multiplayer;
* sincronizzazione realtime;
* scelta casuale di chi offre il caffè;
* challenge animata;
* identità locale anonima.

Tecnologie utilizzate:

* Firebase Firestore;
* SharedPreferences;
* UUID;
* Stream realtime.

Il modulo Break è completamente separato dal Core Economico e non interferisce con il motore di calcolo.

---

# Stato del progetto

Versione corrente:

**1.0.9 (Release Candidate)**

Stato attuale:

* motore multi reparto consolidato;
* Source of Truth unificata;
* architettura stabile;
* regressioni automatiche complete;
* Flutter Analyze pulito;
* suite di test completamente verde.

---

# Qualità del software

Validazione attuale:

* **160 test automatici PASS**;
* Flutter Analyze: **0 warning / 0 errori**;
* regression pack dedicati per tutti i moduli principali;
* validazione su casi reali e scenari multi reparto.

La strategia di sviluppo prevede che ogni bug corretto generi almeno un nuovo regression test.

---

# Roadmap

Priorità future:

* Polstrada;
* Polaria;
* ulteriori reparti specialistici;
* evoluzione del parser cedolini;
* esportazione dati avanzata;
* missioni evolute;
* miglioramenti UX;
* nuove funzionalità del modulo Break.

---

# Visione

L'obiettivo di DutyPay è diventare il punto di riferimento nazionale per la gestione economica e operativa del personale delle Forze dell'Ordine.

Ogni nuova funzionalità dovrà rispettare tre principi fondamentali:

* massima precisione;
* elevata affidabilità;
* semplicità d'uso.

L'architettura è progettata per evolvere nel tempo mantenendo un motore di calcolo unico, coerente e facilmente estendibile.
## Release 1.0.12 (Build 42)

Stato: Rilasciata

Principali novità:

- Stabilizzazione definitiva del Basket Straordinari.
- Corretto il calcolo delle ore oltre il limite mensile.
- Il basket viene ora ricostruito dinamicamente dai turni salvati.
- Eliminazione dei pagamenti basket registrati.
- Eliminazione delle correzioni basket.
- Migliorata la coerenza tra cedolino previsto e basket.

Validazione:

- flutter analyze PASS
- flutter test 158/158 PASS
- Android Release PASS
- iOS Release PASS

---

## Release 1.0.13 (Build 43)

Stato: Rilasciata su iOS e Android.

Principali interventi:

- corretto il riepilogo mensile del Basket Straordinari nei giorni con più
  servizi distinti;
- impedita la trasformazione automatica di servizi accessori in
  straordinario;
- aggiunto regression test sul caso OP notturno + pranzo + cena;
- verificata la gestione dei turni con data servizio diversa dalla data reale
  di inizio;
- allineata la validazione dei codici stanza personalizzati Break al formato
  dei codici automatici;
- migliorata la diagnostica degli errori di creazione stanza;
- rimossi i log temporanei di sviluppo.

Caso basket validato:

- OP 03/07 20:00 → 04/07 10:00: 8h overtime;
- pranzo 13:00 → 15:00: 0h overtime;
- cena 19:00 → 21:00: 0h overtime;
- totale corretto basket: 8h, anziché 12h.

Validazione tecnica:

- flutter analyze: PASS;
- flutter test: 160/160 PASS;
- Android App Bundle: PASS;
- archivio e upload iOS 1.0.13 (43): PASS;
- pubblicazione Android: completata;
- pubblicazione iOS: completata.
## Stato corrente del progetto

Ultimo aggiornamento: 16 luglio 2026

### Release corrente

- Versione: 1.0.15
- Build: 45
- Android: AAB generato e caricato su Google Play Console
- iOS: archive e IPA generati; build caricata su App Store Connect

### Validazione tecnica

- `flutter analyze` → PASS
- `flutter test` → 164/164 PASS
- `flutter build appbundle --release` → PASS
- `flutter build ipa --release` → PASS

### Architettura di calcolo

DutyPay utilizza una pipeline centralizzata basata sul principio:

**Single Source of Truth**

La catena principale è:

```text
BuildShiftMoneyComponentsUseCase
        ↓
BuildDailyShiftResultUseCase
        ↓
BuildMonthlyAccessorySummaryUseCase
        ↓
PayslipProjectionService
        ↓
UI
