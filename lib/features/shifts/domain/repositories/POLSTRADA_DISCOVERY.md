# POLSTRADA_DISCOVERY.md

## Stato

Discovery iniziale per implementazione Polizia Stradale in DutyPay.

Obiettivo: verificare quanto sia riutilizzabile dal modulo Questura Volanti prima di introdurre logiche dedicate.

## Ipotesi iniziale

Polstrada ≈ Questura Volanti + Indennità Autostradale

Ipotesi attualmente plausibile, ma non ancora confermata al 100%.

## Turni operativi raccolti

* Notte: 01:00 → 07:00
* Mattina: 07:00 → 13:00
* Pomeriggio: 13:00 → 19:00
* Sera: 19:00 → 01:00

Questi turni sono compatibili con una logica molto simile a Questura Volanti, con turni da 6 ore e gestione cross-midnight per sera/notte.

## Confronto con Questura Volanti

### Elementi riutilizzabili

* preset turni
* calcolo ore lavorate
* calcolo straordinario eccedente
* straordinario programmato
* compensativo
* basket straordinari
* basket compensativo
* servizio esterno
* controllo del territorio
* OP
* missione
* reperibilità
* cambio turno
* ticket
* ore notturne
* UI QuickAddShift esistente
* cedolino e projection esistenti

### Elementi nuovi

* indennità autostradale
* eventuale distinzione pattuglia/radio/ufficio
* eventuali maggiorazioni future
* eventuale preset specifico Polstrada
* breakdown dedicato per voce autostradale

## Impatto UI

Probabile impatto basso.

Da aggiungere:

* selezione reparto `Polizia Stradale`
* preset Polstrada
* toggle/selettore `Indennità autostradale`
* eventuale scelta tipo servizio:

  * pattuglia
  * radio
  * ufficio

Da evitare:

* nuova schermata dedicata se non necessaria
* duplicazione UI Volanti

## Impatto motore

Impatto medio-basso se l’ipotesi viene confermata.

Strategia consigliata:

* riutilizzare la logica Questura/Volanti
* aggiungere policy specifica solo per indennità autostradale
* non duplicare BuildDailyShiftResultUseCase
* non toccare PayslipProjection salvo necessità reale

## Impatto cedolino

Cedolino può restare invariato.

Serve solo che l’indennità autostradale entri nel breakdown come voce accessoria ordinaria, non basket RFI.

## Impatto basket

Il basket straordinari ordinario può essere riutilizzato.

Nessun nuovo basket previsto.

RFI resta separato e non va riutilizzato per Polstrada.

## Impatto compensativo

Compensativo riutilizzabile integralmente.

Nessuna logica nuova prevista.

## Indennità autostradale

Punto critico da validare prima dell’implementazione definitiva.

Valori non ancora certi.

Da raccogliere:

* importo mattina
* importo pomeriggio
* importo sera
* importo notte
* differenza pattuglia
* differenza radio
* differenza ufficio
* eventuali maggiorazioni festive/notturne
* eventuali regole territoriali o convenzionali

Architettura consigliata:

* predisporre campi nel profilo economico
* usare placeholder controllato se i valori non sono certi
* evitare hardcode nel motore

## Nuovi enum possibili

Da valutare:

* `Department.polstrada`
* `PolstradaServiceType`

  * patrol
  * radio
  * office
* eventuale flag `autostradaAllowance`

## Nuovi preset

Possibili preset:

* polstradaNotte: 01:00 → 07:00
* polstradaMattina: 07:00 → 13:00
* polstradaPomeriggio: 13:00 → 19:00
* polstradaSera: 19:00 → 01:00

## Nuove breakdown category

Probabile nuova categoria:

* `polstrada_highway_allowance`

Etichetta UI:

* `Indennità autostradale`

## Nuove dashboard card

Non necessarie in Fase 1.

Eventuale card futura:

* Totale indennità autostradali mese

## Test richiesti

### Unit test

* Polstrada turno mattina standard
* Polstrada turno pomeriggio standard
* Polstrada turno sera cross-midnight
* Polstrada turno notte
* Polstrada straordinario pre/post turno
* Polstrada indennità autostradale attiva
* Polstrada indennità autostradale disattiva
* Polstrada servizio esterno
* Polstrada controllo territorio
* Polstrada compensativo
* Polstrada basket straordinari

### Regression test

* Questura Volanti invariata
* Polfer RFI invariato
* Reparto Mobile invariato
* Basket ordinario invariato
* Basket compensativo invariato

## Percentuale stimata di riuso Questura Volanti

Stima iniziale:

85% - 90%

Motivo:
la struttura turni e la logica di straordinario sembrano molto vicine a Volanti. La differenza reale sembra essere l’indennità autostradale.

## Rischio regressione

Basso se:

* si introduce `Department.polstrada`
* si riutilizzano policy esistenti
* si isola l’indennità autostradale
* si evitano modifiche a PayslipProjection
* si evitano modifiche a BuildDailyShiftResultUseCase

Medio se:

* si tocca la logica comune di Questura
* si modifica il basket
* si modifica la pipeline cedolino

## Piano implementativo proposto

### Step 1 — Discovery

Completare validazione valori indennità autostradale.

### Step 2 — Department

Aggiungere `Department.polstrada`.

### Step 3 — Preset

Aggiungere preset Polstrada:

* notte
* mattina
* pomeriggio
* sera

### Step 4 — UI

Aggiungere opzione indennità autostradale nella QuickAddShiftPage.

### Step 5 — Profilo economico

Aggiungere campi tariffa indennità autostradale nel UserPayProfile.

### Step 6 — Engine

Aggiungere breakdown dedicato senza toccare basket/RFI.

### Step 7 — Test

Aggiungere test unitari e regression.

### Step 8 — Manual QA

Verifica con collega Polstrada.

## Conclusione

L’ipotesi Polstrada ≈ Questura Volanti + Indennità Autostradale è tecnicamente plausibile.

Prima dell’implementazione definitiva serve confermare i valori economici dell’indennità autostradale e le eventuali differenze tra pattuglia, radio e ufficio.

Non creare un motore separato in Fase 1.
