# TEST STRATEGY

## Obiettivo

La strategia di test di DutyPay garantisce che ogni modifica mantenga la coerenza del motore di calcolo e non introduca regressioni tra i diversi reparti o moduli dell'applicazione.

Ogni bug corretto deve produrre almeno un nuovo test automatico.

Una modifica non è considerata completata finché:

1. il bug è riproducibile;
2. esiste un test che fallisce prima della correzione;
3. il test passa dopo la correzione;
4. l'intera suite rimane completamente verde.

---

# Parser Testing Strategy

I test parser devono utilizzare:

* fixture reali (PDF o testo reale)
* non dati sintetici

## Motivazione

I cedolini NoiPA presentano frequentemente:

* duplicazione dei blocchi;
* layout non lineare;
* variazioni di formattazione;
* righe ripetute;
* differenze tra reparti.

I test sintetici non sono sufficienti a garantire affidabilità.

## Regola obbligatoria

Qualsiasi bug del parser scoperto in produzione deve generare:

1. nuova fixture reale;
2. nuovo test automatico;
3. correzione del parser.

La fixture deve essere aggiunta prima del refactor.

---

# Parser Cedolini – Fixture Reali

## File

`test/unit/parser/payslip_parser_service_test.dart`

## Fixture validate

* RM Marzo 2026
* RM Febbraio 2026
* Polfer Marzo 2026

## Verifiche

Per ogni fixture vengono controllati:

* parsing riepilogo cedolino;
* accessoryEntries;
* operationalAccessoryEntries;
* tariffe straordinario;
* costruzione profilo dinamico.

---

# Core Engine Regression

Copertura:

* CalculateShiftUseCase
* BuildShiftComputationUseCase
* BuildDailyShiftResultUseCase
* BuildMonthlySummaryUseCase

Verifiche:

* straordinari;
* notturno;
* festivo;
* ordine pubblico;
* benefit;
* compensativi;
* breakdown;
* totale turno;
* riepilogo giornaliero;
* riepilogo mensile.

---

# Department Regression Packs

## Reparto Mobile

Copertura:

* soglia ordinaria 6h;
* straordinario;
* notturno;
* ordine pubblico;
* servizi esterni;
* riepiloghi mensili.

---

## Polfer

Copertura:

* fine turno teorica;
* controllo territorio;
* RFI;
* scalo automatico;
* scalo manuale;
* straordinario programmato.

---

## Questura

Copertura:

### Uffici

* override ordinario;
* 6h;
* 7h12;
* personalizzato.

### Volanti

* preset mattina;
* preset pomeriggio;
* preset sera;
* preset notte;
* straordinario oltre preset.

---

## Multi Department

Verifica:

* isolamento delle policy;
* nessuna contaminazione tra reparti;
* stessa casistica produce risultati differenti solo quando previsto dalle rispettive regole.

---

# Programmed Overtime

Copertura:

* segmento programmato;
* clamp automatico;
* destinazione pagamento;
* destinazione compensativo.

Verifiche:

* overtime corretto;
* compensativo corretto;
* importo pagato corretto.

---

# Basket Regression

## Basket Straordinari

Copertura:

* pagamenti;
* residuo;
* serializzazione;
* persistenza.

---

## Basket Compensativi

Copertura:

* earned;
* recovered;
* adjustment;
* riepiloghi;
* governance.

Verifiche:

* adjustment positivo;
* adjustment negativo;
* nota obbligatoria;
* eliminazione consentita solo agli adjustment.

---

## Basket RFI

Copertura:

* generazione automatica;
* stato OPEN;
* pagamento;
* stato PAID;
* proiezione cedolino.

Verifiche:

* nessuna interferenza con:
  * straordinari;
  * compensativi;
  * accessorie.

---

# Break Regression Packs

## Domain

Copertura:

* BreakRoom;
* BreakParticipant;
* BreakIdentity.

---

## DTO

Copertura:

* serializzazione;
* deserializzazione;
* backward compatibility.

---

## Challenge Engine

Copertura:

* ChallengeRunner;
* ChallengeFrame;
* ChallengeState;
* determinismo del motore;
* vincitore;
* animazioni;
* frame generati.

---

# UI Regression

Verificare sempre:

* Preview = turno salvato;
* Breakdown = totale;
* Totale turno = riepilogo giornaliero;
* Riepilogo giornaliero = riepilogo mensile;
* Cedolino = proiezione motore.

---

# Release Validation Checklist

Prima di ogni release devono risultare verdi:

* flutter analyze
* flutter test
* regression pack Reparto Mobile
* regression pack Polfer
* regression pack Questura
* regression pack Multi Department
* regression pack Basket Straordinari
* regression pack Basket Compensativi
* regression pack Basket RFI
* regression pack Break Domain
* regression pack Break DTO
* regression pack Break Challenge Engine

---

# Stato attuale

Versione validata:

**DutyPay 1.0.9**

Reparti supportati:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Suite automatica:

**160 test superati**

Verifica qualità:

* flutter analyze → 0 errori
* flutter test → PASS

La suite di regressione protegge l'intero motore di calcolo e tutti i moduli principali dell'applicazione.
## Regression Pack — Release 1.0.15

Nuovi regression test introdotti.

### quick_add_shift_daily_context_regression_test.dart

Verifica che la preview della modifica turno utilizzi il contesto giornaliero completo.

Protegge da regressioni nella ricostruzione del contesto.

---

### quick_add_shift_rm_external_service_regression_test.dart

Verifica che il toggle "Servizio esterno" del Reparto Mobile:

- sia visibile;
- possa essere modificato;
- venga salvato correttamente.

Protegge da regressioni della UI.

---

Stato suite:

164 test PASS.
