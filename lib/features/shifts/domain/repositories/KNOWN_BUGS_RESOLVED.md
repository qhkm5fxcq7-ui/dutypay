# BUG RISOLTI – DUTYPAY

## Polfer falso straordinario
Causa:
- uso soglia 6h

Soluzione:
- uso fine turno teorica

---

## Scalo spariva dopo salvataggio
Causa:
- pipeline sporca

Soluzione:
- separazione engine / serialization

---

## Basket RFI a zero
Causa:
- uso monthlySummaries

Soluzione:
- uso rfiMonthlySummaries

---

## Breakdown Polfer incoerente
Causa:
- merge con logica legacy

Soluzione:
- breakdown solo da engine
# DutyPay — Known Bugs Resolved

---

## BUG RM — perdita notturno con straordinario

### Descrizione

Nel Reparto Mobile:
- la quota notturna veniva alterata in presenza di straordinario
- in alcuni casi veniva ridotta o persa

---

### Causa

Errore nella policy:

```text
ordinaryNight = nightOrdinaryHours - overtimeNightHours
## Benefit sommati erroneamente al totale

Bug risolti:
- duplicazione del comfort
- ticket assente nel post-salvataggio
- benefit sommati erroneamente a totalAmount
- benefit sommati erroneamente a extraAmount

Categorie coinvolte:
- ticket_meal
- comfort
- comfort_cdg

Soluzione:
- normalizzazione benefit non economici con:
  - amount = 0.0
  - benefitAmount valorizzato
  - isBenefit = true

Esito:
- preview e post-salvataggio allineati
- benefit visibili ma non cumulati
- duplicazione genere di conforto
- ticket pasto non presente nel post-salvataggio
- benefit conteggiati erroneamente nel totale
- parser leggeva il blocco accessorie del riepilogo invece del dettaglio
- accessorie non estratte dai PDF reali
- derivazione rate straordinario errata per parsing incompleto
## Ultimi fix critici

- Preview calcolo non coerente → RISOLTO
- RFI mostrato con ore → RISOLTO (solo €)
- Reset turno su selezione assenza → RISOLTO
- Differenze preview vs salvataggio → RISOLTO