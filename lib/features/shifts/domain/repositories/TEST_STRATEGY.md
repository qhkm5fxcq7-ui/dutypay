## Parser Testing Strategy

I test parser devono usare:

- fixture reali (PDF o raw text reale)
- non solo dati sintetici

Motivazione:
I cedolini NoiPA presentano:
- duplicazione blocchi
- layout non lineare
- variazioni di formattazione

I test sintetici NON sono sufficienti per garantire affidabilità.
## Test RFI obbligatori

- Inserimento scalo → deve entrare nel basket
- Nessun impatto su accessorie
- Pagamento manuale → sposta da OPEN a PAID
- Cedolino → include solo se pagato nel mese
- Preview = turno salvato (sempre)
## Nuova copertura test — parser cedolini con fixture reali

È stato aggiunto e validato un test dedicato su fixture reali per blindare il parsing delle accessorie da cedolino.

### File test
`test/unit/parser/payslip_parser_service_test.dart`

### Copertura introdotta
Sono stati coperti i seguenti casi reali:
- RM Marzo 2026
- RM Febbraio 2026
- Polfer Marzo 2026

### Verifiche effettuate
Per ogni fixture vengono verificati:
- parsing corretto del riepilogo cedolino
- estrazione corretta delle `accessoryEntries`
- estrazione corretta delle `operationalAccessoryEntries`
- derivazione corretta delle tariffe di straordinario nel profilo dinamico

### Esito
I test passano correttamente.

### Impatto
Questo test impedisce regressioni future sul parser cedolini, che rappresenta una componente critica per:
- stima cedolino
- calcolo accessorie reali
- costruzione del profilo dinamico utente

## 4. `TEST_STRATEGY.md`

Aggiungi:

```md
## Programmed Overtime Segment Tests

Test file:
- `test/unit/usecases/programmed_overtime_segment_test.dart`

Covered cases:
1. Ordinary + programmed overtime:
   - shift 07:00–16:00
   - programmed 13:00–16:00
   - expected overtime: 3h

2. Programmed compensative overtime:
   - shift 07:00–16:00
   - programmed 13:00–16:00
   - destination compensative
   - expected total overtime: 3h
   - expected compensative hours: 3h
   - expected paid amount: 0 for programmed overtime

3. Out-of-range programmed segment:
   - shift 07:00–13:00
   - programmed 12:00–18:00
   - expected overtime after clamp: 1h

Regression requirements:
- RM daily overtime must remain stable.
- Polfer preset closure must remain stable.
- Questura/Volanti preset logic must not lose operational identity.
- Compensative overtime must not enter payslip paid amount.
- RFI basket must remain separate.
