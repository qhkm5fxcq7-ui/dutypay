# DutyPay — Calculation Rules

## Obiettivo
Questo documento descrive le regole di calcolo attualmente considerate corrette e consolidate per i reparti già supportati in DutyPay.

Non contiene proposte di refactor.
Non contiene teoria generica.
Serve come fonte di verità per sviluppo, test e debugging.

---

## 1. Regole comuni

### 1.1 Ore lavorate
- Le ore lavorate sono calcolate come differenza tra `start` ed `end`.
- Se `end` è precedente o uguale a `start`, il turno attraversa la mezzanotte e `end` va normalizzato al giorno successivo.
- Il turno può quindi estendersi su due date diverse.
- `workedHoursOverride`, se presente e previsto dal flusso, ha priorità sul calcolo puro da differenza oraria.

### 1.2 Fasce orarie
- Fascia diurna: `06:00 – 22:00`
- Fascia notturna: `22:00 – 06:00`

### 1.3 Festivi
- La domenica è trattata come festivo.
- Le festività particolari/superfestive sono gestite separatamente.
- Il tratto successivo alla mezzanotte diventa festivo solo se il nuovo giorno è effettivamente festivo o domenica.

### 1.4 Assenze
- Le assenze non producono importi.
- Le assenze devono restare visibili nel calendario e nelle etichette.
- In caso di assenza:
  - totale = 0
  - breakdown economico = vuoto
  - straordinario = 0

### 1.5 Breakdown
- Il breakdown deve essere coerente con il totale.
- Preview e turno salvato devono restituire risultati coerenti.
- Le voci non devono sparire dopo il salvataggio.
- Le voci non devono comparire duplicate.

### 1.6 Ticket e welfare
- Ticket pasto, genere di conforto e genere di conforto CDG restano tracciati nel turno e nella UI.
- Il ticket pasto non deve entrare nel flusso del cedolino stimato.
- Comfort e CDG devono restare separati.

---

## 2. Reparto Mobile

## 2.1 Regola base straordinario
- La soglia ordinaria giornaliera del Reparto Mobile è `6 ore`.
- Tutto ciò che eccede le 6 ore viene trattato come straordinario.

## 2.2 Segmentazione straordinario
Lo straordinario RM viene segmentato in:
- straordinario diurno
- straordinario notturno
- straordinario festivo diurno
- straordinario notturno festivo

## 2.3 Fascia notturna RM
- La fascia notturna è `22:00 – 06:00`.
- L’attraversamento della mezzanotte deve essere riconosciuto correttamente.

## 2.4 Passaggio al festivo
- Se il turno prosegue oltre mezzanotte verso una domenica o un festivo, il tratto successivo alla mezzanotte deve essere classificato come festivo.
- Esempio: un tratto `00:00 – 02:00` diventa notturno festivo solo se il nuovo giorno è realmente domenica o festivo.

## 2.5 Indennità RM
Le voci RM considerate consolidate sono:
- Ordine pubblico:
  - In sede
  - Fuori sede
  - Pernotto
- Indennità presenza servizi esterni
- Indennità servizio festivo
- Festività particolare
- Genere di conforto
- Genere di conforto CDG
- Ticket pasto nella UI, ma non nel cedolino stimato

## 2.6 Multi-turno
- Il multi-turno nello stesso giorno è stato validato come area critica.
- Deve restare coerente tra preview, salvataggio e riepilogo.

## 2.7 Caso standard RM
- Un turno RM standard `06:55 → 13:08` genera circa `0.2h` di straordinario diurno, perché la soglia corretta RM resta 6 ore.

---

## 3. Polfer

## 3.1 Regola base straordinario
Per Polfer, la soglia di straordinario non è la sesta ora fissa.

Lo straordinario parte dopo la chiusura teorica del turno standard.

Riferimenti consolidati:
- mattina → `13:08`
- pomeriggio → `19:08`
- sera → `00:08`
- notte → `07:08`

## 3.2 Effetto pratico
- Un turno Polfer `06:55 → 13:08` standard non deve generare straordinario.
- Un turno Polfer `12:55 → 19:08` standard non deve generare straordinario.
- Il falso `0.2h` su turni standard Polfer è stato riconosciuto come bug, non come comportamento corretto.

## 3.3 Fascia notturna Polfer
- La fascia notturna considerata valida è `22:00 – 06:00`.
- In questa fase non è consolidata una regola diversa che escluda il tratto `22:00 – 24:00`.

## 3.4 Indennità Polfer consolidate
Le voci Polfer considerate consolidate sono:
- Controllo del territorio serale
- Controllo del territorio notturno
- Scalo ferroviario ridotto
- Scalo ferroviario intero
- Scalo ferroviario misto manuale
- Indennità servizio notturno
- Indennità presenza servizi esterni
- Eventuali altre voci comuni già previste dal motore

