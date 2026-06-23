# DUTYPAY — CALCULATION RULES

## Obiettivo

Questo documento descrive le regole di calcolo ufficiali e consolidate di DutyPay.

È la fonte di verità per:

- sviluppo
- debugging
- test
- validazione utenti

Non contiene:

- roadmap
- refactor proposti
- codice temporaneo

---

# Source of Truth

Tutti i calcoli economici devono derivare da:

BuildDailyShiftResultUseCase

Responsabile di:

- overtime
- notturno
- festivo
- OP
- servizi esterni
- compensativi
- basket
- breakdown
- totale turno
- totale giorno

Regola:

Preview, dettaglio turno, totale giorno e summary mese devono derivare dalla stessa computation.

---

# Regole Comuni

## Ore lavorate

Le ore lavorate sono:

end - start

Se:

end <= start

il turno attraversa la mezzanotte.

Il turno viene normalizzato al giorno successivo.

---

## Fasce

### Diurno

06:00 → 22:00

### Notturno

22:00 → 06:00

---

## Festivi

Sono festivi:

- domenica
- festività nazionali
- festività particolari

Dopo mezzanotte:

- viene verificato il nuovo giorno
- la classificazione può cambiare

---

## Assenze

Le assenze:

- restano visibili
- non generano importi

Output:

- totale = 0
- overtime = 0
- breakdown = []

---

# Benefit Non Economici

Categorie:

- ticket_meal
- comfort
- comfort_cdg

Regole:

- visibili nella UI
- visibili nel breakdown
- NON entrano nel totale
- NON entrano negli extra
- NON entrano nel cedolino

Struttura:

- amount = 0.0
- benefitAmount > 0
- isBenefit = true

---

# Reparto Mobile

## Regola Base

Soglia ordinaria:

6 ore

Tutto ciò che eccede:

overtime

---

## Segmentazione

Supportata:

- overtime day
- overtime night
- overtime holiday day
- overtime night holiday

---

## Notturno

Fascia:

22:00 → 06:00

Il notturno è indipendente dallo straordinario.

Possono coesistere:

- ordinaryNightHours
- overtimeNightHours

---

## Principio Fondamentale

NON fare:

ordinaryNightHours - overtimeNightHours

Le due grandezze sono indipendenti.

---

## Multi-Turno

Supportato.

Più turni nello stesso giorno devono:

- rispettare la soglia ordinaria
- restare coerenti tra preview e salvataggio

---

## Indennità RM

Supportate:

- OP In sede
- OP Fuori sede
- OP Pernotto
- Servizi esterni
- Festivo
- Festività particolare

---

# Polfer

## Regola Straordinario

Polfer NON utilizza la soglia 6h.

Lo straordinario parte dopo la chiusura teorica.

Riferimenti:

- Mattina → 13:08
- Pomeriggio → 19:08
- Sera → 00:08
- Notte → 07:08

---

## Turni Standard

Devono generare:

- overtime = 0

Esempi:

- 06:55 → 13:08
- 12:55 → 19:08
- 18:55 → 00:08
- 00:55 → 07:08

---

## Notturno

Fascia:

22:00 → 06:00

---

## Indennità Polfer

Supportate:

- Controllo territorio serale
- Controllo territorio notturno
- Scalo ferroviario ridotto
- Scalo ferroviario intero
- Scalo ferroviario misto
- Notturno ordinario
- Servizi esterni

---

# Basket RFI

Pipeline separata.

Lo scalo ferroviario:

- NON entra nelle accessorie
- NON entra nel cedolino
- NON entra negli straordinari

Flusso:

Turno
↓
rfiBasketGross
↓
OPEN
↓
PAID
↓
Cedolino

---

## Regola Cedolino RFI

Solo il pagato entra nel cedolino.

Formula:

rfiNet = rfiPaidThisMonthGross * (1 - accessoryTaxRate)

---

# Questura Uffici

## Ordinario Configurabile

Valori supportati:

- 6h
- 7h12
- custom

---

## Straordinario

Formula:

overtime = workedHours - ordinaryConfiguredHours

Se negativo:

0

---

## Validato

- 6h
- 7h12
- custom

---

# Questura Volanti

## Preset Supportati

- Mattina
- Pomeriggio
- Sera
- Notte

---

## Regola

Le ore fino alla fine del preset sono:

ordinarie

Le ore successive sono:

overtime

---

## Straordinario Programmato

Supportato.

---

# Programmed Overtime

Gestito come segmento temporale.

Campi:

- programmedOvertimeEnabled
- programmedOvertimeStart
- programmedOvertimeEnd
- overtimeDestination

---

## Regole

1. viene calcolata l'intersezione col turno
2. il segmento viene clamped
3. il segmento diventa overtime certo

---

## Destinazione Pagamento

Il segmento entra nel totale economico.

---

## Destinazione Compensativo

Il segmento:

- entra nelle compensative
- NON entra nel totale economico
- NON entra nel cedolino
- NON entra nel basket RFI

---

# Compensative Basket Rules

Il basket compensativo gestisce esclusivamente ore.

Non è:

- denaro
- accessoria
- RFI

---

## Earned

Origine:

DailyShiftResult.compensativeHours

Movimento:

earned

---

## Recovered

Origine:

assenza = Recupero compensativo

Movimento:

recovered

---

## Adjustment

Consentiti:

- positivi
- negativi

Richiedono:

- nota obbligatoria

---

## Formula Residuo

residual =
earned
- recovered
+ adjustments

---

## Regole di Protezione

Movimenti automatici:

- earned
- recovered

non possono essere:

- modificati
- eliminati

Solo:

- adjustment

è modificabile.

---

# Pipeline Cedolino

Tutte le accessorie sono gestite in LORDO.

Pipeline:

1. Breakdown turno
2. Aggregazione mensile
3. Esclusione benefit
4. Esclusione RFI
5. Totale accessorie lorde
6. Applicazione fiscalità stimata
7. Netto previsto

Regola:

Nessun valore netto deve entrare prima dello step 6.

---

# Punti Critici da Non Rompere

- Preview ↔ Salvataggio
- Breakdown ↔ Totale
- Totale giorno ↔ Summary mese
- RM soglia 6h
- Polfer scheduled end
- Basket RFI separato
- Basket compensativo separato
- Benefit fuori dai flussi economici
- Straordinario programmato compensativo non pagato
- Nessuna logica economica nei widget

---

# Baseline Validata

Release:

DutyPay 1.0.5

Reparti:

- Reparto Mobile
- Polfer
- Questura Uffici
- Questura Volanti

Stato:

VALIDATO
# POLSTRADA

## Preset

Mattina
06:55 → 13:08

Pomeriggio
12:55 → 19:08

Sera
18:55 → 01:08

Notte
00:55 → 07:08

## Straordinario

Mattina:
oltre 13:08

Pomeriggio:
oltre 19:08

Sera:
oltre 01:08

Notte:
oltre 07:08

## Supportato

- servizio esterno
- ticket
- compensativo
- programmed overtime
- basket straordinari
- basket compensativo

## Indennità autostradale

Architettura predisposta.

Importi non ancora attivati.

Release sospesa fino al reperimento dei valori ufficiali.
## Indennità autostradale

Mattina:
€ 9,50

Pomeriggio:
€ 9,50

Sera:
€ 12,00

Notte:
€ 14,50

Categoria breakdown:

autostrada_service
