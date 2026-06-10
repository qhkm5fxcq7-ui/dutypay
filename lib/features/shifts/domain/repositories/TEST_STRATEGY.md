# TEST STRATEGY

## Parser Testing Strategy

I test parser devono utilizzare:

* fixture reali (PDF o raw text reale)
* non solo dati sintetici

### Motivazione

I cedolini NoiPA presentano frequentemente:

* duplicazione blocchi
* layout non lineare
* variazioni di formattazione
* righe ripetute
* differenze tra reparti

I test sintetici non sono sufficienti per garantire affidabilità.

### Regola obbligatoria

Qualsiasi bug parser scoperto in produzione deve generare:

1. nuova fixture reale
2. nuovo test automatico
3. successiva correzione del parser

La fixture deve essere introdotta prima del refactor del parser.

---

## Test RFI obbligatori

Copertura minima richiesta:

### Inserimento scalo

Verificare:

* generazione automatica basket RFI
* inserimento movimento OPEN

### Separazione contabile

Verificare:

* nessun impatto su accessorie
* nessun impatto su straordinari
* nessun impatto su compensativi

### Pagamento

Verificare:

* pagamento manuale
* passaggio OPEN → PAID

### Cedolino

Verificare:

* inclusione solo nel mese di pagamento

### UI

Verificare sempre:

* Preview = turno salvato
* Card = dettaglio turno
* Totale = breakdown

---

## Parser Cedolini – Fixture Reali

### File test

`test/unit/parser/payslip_parser_service_test.dart`

### Fixture validate

* RM Marzo 2026
* RM Febbraio 2026
* Polfer Marzo 2026

### Verifiche effettuate

Per ogni fixture:

* parsing corretto riepilogo cedolino
* estrazione corretta accessoryEntries
* estrazione corretta operationalAccessoryEntries
* derivazione corretta tariffe straordinario
* costruzione corretta profilo dinamico

### Esito

Tutti i test passano.

### Impatto

Questa copertura protegge:

* parser cedolino
* accessorie reali
* profilo dinamico
* stima cedolino
* regressioni future

---

## Programmed Overtime Segment Tests

### File test

`test/unit/usecases/programmed_overtime_segment_test.dart`

### Covered Cases

#### Caso 1 – Ordinary + Programmed Overtime

Turno:

* 07:00–16:00

Programmato:

* 13:00–16:00

Atteso:

* overtime = 3h

---

#### Caso 2 – Programmed Compensative Overtime

Turno:

* 07:00–16:00

Programmato:

* 13:00–16:00

Destinazione:

* compensativo

Atteso:

* overtime totale = 3h
* compensativo = 3h
* importo pagato = 0

---

#### Caso 3 – Out of Range Segment

Turno:

* 07:00–13:00

Programmato:

* 12:00–18:00

Atteso:

* clamp corretto
* overtime = 1h

### Regression Requirements

Devono rimanere stabili:

* soglia RM 6h
* logica Polfer notturno e territorio
* logica Questura Uffici
* logica preset Questura Volanti
* overtime programmato
* compensativi programmati
* separazione basket RFI

---

## Compensative Basket Test Coverage

### Summary Model

Copertura:

* earned − recovered = residual
* adjustment positivo
* adjustment negativo

### Movement Model

Copertura:

* JSON serialization
* JSON deserialization
* fallback sicuro movement type sconosciuto

### Movement Builder

Copertura:

* earned da turno compensativo
* recovered da Recupero compensativo
* storico misto nello stesso mese

### Summary From Movements

Copertura:

* earned aggregation
* recovered aggregation
* adjustment aggregation
* validazione formula residuale

### Adjustment Governance

Copertura:

* adjustment positivo aumenta residuo
* adjustment negativo diminuisce residuo
* nota vuota blocca adjustment
* delete consentito solo sugli adjustment

### Immutability Rules

Movimenti automatici:

* earned = generato dal sistema
* recovered = generato dal sistema

Regole:

* earned non modificabile
* earned non eliminabile
* recovered non modificabile
* recovered non eliminabile

L'unico movimento modificabile dall'utente è:

* adjustment

### Regression Requirements

I compensativi:

* non devono impattare il cedolino
* non devono impattare il basket RFI
* non devono impattare il basket pagamenti
* non devono alterare la segmentazione overtime programmato
* non devono alterare il motore centrale

---

## Release Baseline

Versione validata:

DutyPay 1.0.5

Reparti coperti:

* Reparto Mobile
* Polfer
* Questura Uffici
* Questura Volanti

Prima di ogni release:

* flutter analyze
* flutter test
* smoke test multi reparto
* verifica preview ↔ dettaglio ↔ summary
## Regression tests aggiunti

### RC-BASKET-OVERTIME-01
File:
`test/regression/basket_regression_test.dart`

Copre:
- pagamento basket straordinari;
- riduzione residuo ore;
- serializzazione/deserializzazione `BasketPayment`.

### RC-BASKET-COMPENSATIVO-01
File:
`test/regression/compensative_basket_regression_test.dart`

Copre:
- ore compensative maturate;
- ore recuperate;
- correzione manuale positiva;
- correzione manuale negativa;
- blocco correzione senza nota;
- eliminazione consentita solo per correzioni manuali.

Stato:
`flutter test` PASS: `+86 All tests passed`.