## 3.5 Scalo ferroviario / basket RFI
Questa è una regola funzionale consolidata:
- lo scalo deve essere calcolato
- lo scalo deve restare visibile e tracciabile nel turno
- lo scalo deve confluire nel basket RFI
- lo scalo non deve confluire nelle accessorie ordinarie
- lo scalo non deve confluire nello stipendio / cedolino stimato

## 3.6 Breakdown Polfer
- Il breakdown in preview e quello post-salvataggio devono restare coerenti.
- Lo scalo non deve sparire dopo il salvataggio.
- Il basket RFI non può essere trattato come semplice testo senza metadata utili al flusso di aggregazione.

## 3.7 Turni standard Polfer già consolidati
- Mattina standard → zero straordinario
- Pomeriggio standard → zero straordinario
- Sera standard → zero straordinario, resta l’eventuale quota notturna ordinaria
- Notte standard → zero straordinario, resta l’eventuale quota notturna ordinaria

---

## 4. Casi canonici consolidati — Reparto Mobile

## RM-01
Descrizione:
- Turno OP fuori sede non festivo che attraversa la mezzanotte

Input:
- start: 11/04/2026 15:00
- end: 12/04/2026 02:00
- orderPublic: Fuori sede

Output atteso:
- workedHours: 11.0
- ordinaryHours: 6.0
- overtimeHours: 5.0
- overtimeDayHours: 1.0
- overtimeNightHours: 4.0
- overtimeHolidayDayHours: 0.0
- overtimeNightHolidayHours: 0.0

Breakdown atteso:
- Ordine pubblico Fuori sede
- Straordinario diurno 1.0h
- Straordinario notturno 4.0h

## RM-02
Descrizione:
- Turno OP fuori sede che attraversa la mezzanotte verso domenica/festivo

Input:
- start: 11/04/2026 15:00
- end: 12/04/2026 02:00
- il nuovo giorno è domenica/festivo

Output atteso:
- workedHours: 11.0
- ordinaryHours: 6.0
- overtimeHours: 5.0
- overtimeDayHours: 1.0
- overtimeNightHours: 2.0
- overtimeNightHolidayHours: 2.0

Breakdown atteso:
- Ordine pubblico Fuori sede
- Straordinario diurno 1.0h
- Straordinario notturno 2.0h
- Straordinario notturno festivo 2.0h

## RM-03
Descrizione:
- Turno lungo con mezz’ora iniziale notturna, non festivo

Input:
- start: 02/04/2026 05:30
- end: 02/04/2026 18:30
- orderPublic: Fuori sede

Output atteso:
- workedHours: 13.0
- ordinaryHours: 6.0
- overtimeHours: 7.0
- overtimeDayHours: 7.0
- overtimeNightHours: 0.0
- nightOrdinaryHours: 0.5

Breakdown atteso:
- Straordinario diurno 7.0h
- Indennità servizio notturno 0.5h
- Ordine pubblico Fuori sede

## RM-04
Descrizione:
- Turno standard mattina RM

Input:
- start: 01/04/2026 06:55
- end: 01/04/2026 13:08

Output atteso:
- workedHours: circa 6.2
- ordinaryHours: 6.0
- overtimeHours: circa 0.2
- overtimeDayHours: circa 0.2

Breakdown atteso:
- Straordinario diurno circa 0.2h

## RM-05
Descrizione:
- Giorno di assenza

Output atteso:
- workedHours: 0.0
- ordinaryHours: 0.0
- overtimeHours: 0.0
- breakdown: vuoto
- totale: 0.0

---

## 5. Casi canonici consolidati — Polfer

## POLFER-01
Descrizione:
- Turno mattina standard Polfer

Input:
- start: 01/04/2026 06:55
- end: 01/04/2026 13:08

Output atteso:
- workedHours: circa 6.2
- ordinaryHours: circa 6.2
- overtimeHours: 0.0
- breakdown: nessuna voce economica standard, salvo flag aggiuntivi

## POLFER-02
Descrizione:
- Turno pomeriggio standard Polfer

Input:
- start: 01/04/2026 12:55
- end: 01/04/2026 19:08

Output atteso:
- workedHours: circa 6.2
- ordinaryHours: circa 6.2
- overtimeHours: 0.0
- breakdown: nessuna voce economica standard, salvo flag aggiuntivi

## POLFER-03
Descrizione:
- Turno sera standard Polfer

Output atteso:
- overtimeHours: 0.0
- breakdown atteso:
  - sola eventuale indennità servizio notturno ordinario
