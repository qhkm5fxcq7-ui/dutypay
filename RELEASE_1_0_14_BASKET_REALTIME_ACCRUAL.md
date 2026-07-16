# DutyPay 1.0.14 — Basket Real-Time Accrual

Versione: 1.0.14  
Build: 44  
Stato: hotfix

## Problema

Le ore eccedenti la soglia mensile configurata dall'utente diventavano
visibili nel Basket Straordinari solo quando il mese entrava nel ciclo
delle competenze accessorie del cedolino.

## Regola corretta

Il basket deve maturare immediatamente nel mese in cui lo straordinario
supera la soglia personale impostata dall'utente.

Il ritardo delle competenze accessorie continua ad applicarsi soltanto
al cedolino.

## Soluzione

Sono state separate:

- la pipeline del mese di riferimento cedolino;
- la pipeline dei mesi rilevanti per la maturazione del basket.

Il basket ora considera tutti i mesi fino al mese selezionato compreso.

La soglia resta dinamica ed è letta da:

`monthlyOvertimePayableHoursLimit`

## Scenari protetti

- limite personale 55h, straordinario 60h → 5h basket;
- limite personale 40h, straordinario 46h → 6h basket;
- mese corrente incluso immediatamente;
- nessuna anticipazione delle accessorie nel cedolino.

## Validazione

- flutter analyze: PASS;
- flutter test: 162/162 PASS;
- regression pack Basket: 11/11 PASS;
- verifica manuale su app: PASS.
