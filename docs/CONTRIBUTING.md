# DutyPay Contributing Guidelines

## Obiettivo

Definire le regole operative per contribuire a DutyPay senza introdurre regressioni.

DutyPay è un prodotto production-grade: ogni modifica deve preservare precisione, affidabilità e coerenza.

---

## Documenti guida

Prima di modificare il progetto leggere:

- README.md
- VISION.md
- ROADMAP.md
- DESIGN_SYSTEM.md
- ARCHITECTURE.md

Ogni nuova modifica deve essere coerente con questi documenti.

---

## Gerarchia del progetto

Ogni decisione deve rispettare questo ordine:

1. Precisione
2. Affidabilità
3. Esperienza utente
4. Brand Identity
5. Community
6. Innovazione

La precisione del motore economico viene sempre prima.

---

## Regole architetturali

È vietato:

- inserire logica economica nella UI
- duplicare logiche di calcolo
- creare fallback legacy non controllati
- modificare preview con calcoli paralleli
- usare monthlySummaries per RFI
- modificare il motore senza test
- introdurre feature che aggirano i UseCase esistenti

---

## Flusso corretto

Per ogni modifica:

1. Capire il livello interessato:
   - Presentation
   - Application
   - Domain
   - Infrastructure

2. Fare una modifica piccola e isolata.

3. Eseguire i test.

4. Verificare lo stato Git.

5. Committare con messaggio chiaro.

---

## Test minimi obbligatori

Prima di ogni commit rilevante:

```bash
flutter test