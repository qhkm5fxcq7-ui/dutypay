# DUTYPAY — CALCULATION RULES

## Obiettivo

Questo documento definisce le regole ufficiali del motore di calcolo di DutyPay.

È la fonte di riferimento per:

* sviluppo;
* debugging;
* regression test;
* validazione funzionale;
* nuove implementazioni.

Non contiene:

* roadmap;
* codice temporaneo;
* workaround;
* logiche legacy.

---

# Release di riferimento

**Release Candidate 1.0.9**

Stato:

* motore multi-reparto consolidato;
* Source of Truth unificata;
* regressioni automatiche complete;
* `flutter analyze` senza warning;
* **156 test automatici PASS**.

---

# Source of Truth

Il motore economico è organizzato su due livelli.

## CalculateShiftUseCase

Responsabile di:

* selezione della DepartmentPolicy;
* calcolo del singolo turno;
* produzione dello `ShiftCalculationResult`.

---

## BuildDailyShiftResultUseCase

È l'unica Source of Truth utilizzata dall'intera applicazione.

Responsabile di:

* overtime;
* ore ordinarie;
* notturno;
* festivo;
* Ordine Pubblico;
* servizi esterni;
* accessorie;
* compensativi;
* basket;
* breakdown;
* totale turno;
* totale giornata.

Qualsiasi schermata deve leggere esclusivamente i risultati prodotti da questo UseCase.

---

# Pipeline ufficiale

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

↓

Preview

↓

Dettaglio Turno

↓

Cedolino

↓

Summary Mensile

---

# Regole comuni

## Ore lavorate

Le ore lavorate sono sempre:

```
end - start
```

Se:

```
end <= start
```

il turno attraversa la mezzanotte e viene automaticamente normalizzato.

---

## Fasce orarie

### Diurno

06:00 → 22:00

### Notturno

22:00 → 06:00

---

## Festivi

Sono considerati festivi:

* domeniche;
* festività nazionali;
* festività particolari.

La classificazione viene rivalutata automaticamente dopo la mezzanotte.

---

## Assenze

Le assenze:

* restano visibili;
* non generano importi;
* non generano overtime.

Output previsto:

* totale = 0
* overtime = 0
* breakdown vuoto

---

# Benefit

Categorie supportate:

* ticket_meal
* comfort
* comfort_cdg

Caratteristiche:

* visualizzati nella UI;
* presenti nel breakdown;
* esclusi dai calcoli economici.

Regole:

* amount = 0
* benefitAmount valorizzato
* isBenefit = true

Mai inclusi in:

* totalAmount;
* extraAmount;
* cedolino.

---

# Reparto Mobile

## Regola ordinaria

Soglia:

**6 ore**

Le ore successive diventano straordinario.

---

## Segmentazione

Supportata:

* overtime day;
* overtime night;
* overtime holiday;
* overtime holiday night.

---

## Notturno

22:00 → 06:00

Il notturno ordinario è indipendente dallo straordinario.

Possono coesistere:

* ordinaryNightHours;
* overtimeNightHours.

Mai sottrarre uno dall'altro.

---

## Multi turno

Supportato.

Il consumo delle ore ordinarie deve essere coerente nell'intera giornata.

---

## Indennità

Supportate:

* OP sede;
* OP fuori sede;
* OP pernotto;
* servizi esterni;
* festivo;
* festività particolare.

---

# Polfer

## Straordinario

Non utilizza la soglia fissa di 6 ore.

Lo straordinario inizia dopo la fine teorica del preset.

Preset:

* Mattina → 13:08
* Pomeriggio → 19:08
* Sera → 00:08
* Notte → 07:08

---

## Controllo territorio

Supportato:

* serale;
* notturno.

Le due indennità restano indipendenti.

---

## Scalo ferroviario

Supportato:

* ridotto;
* intero;
* misto;
* inserimento manuale.

Lo scalo genera esclusivamente Basket RFI.

