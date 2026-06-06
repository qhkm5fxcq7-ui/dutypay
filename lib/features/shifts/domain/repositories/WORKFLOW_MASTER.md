# DUTYPAY – WORKFLOW MASTER

## Obiettivo
Coordinare lo sviluppo di DutyPay su più chat senza perdere contesto, introdurre regressioni o duplicare lavoro.

DutyPay è un'app Flutter per il personale delle Forze dell'Ordine.

Baseline attuale:
**Release 1.0.5 – Multi Department Engine**

Reparti supportati:
- Reparto Mobile
- Polfer
- Questura Uffici
- Questura Volanti

---

## Fonte di verità

Ordine di priorità:

1. SYSTEM_HANDOFF.md
2. CALCULATION_RULES.md
3. ARCHITECTURE.md
4. CHAT_HANDOFF.md
5. codice esistente

Nota:
Il codice esistente è fonte di verità solo se coerente con il motore centrale.
Qualsiasi logica duplicata o legacy in UI non deve prevalere sul motore.

---

## Source of truth tecnica

La fonte di verità assoluta dei calcoli turno è:

**BuildDailyShiftResultUseCase**

Responsabile di:
- ore lavorate
- ore ordinarie
- straordinario automatico
- straordinario programmato
- notturno
- festivo
- OP
- servizi esterni
- basket
- compensativi
- accessorie
- breakdown
- totale turno
- totale giorno

Ogni nuovo reparto, nuova indennità o nuova regola deve passare dal motore centrale.

È vietato duplicare logiche economiche nei widget.

---

## Regole di lavoro

- Ogni chat lavora su un solo blocco tecnico principale.
- Nessuna chat deve modificare logiche fuori dal proprio blocco senza riportarlo nell’handoff.
- Qualsiasi modifica strutturale deve essere prima allineata con il cervello del sistema.
- Le logiche legacy non devono essere reintrodotte.
- QuickAddShiftPage deve essere solo una preview del motore.
- Preview, card turno, dettaglio turno, totale giorno e summary mese devono leggere risultati coerenti.
- RM, Polfer e Questura non devono contaminarsi.
- RFI è un flusso separato.
- I basket compensativi non devono essere confusi con basket RFI o accessorie ordinarie.
- Ogni bug deve essere riprodotto, documentato, corretto e ritestato.

---

## Chat attive consigliate

### Chat cervello
Responsabilità:
- architettura
- regole
- vincoli
- handoff globale
- controllo coerenza
- roadmap release successive

### Chat motore turni
Responsabilità:
- Shift / policy / result
- calcoli reparto
- overtime
- breakdown
- basket tecnici
- source of truth `BuildDailyShiftResultUseCase`

### Chat cedolino
Responsabilità:
- projection service
- payslip result
- summary mensili
- stime cedolino
- accessorie ritardate
- netto stimato

### Chat UI
Responsabilità:
- schermate Flutter
- cards
- calendario
- riepiloghi
- preview
- allineamento visuale con il motore

### Chat test
Responsabilità:
- test unitari
- test regressione
- controllo pre-release
- smoke test multi-reparto
- checklist store release

---

## Procedura obbligatoria per ogni modifica

1. Leggere i file docs principali.
2. Identificare il blocco tecnico corretto.
3. Verificare la source of truth.
4. Fare la modifica minima necessaria.
5. Lanciare i test pertinenti.
6. Aggiornare l’handoff del blocco.
7. Se la modifica impatta la logica generale, aggiornare anche il cervello del sistema.
8. Prima della release eseguire:
   - `flutter analyze`
   - `flutter test`
   - smoke test manuale dei reparti principali

---

## Cose da non rompere

### Reparto Mobile
- Soglia ordinaria 6h.
- Secondo turno nella stessa giornata deve diventare straordinario se le 6h sono già state consumate.
- OP in sede, fuori sede e pernotto devono sommarsi correttamente.
- Il totale giorno deve includere straordinario + OP + accessorie.
- Le soglie Polfer/Volanti 13:08, 19:08, 00:08, 07:08 non devono contaminare RM.

### Polfer
- Turni standard non devono produrre falso straordinario.
- Notturno Polfer dalle 22:00.
- Controllo territorio serale e notturno devono restare separati.
- Basket RFI separato dalle accessorie ordinarie.
- Scalo/RFI non deve contaminare overtime ordinario.

### Questura Uffici
- Supporto orario ordinario personalizzato.
- Override 6h.
- Override 7h12.
- Override qualsiasi valore.
- Straordinario solo oltre l’ordinario configurato.

### Questura Volanti
- Preset attivi:
  - Mattina
  - Pomeriggio
  - Sera
  - Notte
- Straordinario automatico solo dopo fine preset.
- Notturno ordinario calcolato correttamente.
- Servizio esterno sommato correttamente.
- Straordinario programmato sempre conteggiato come overtime.

### UI / Summary
- Coerenza preview ↔ salvataggio.
- Coerenza card ↔ dettaglio.
- Coerenza breakdown ↔ totale.
- Coerenza totale giorno ↔ totale settimana ↔ media giornaliera ↔ netto stimato.
- Nessun calcolo parallelo nei widget.

---

## Workflow RFI

1. Inserimento turno con scalo.
2. Generazione automatica `rfiBasketGross`.
3. Inserimento diretto nel basket RFI con stato OPEN.
4. Visualizzazione in UI come totale generato.
5. Pagamento manuale utente.
6. Spostamento in PAID.
7. Inclusione nel cedolino solo nel mese di pagamento.

RFI resta separato da:
- straordinario ordinario
- accessorie ordinarie
- basket compensativo

---

## Release baseline 1.0.5

Stato:
- Android 1.0.5 build 18 inviata a Google Play.
- iOS 1.0.5 build 18 inviata ad Apple.
- Test automatici: 78/78 PASS.
- `flutter analyze`: 0 errori bloccanti.

Implementato:
- Questura Uffici.
- Questura Volanti.
- Preset Volanti.
- Straordinario automatico post preset.
- Straordinario programmato personalizzato.
- Orario ordinario personalizzato.
- Fix preview Quick Add.
- Fix totale turno.
- Fix totale giorno.
- Fix totale settimana.
- Fix media giornaliera.
- Fix netto stimato.
- Allineamento dashboard a `BuildDailyShiftResultUseCase`.

Bug noto non bloccante:
- Export dati su macOS desktop genera errore `Bytes are not supported on macOS`.
- Da correggere in 1.0.6.
- Nessun impatto sugli utenti Android/iOS.

---

## Roadmap post 1.0.5

Priorità suggerite:
1. Fix export macOS.
2. Export/import multi reparto.
3. Turnario annuale.
4. Missioni evolute.
5. Feedback utenti in-app.
6. Cedolino Pro / premium layer.
7. Ulteriori reparti solo dopo stabilizzazione della 1.0.5.