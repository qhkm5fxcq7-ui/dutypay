# DutyPay 1.0.12 — Basket Stabilization Release

Versione: 1.0.12  
Build: 42  
Stato: rilasciata su Android e iOS

## Validazione

- flutter analyze: PASS
- flutter test: 158/158 PASS
- flutter build appbundle --release: PASS
- flutter build ipa --release: PASS

## Contenuto principale

La release 1.0.12 stabilizza il Basket Straordinari.

Il basket viene ricostruito dinamicamente da turni, riepiloghi mensili, pagamenti basket e correzioni basket.

## Correzioni principali

- Corretto il calcolo delle ore oltre il limite mensile.
- Corretto il riepilogo mensile che poteva gonfiare le ore straordinario.
- Corretto il ricalcolo dopo modifica turni.
- Aggiunta eliminazione pagamenti basket.
- Aggiunta eliminazione correzioni basket.
- Migliorata coerenza tra basket, cedolino previsto e pagamenti manuali.

## Stato post release

Core Engine: stabile  
Break Engine: stabile  
Basket Straordinari: stabile  
Basket RFI: stabile  
Compensativi: stabile  
Cedolino predittivo: stabile  

## Fase successiva

Monitoraggio post release tramite analytics e feedback utenti.