Non produce straordinario.

La validazione dello scalo manuale considera anche l'eventuale straordinario programmato distribuito sul turno.

---

# Questura Uffici

Supportato:

* ordinario configurabile;
* override 6h;
* override 7h12;
* override libero.

Lo straordinario inizia esclusivamente oltre l'ordinario configurato.

---

# Questura Volanti

Preset ufficiali:

* Mattina;
* Pomeriggio;
* Sera;
* Notte.

Lo straordinario parte dopo la fine del preset.

Supporta:

* override ordinario;
* straordinario programmato;
* servizi esterni;
* notturno ordinario.

---

# Polstrada

Riutilizza la stessa pipeline di Questura Pattuglia.

Supporta:

* preset dedicati;
* servizi esterni;
* ticket;
* compensativi;
* straordinario programmato;
* basket straordinari;
* basket compensativi.

L'indennità autostradale è prevista dall'architettura ma potrà essere attivata solo con valori ufficiali definitivi.

---

# Straordinario programmato

È gestito come segmento temporale.

Campi:

* programmedOvertimeEnabled
* programmedOvertimeStart
* programmedOvertimeEnd
* overtimeDestination

Pipeline:

1. calcolo intersezione;
2. clamp sul turno reale;
3. classificazione come overtime certo.

Destinazioni:

## Payment

Produce importo economico.

## Compensative

Produce ore compensative.

Non produce importo economico.

---

# Basket Straordinari

Gestisce esclusivamente lo straordinario maturato.

Supporta:

* pagamenti;
* correzioni manuali;
* proiezione cedolino.

È indipendente da:

* Basket RFI;
* Basket Compensativi.

---

# Basket Compensativi

Gestisce esclusivamente ore.

Movimenti:

* earned;
* recovered;
* adjustment.

Formula:

```
Residual =
Earned
- Recovered
+ Adjustments
```

Regole:

* earned non modificabile;
* recovered non modificabile;
* adjustment modificabile;
* adjustment eliminabile;
* nota obbligatoria.

---

# Basket RFI

Pipeline completamente separata.

Turno

↓

Scalo

↓

RFI Basket

↓

OPEN

↓

PAID

↓

Cedolino

Mai miscelato con:

* straordinari;
* compensativi;
* accessorie.

Solo il movimento PAID entra nella proiezione del cedolino.

---

# Cedolino

Pipeline:

Breakdown

↓

Aggregazione mensile

↓

Esclusione Benefit

↓

Esclusione Basket RFI OPEN

↓

Totale Lordo

↓

Fiscalità stimata

↓

Netto previsto

Tutti i calcoli restano in lordo fino all'ultimo passaggio.

---

# Preview

La Quick Add Shift Page non esegue alcun calcolo economico.

Legge esclusivamente il risultato del motore.

Devono sempre coincidere:

* preview;
* turno salvato;
* dashboard;
* riepilogo mensile.

---

# Validazioni

Ogni nuova regola deve essere validata tramite regression test.

Ogni bug corretto deve generare almeno un nuovo test.

---

# Regressioni ufficiali

Copertura attuale:

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

---

# Vincoli assoluti

Non devono mai rompersi:

* Source of Truth;
* Preview ↔ turno salvato;
* Breakdown ↔ totale;
* Totale giorno ↔ summary mese;
* soglia RM 6h;
* preset Polfer;
* override Questura;
* preset Volanti;
* separazione Basket Straordinari;
* separazione Basket Compensativi;
* separazione Basket RFI;
* Benefit fuori dai flussi economici;
* nessuna logica economica nei widget.

---

# Stato di validazione

Versione:

**DutyPay RC 1.0.9**

Stato:

* motore consolidato;
* architettura stabile;
* regressioni complete;
* `flutter analyze` PASS;
* **156/156 test PASS**.

Qualsiasi futura modifica del motore dovrà mantenere invariate le regole documentate in questo file oppure aggiornarle contestualmente.
