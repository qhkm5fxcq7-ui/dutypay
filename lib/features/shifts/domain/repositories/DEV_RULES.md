# DEV RULES – DUTYPAY

## Scopo

Queste regole hanno priorità su qualsiasi implementazione.

Se una modifica viola una di queste regole, la modifica deve essere rifiutata o riprogettata.

---

# Baseline Attuale

Release:

**DutyPay 1.0.9 (Release Candidate)**

Stato:

* motore multi-reparto consolidato;
* Source of Truth unificata;
* Break isolato dal Core Economico;
* suite automatica: 160 test PASS;
* flutter analyze: 0 warning / 0 errori.

---

# REGOLA 1 — Una sola Source of Truth

La Source of Truth assoluta è:

**BuildDailyShiftResultUseCase**

Responsabile di:

* overtime;
* notturno;
* festivo;
* OP;
* servizi esterni;
* accessorie;
* benefit;
* compensativi;
* basket;
* breakdown;
* totale turno;
* totale giorno;
* summary.

È vietato creare una seconda fonte della verità.

---

# REGOLA 2 — Pipeline obbligatoria

La pipeline ufficiale è:

```text
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
Dashboard / Preview / Cedolino / Summary
```

È vietato bypassare questa pipeline.

---

# REGOLA 3 — Nessuna logica economica in UI

I widget possono:

* leggere dati;
* visualizzare dati;
* raccogliere input utente.

I widget NON possono:

* calcolare overtime;
* calcolare importi;
* segmentare ore;
* classificare notturno;
* classificare festivo;
* applicare regole reparto.

Qualsiasi calcolo economico deve vivere nel motore.

---

# REGOLA 4 — Nessuna duplicazione

È vietato duplicare logica tra:

* Shift;
* Policy;
* UseCase;
* UI;
* Summary;
* Preview.

Prima di aggiungere una regola verificare sempre:

1. esiste già?
2. può essere riutilizzata?
3. può essere centralizzata?

---

# REGOLA 5 — Le Policy sono proprietarie del reparto

Le logiche reparto devono vivere esclusivamente nelle Policy.

Policy attive:

* RepartoMobilePolicy;
* PolferPolicy;
* QuesturaPolicy.

Le regole di un reparto non devono contaminare gli altri.

---

# REGOLA 6 — Reparti isolati

Reparto Mobile:

* soglia ordinaria 6h.

Polfer:

* scheduled end;
* territorio;
* notturno;
* RFI.

Questura Uffici:

* ordinario personalizzato.

Questura Volanti:

* preset operativi.

Nessuna regola deve propagarsi ad altri reparti senza esplicita progettazione.

---

# REGOLA 7 — RFI è una pipeline separata

RFI non è:

* overtime;
* accessoria;
* compensativo.

Pipeline:

```text
OPEN
↓
PAID
↓
Cedolino
```

Mai usare:

```text
monthlySummaries
```

per gestire RFI.

Utilizzare sempre:

```text
rfiMonthlySummaries
```

---

# REGOLA 8 — Basket Compensativo separato

Il Basket Compensativo:

* non è denaro;
* non è RFI;
* non è accessoria.

Gestisce esclusivamente ore.

I compensativi non devono influenzare:

* cedolino;
* overtime pagato;
* accessorie;
* Basket RFI.

---

# REGOLA 9 — Basket Straordinari separato

Il Basket Straordinari gestisce solo:

* ore straordinario;
* pagamenti;
* correzioni manuali;
* residuo;
* proiezione cedolino.

Non deve essere accorpato a:

* RFI;
* compensativi;
* benefit.

---

# REGOLA 10 — Programmed Overtime

Lo straordinario programmato è:

* un segmento temporale.

Non è:

* un override dell'intero turno.

Regole:

* clamp al turno reale;
* può essere pagato;
* può essere compensativo.

Destinazione compensativa:

* entra nel Basket Compensativo;
* non entra nel totale economico.

---

# REGOLA 11 — Preview = Reality

La preview deve sempre essere identica a:

* turno salvato;
* dettaglio turno;
* totale giorno;
* summary.

Se esiste una differenza, è un bug critico.

---

# REGOLA 12 — Breakdown = Totale

Il breakdown deve sempre ricostruire il totale.

Non devono esistere:

* righe fantasma;
* importi nascosti;
* componenti non rappresentate.

---

# REGOLA 13 — UseCase senza logica reparto

I UseCase possono:

* orchestrare;
* aggregare;
* adattare dati.

I UseCase non devono:

* implementare logiche reparto;
* classificare ore;
* classificare festivi;
* calcolare importi specifici di reparto.

---

# REGOLA 14 — Nessun fallback legacy

È vietato:

* recuperare vecchie logiche;
* utilizzare metodi obsoleti come fonte di verità;
* usare risultati legacy come fallback.

Ogni nuova implementazione deve utilizzare il motore corrente.

---

# REGOLA 15 — Ogni bug genera un test

Flusso obbligatorio:

```text
bug
↓
test di riproduzione
↓
fix
↓
validazione
```

Mai correggere un bug senza introdurre protezione contro la regressione.

---

# REGOLA 16 — Parser Cedolini

Il parser deve utilizzare fixture reali.

Ogni nuovo bug parser deve produrre:

* fixture reale;
* test automatico;
* correzione.

Mai fare refactor del parser senza copertura test.

---

# REGOLA 17 — Break isolato

Break è indipendente dal Core Economico.

Non può dipendere da:

* turni;
* cedolino;
* basket;
* compensativi;
* DepartmentPolicy;
* parser cedolini;
* profili stipendiali.

Il Challenge Engine deve restare deterministico.

---

# REGOLA 18 — Release Gate

Prima di ogni release:

* flutter analyze;
* flutter test;
* smoke test multi reparto;
* verifica preview ↔ dettaglio;
* verifica totale giorno ↔ summary mese;
* verifica Basket RFI;
* verifica Basket Compensativo;
* verifica Basket Straordinari;
* verifica Break se incluso nella release.

---

# Regola Finale

Queste regole rappresentano la costituzione tecnica del progetto.

Qualsiasi modifica che violi la Source of Truth, duplichi calcoli o reintroduca logica legacy deve essere respinta.
