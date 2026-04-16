# DUTYPAY – WORKFLOW MASTER

## Obiettivo
Coordinare lo sviluppo di DutyPay su più chat senza perdere contesto, introdurre regressioni o duplicare lavoro.

---

## Fonte di verità
Ordine di priorità:

1. SYSTEM_HANDOFF.md
2. CALCULATION_RULES.md
3. ARCHITECTURE.md
4. CHAT_HANDOFF.md
5. codice esistente

---

## Regole di lavoro
- Ogni chat lavora su un solo blocco tecnico principale.
- Nessuna chat deve modificare logiche fuori dal proprio blocco senza riportarlo nell’handoff.
- Qualsiasi modifica strutturale deve essere prima allineata con il cervello del sistema.
- Le logiche legacy non devono essere reintrodotte.
- RM e Polfer non devono contaminarsi.
- RFI è un flusso separato.

---

## Chat attive consigliate

### Chat cervello
Responsabilità:
- architettura
- regole
- vincoli
- handoff globale
- controllo coerenza

### Chat motore turni
Responsabilità:
- Shift / policy / result
- calcoli reparto
- overtime
- breakdown
- basket tecnici

### Chat cedolino
Responsabilità:
- projection service
- payslip result
- summary mensili
- stime cedolino

### Chat UI
Responsabilità:
- schermate Flutter
- cards
- calendario
- riepiloghi

### Chat test
Responsabilità:
- test unitari
- test regressione
- controllo pre-release

---

## Procedura obbligatoria per ogni modifica
1. leggere i file docs principali
2. identificare il blocco tecnico corretto
3. fare la modifica
4. aggiornare l’handoff del blocco
5. se la modifica impatta la logica generale, aggiornare anche il cervello del sistema

---

## Cose da non rompere
- RM con soglia 6h
- Polfer con turni standard non forzati a produrre importo
- notturno Polfer dalle 22:00
- basket RFI separato da accessorie ordinarie
- coerenza preview ↔ salvataggio
- coerenza breakdown ↔ totale
## Workflow RFI

1. Inserimento turno con scalo
2. Generazione automatica rfiBasketGross
3. Inserimento diretto nel basket (OPEN)
4. Visualizzazione in UI (Totale generato)
5. Pagamento manuale utente
6. Spostamento in PAID
7. Inclusione nel cedolino (solo mese pagamento)