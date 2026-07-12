# DutyPay 1.0.13 — Basket & Break Stabilization

Versione: 1.0.13  
Build: 43  
Stato: pubblicata su iOS e Android

## Obiettivo

La release 1.0.13 corregge una sovrastima delle ore nel Basket Straordinari
quando più servizi distinti condividevano la stessa data servizio e migliora
la gestione dei codici stanza personalizzati del modulo Break.

## Basket Straordinari

### Problema

Il riepilogo mensile usato dalla proiezione cedolino elaborava i turni della
stessa giornata in un contesto cumulativo.

Dopo il consumo delle ore ordinarie da parte del primo servizio, turni
successivi potevano essere trasformati impropriamente in straordinario.

### Caso reale

Data servizio: 04/07/2026

- OP 03/07 20:00 → 04/07 10:00: 8h overtime;
- pranzo 13:00 → 15:00: 0h overtime;
- cena 19:00 → 21:00: 0h overtime.

Prima della correzione:

- riepilogo basket: 12h.

Dopo la correzione:

- riepilogo basket: 8h.

### Soluzione

`BuildMonthlyAccessorySummaryUseCase` usa ora:

- le ore straordinarie manuali legacy, quando presenti;
- altrimenti le ore straordinarie proprie del singolo turno.

Il contesto giornaliero continua a essere disponibile per le altre elaborazioni,
ma non può inventare ore basket su servizi separati.

## Turni notturni

Validato il caso:

- data servizio: 04/07/2026;
- data reale inizio: 03/07/2026;
- orario: 20:00 → 10:00;
- durata: 14h;
- straordinario: 8h.

Il turno rimane associato alla data servizio selezionata.

## Break

### Problema

Il generatore automatico produceva codici con trattino, mentre la validazione
manuale accettava inizialmente solo lettere e numeri.

### Soluzione

Sono ora accettati codici:

- da 3 a 12 caratteri;
- con lettere e numeri;
- con un eventuale trattino.

Test manuali:

- MAZ123: PASS;
- BRL-12: PASS;
- codice non valido: messaggio specifico mostrato.

È stato inoltre aggiunto logging tecnico per gli errori Firestore durante la
creazione stanza.

## Pulizia

Rimossi:

- PREVIEW TOTAL;
- PREVIEW SHIFT;
- SHIFT SAVE DEBUG.

## Validazione

- dart format: PASS;
- flutter analyze: PASS;
- flutter test: 160/160 PASS;
- test Basket specifici: PASS;
- regression test Basket: PASS;
- build Android App Bundle: PASS;
- archivio iOS 1.0.13 build 43: PASS;
- upload App Store Connect: PASS;
- upload Google Play: PASS.

## File principali modificati

- lib/features/shifts/application/usecases/build_monthly_accessory_summary_usecase.dart
- lib/features/break/data/repositories/firestore_break_room_repository.dart
- lib/features/break/presentation/break_page.dart
- test/unit/usecases/build_monthly_accessory_summary_usecase_test.dart
- test/unit/usecases/build_monthly_summary_usecase_test.dart
- test/regression/basket_regression_test.dart