- riferimento emerso:
  - circa 2.1h notturne ordinarie
  - importo visto: € 9.17

## POLFER-04
Descrizione:
- Turno notte standard Polfer

Output atteso:
- overtimeHours: 0.0
- breakdown atteso:
  - sola eventuale indennità servizio notturno ordinario
- riferimento emerso:
  - circa 6.1h notturne ordinarie
  - importo visto: € 26.16

## POLFER-05
Descrizione:
- Turno con controllo territorio serale, servizi esterni e scalo ferroviario ridotto

Output atteso:
- breakdown atteso:
  - Controllo del territorio serale = € 5.00
  - Scalo ferroviario ridotto (basket RFI) = € 5.61
  - Straordinario diurno = € 23.89
  - Indennità servizio notturno = € 26.16
  - Indennità presenza servizi esterni = € 6.00
- totale preview atteso: € 65.27
- extraAmount atteso al netto del basket RFI: € 59.66
- basket RFI atteso: € 5.61

---

## 6. Punti delicati da non rompere

- coerenza preview ↔ salvataggio
- breakdown economico coerente
- multi-turno stesso giorno
- ticket fuori dal cedolino
- comfort e CDG separati
- Reparto Mobile con soglia fissa a 6 ore
- Polfer non riportata alla logica 6 ore fisse sui turni standard
- scalo RFI presente, tracciato e separato dal cedolino
- nessuna perdita di metadata utili per il basket RFI

---

## 7. Differenze consolidate tra logica legacy e logica corretta

### Polfer
Legacy errata:
- soglia straordinario fissa a 6 ore

Logica corretta:
- straordinario dopo la chiusura teorica del turno standard

### Basket RFI
Legacy errata:
- voce trattata solo come riga testuale e persa nell’aggregazione

Logica corretta:
- voce strutturata, tracciabile e separata nel flusso basket RFI
# REGOLE DI CALCOLO – DUTYPAY

## REPARTO MOBILE

- soglia ordinaria: 6 ore
- oltre → straordinario

### Fasce
- Notturno: 22:00 – 06:00
- Diurno: resto

### Segmentazione
- diurno
- notturno
- festivo
- notturno festivo

### Regole
- attraversamento mezzanotte valido
- dopo mezzanotte → verifica festivo reale
- multi-turno supportato

---

## POLFER

### Straordinario
NON basato su 6 ore

Basato su fine turno teorica:
- mattina → 13:08
- pomeriggio → 19:08
- sera → 00:08
- notte → 07:08

### Fasce
- Notturno: 22:00 – 06:00

---

## INDENNITÀ

### Comuni
- ordine pubblico
- servizi esterni
- festivo
- festività particolare
- genere di conforto
- ticket pasto (NON nel cedolino)

### Polfer specifiche
- controllo territorio
- scalo ferroviario

---

## BASKET

### RFI
- lo scalo va qui
- NON entra nel totale stipendio
- deve restare tracciabile
## REGOLA CRITICA – TURNO POLFER

Un turno Polfer può legittimamente produrre:

- totale = 0
- straordinario = 0

Questo NON è un bug.

È corretto perché il turno è coperto da stipendio base.
# DutyPay — Calculation Rules

## Reparto Mobile (RM)

### Regole base

- Soglia straordinario: **6 ore**
- Fascia notturna: **22:00 → 06:00**
- Il notturno è **indipendente dallo straordinario**

---

## Modello corretto (fondamentale)

Il turno viene sempre scomposto in 4 dimensioni:

- ordinaryDayHours
- ordinaryNightHours
- overtimeDayHours
- overtimeNightHours

(+ varianti festive)

---

## Principio chiave

> Il notturno NON dipende dallo straordinario

Significa:
- può esistere notturno senza straordinario
- può esistere notturno ordinario e straordinario nello stesso turno
- non devono mai sovrascriversi

---

## Segmentazione

1. Si calcolano le ore lavorate totali
2. Le prime 6h → ordinario
3. Le successive → straordinario
4. Ogni blocco viene classificato:
   - giorno / notte
   - festivo / non festivo

---

## Casi ufficiali

### Caso 1 — 17:00 → 23:00

- workedHours = 6
- overtimeHours = 0
- ordinaryNightHours = 1
- overtimeNightHours = 0

✔ NOTA:
- esiste notturno senza straordinario

---

### Caso 2 — 17:00 → 01:00 (non festivo)

- workedHours = 8
- overtimeHours = 2

Segmentazione:
- 22:00 → 23:00 = ordinary night
- 23:00 → 01:00 = overtime night

✔ Risultato:
- ordinaryNightHours = 1
- overtimeNightHours = 2

---

