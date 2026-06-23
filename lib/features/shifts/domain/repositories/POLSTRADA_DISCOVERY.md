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
## Aggiornamento discovery – Validazioni Manuel

Validazioni ricevute:

- straordinario: uguale per tutti i reparti;
- ore notturne: uguali;
- ticket: mantenere toggle manuale;
- reperibilità: uguale;
- turni ordinari: pagati come gli altri reparti;
- unica differenza reale attualmente identificata: indennità specifiche Polstrada.

Conclusione aggiornata:

Polstrada può essere implementata riutilizzando quasi integralmente Questura Volanti.

La logica nuova deve essere limitata alle sole indennità Polstrada.

## Stato indennità Polstrada

Gli importi non sono ancora disponibili.

Per evitare blocchi nello sviluppo:

- predisporre architettura;
- aggiungere campi configurabili nel profilo economico;
- non hardcodare importi;
- usare default `0.0`;
- mostrare toggle/opzioni solo se utile;
- consentire futura valorizzazione senza migrazione pesante.

## Impatto tecnico aggiornato

Riuso stimato da Questura Volanti:

95%

Nuovi elementi realmente necessari:

- `Department.polstrada`
- preset Polstrada:
  - Notte 01:00 → 07:00
  - Mattina 07:00 → 13:00
  - Pomeriggio 13:00 → 19:00
  - Sera 19:00 → 01:00
- campi economici per indennità Polstrada nel profilo
- eventuale toggle o selector per indennità Polstrada
- breakdown category dedicata

Elementi da NON duplicare:

- straordinario
- notturno
- ticket
- reperibilità
- compensativo
- basket
- missione
- OP
- servizio esterno
- controllo territorio
- PayslipProjection
- BuildDailyShiftResultUseCase

## Decisione operativa

Si può procedere alla Fase 2 con implementazione leggera:

1. aggiungere reparto Polstrada;
2. riusare Questura Volanti come base logica;
3. aggiungere preset orari Polstrada;
4. predisporre indennità Polstrada con valore 0.0 configurabile;
5. non bloccare lo sviluppo in attesa degli importi definitivi.
# STATO IMPLEMENTAZIONE

## Preset confermati

Mattina
06:55 → 13:08

Pomeriggio
12:55 → 19:08

Sera
18:55 → 01:08

Notte
00:55 → 07:08

## Chiusure teoriche

Mattina → 13:08
Pomeriggio → 19:08
Sera → 01:08
Notte → 07:08

## Implementazione

Completata.

Riutilizzo framework:

≈95%

Base architetturale:

Questura Pattuglia

## Stato rilascio

STAGING

Motivo:

In attesa delle tabelle ufficiali delle indennità autostradali.
# IMPLEMENTAZIONE COMPLETATA

## Funzioni implementate

- Preset ufficiali Polstrada
- Servizio autostradale
- Servizio esterno
- Straordinario automatico
- Straordinario programmato
- Compensativo
- Dashboard integrata
- Persistenza completa

## Indennità autostradale

Valori attuali:

Mattina:
€ 9,50

Pomeriggio:
€ 9,50

Sera:
€ 12,00

Notte:
€ 14,50

## Stato

Completata.

Validata tramite test automatici e test manuali.

Pronta per il rilascio.