### Caso 3 — attraversamento festivo

Esempio:
17:00 → 01:00 con mezzanotte domenica

Segmentazione:
- 23:00 → 00:00 = overtime night
- 00:00 → 01:00 = overtime night holiday

✔ Risultato:
- overtimeNightHours = 1
- overtimeNightHolidayHours = 1

---

## Breakdown (obbligatorio)

Ogni voce deve avere:

- category
- amount
- hours

Categorie valide:
- overtime_day
- overtime_night
- overtime_holiday_day
- overtime_night_holiday
- ordinary_night

---

## Regole critiche

❌ NON fare:
- sottrarre overtimeNight da nightOrdinary
- usare fallback legacy
- spostare logica in UI

✅ SEMPRE:
- calcolo in engine
- UI legge soltanto
## Benefit non economici

Le seguenti voci sono benefit visibili ma non economici:
- ticket_meal
- comfort
- comfort_cdg

Regole:
- visibili nel breakdown
- NON entrano nel totale turno
- NON entrano negli extra
- NON entrano nel cedolino
- NON entrano nei flussi economici accessori

Struttura obbligatoria:
- amount = 0.0
- benefitAmount valorizzato
- isBenefit = true
## Benefit non economici

Le seguenti voci sono trattate come benefit:

- Ticket pasto
- Genere di conforto
- Genere di conforto CDG

Regole:
- Sono visibili nel breakdown turno
- NON contribuiscono al totalAmount
- NON contribuiscono agli extra
- NON entrano nel cedolino previsto
- Sono rappresentate come:
  - amount = 0.0
  - benefitAmount > 0
  - isBenefit = true
  ## Regola fondamentale pipeline cedolino

Tutte le accessorie economiche sono trattate in LORDO.

Pipeline:

1. Calcolo breakdown turno (valori economici lordi)
2. Aggregazione mensile accessorie
3. Esclusione benefit non economici
4. Esclusione RFI ordinario
5. Somma totale accessorie lorde
6. Applicazione logica fiscale (tax rate stimato)
7. Output netto previsto

Nota:
- Nessun valore netto deve entrare prima dello step 6
## RFI Basket – Logica definitiva

Lo scalo ferroviario (RFI) è gestito come flusso separato dalle accessorie standard.

### Regole:
- NON entra nelle accessorie del cedolino
- NON è soggetto a delay mesi
- NON è soggetto a limiti straordinario
- Viene accumulato immediatamente nel basket

### Flusso:
Turno con scalo →
→ genera rfiBasketGross →
→ entra direttamente in openRfiBasketEntries

### Stato:
- OPEN → non ancora pagato
- PAID → registrato tramite RfiBasketPayment

### Cedolino:
Il valore RFI viene aggiunto SOLO se pagato nel mese:

rfiNet = rfiPaidThisMonthGross * (1 - accessoryTaxRate)

totalNetWithRfi = estimatedPayslipTotal + rfiNet
## Programmed Overtime — Segmented Rule

Programmed overtime is handled as a single explicit time segment.

Fields:
- `programmedOvertimeEnabled`
- `programmedOvertimeStart`
- `programmedOvertimeEnd`
- `programmedOvertimeNote`
- `overtimeDestination`

Rules:
1. If programmed overtime is disabled, normal overtime logic applies.
2. If enabled and start/end are valid, DutyPay calculates the overlap between:
   - the shift range
   - the programmed overtime range
3. Only the overlapping segment is treated as programmed overtime.
4. The programmed segment is excluded from ordinary-hour absorption.
5. The programmed segment is added as certain overtime.
6. If the segment exceeds the shift range, it is clamped safely.
7. If `overtimeDestination == payment`, the programmed overtime remains payable.
8. If `overtimeDestination == compensative`, the programmed overtime:
   - remains in total overtime hours
   - enters compensative hours
   - is excluded from paid total amount
   - must not enter payslip payment
   - must not enter RFI basket
   - must not enter payment basket

Validated examples:
- Shift 07:00–16:00, programmed 13:00–16:00 = 3h programmed overtime.
- Shift 07:00–16:00, programmed 13:00–16:00, compensative = 3h compensative, no paid overtime amount.
- Shift 07:00–13:00, programmed 12:00–18:00 = 1h programmed overtime after clamp.

## 3. `CALCULATION_RULES.md`

Aggiungi:

```md
## Compensative Basket Rules

The Compensative Basket tracks hours only.

### Earned hours

Earned compensative hours derive from compensative overtime.

Primary source:
- `DailyShiftResult.compensativeHours`

Runtime movement:
- `CompensativeBasketMovementType.earned`

### Recovered hours

Recovered hours derive from absence:

```text
Recupero compensativo
