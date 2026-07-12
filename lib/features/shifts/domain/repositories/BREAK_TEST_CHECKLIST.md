# DUTYPAY — BREAK TEST CHECKLIST

## Obiettivo

Questo documento definisce la procedura ufficiale di collaudo della feature Break.

La checklist deve essere completata prima di qualsiasi release pubblica.

---

# Ambiente di test

Configurazione minima consigliata:

- Dispositivo A (Android/iPhone)
- Dispositivo B (Desktop Flutter)

Entrambi devono utilizzare lo stesso progetto Firebase.

Ogni dispositivo deve avere un proprio deviceId.

---

# Requisiti iniziali

Verificare:

- [ ] Firebase configurato
- [ ] Connessione internet disponibile
- [ ] Flutter test PASS
- [ ] Nessun errore bloccante in flutter analyze
- [ ] Firestore raggiungibile

---

# 1. Primo avvio

Verificare:

- [ ] Break si apre correttamente
- [ ] Richiesta nickname al primo avvio
- [ ] Nickname salvato
- [ ] Nickname persistente al riavvio
- [ ] DeviceId persistente

---

# 2. Creazione stanza

Verificare:

- [ ] Creazione stanza completata
- [ ] Codice stanza generato
- [ ] Codice copiabile
- [ ] Creatore presente tra i partecipanti
- [ ] participantsCount = 1
- [ ] room.status = waiting

---

# 3. Join stanza

Verificare:

- [ ] Join tramite codice valido
- [ ] Join con lettere minuscole
- [ ] Join con spazi iniziali/finali
- [ ] Gestione codice inesistente
- [ ] Gestione stanza piena
- [ ] Gestione stanza già avviata
- [ ] Nessun partecipante duplicato

---

# 4. Realtime

Verificare sincronizzazione tra i dispositivi:

- [ ] Nuovo partecipante
- [ ] Cambio stato Ready
- [ ] Avvio partita
- [ ] Reset partita
- [ ] Risultato finale

---

# 5. Partecipanti

Verificare:

- [ ] Elenco corretto
- [ ] Avatar corretti
- [ ] Nickname corretti
- [ ] Conteggio corretto
- [ ] Nessun duplicato

---

# 6. Ready

Verificare:

- [ ] Ready ON
- [ ] Ready OFF
- [ ] Aggiornamento realtime
- [ ] Pulsante disabilitato quando necessario

---

# 7. Avvio partita

Verificare:

- [ ] Start consentito solo quando previsto
- [ ] room.status = running
- [ ] roundSeed valorizzato
- [ ] selectedPayerId valorizzato
- [ ] resultId valorizzato
- [ ] resultText valorizzato

---

# 8. Animazione

Verificare:

- [ ] Animazione avviata
- [ ] Sequenza identica sui dispositivi
- [ ] Stesso vincitore
- [ ] Stesso risultato finale
- [ ] Nessuna desincronizzazione

---

# 9. Reset

Verificare:

- [ ] Stato waiting
- [ ] Reset selectedPayerId
- [ ] Reset roundSeed
- [ ] Reset resultId
- [ ] Reset resultText
- [ ] Reset Ready

---

# 10. Persistenza

Chiudere completamente l'app.

Verificare:

- [ ] Nickname mantenuto
- [ ] DeviceId mantenuto
- [ ] Possibilità di rientrare

---

# 11. Error handling

Verificare:

- [ ] Connessione assente
- [ ] Firestore non raggiungibile
- [ ] Timeout
- [ ] Errori mostrati correttamente
- [ ] Nessun crash

---

# 12. Edge cases

Verificare:

- [ ] Join contemporanei
- [ ] Ready contemporanei
- [ ] Start contemporanei
- [ ] Reset durante animazione
- [ ] Chiusura app durante animazione
- [ ] Riapertura immediata

---

# 13. UI

Verificare:

- [ ] Nessun overflow
- [ ] Nessun testo tagliato
- [ ] Nessun layout rotto
- [ ] Responsive
- [ ] Tema coerente

---

# 14. Prestazioni

Verificare:

- [ ] Nessun lag
- [ ] Nessun freeze
- [ ] Rebuild contenuti
- [ ] Firestore fluido

---

# 15. Regressione

Verificare che Break non abbia modificato:

- [ ] Turni
- [ ] Cedolino
- [ ] Basket Straordinari
- [ ] Basket RFI
- [ ] Basket Compensativo
- [ ] Dashboard
- [ ] Calendario
- [ ] Backup
- [ ] Parser Cedolini

---

# Criteri di rilascio

La feature Break può essere considerata pronta per la release quando risultano soddisfatte tutte le seguenti condizioni:

- Flutter test: PASS
- Nessun errore bloccante in flutter analyze
- Tutti i test della presente checklist completati
- Nessun crash durante il collaudo
- Sincronizzazione verificata tra più dispositivi
- Nessuna regressione sul motore economico
- Firestore stabile
- Esperienza utente conforme agli standard del progetto DutyPay

---

# Stato

Versione documento: 1.0

Feature: Break

Ultimo aggiornamento: giugno 2026
# Stato

Versione documento:

**1.0.9 (Release Candidate)**

Stato attuale della feature:

### Core completato

- ✅ Architettura modulare
- ✅ Dependency Injection dedicata
- ✅ Domain Models
- ✅ Repository
- ✅ DTO
- ✅ Firestore Datasource
- ✅ Local Identity
- ✅ Code Generator
- ✅ Use Case principali
- ✅ Challenge Engine deterministico
- ✅ Serializzazione Firestore
- ✅ Gestione stato stanza
- ✅ Gestione partecipanti

### Regression Pack disponibili

Copertura automatica:

- Break Domain Regression Pack
- Break DTO Regression Pack
- Break Challenge Engine Regression Pack

Tutti i regression pack devono rimanere verdi prima di ogni release.

### Test automatici

Verifiche garantite:

- modelli Domain;
- serializzazione/deserializzazione DTO;
- persistenza dei dati;
- determinismo del Challenge Engine;
- coerenza dei frame della gara;
- sincronizzazione del vincitore;
- stabilità delle animazioni.

### Stato Release

- flutter test: PASS (160/160)
- flutter analyze: PASS
- nessun warning
- nessun errore bloccante

### Componenti ancora da validare manualmente

Prima della release pubblica restano da completare esclusivamente i test end-to-end relativi a:

- creazione stanza da UI;
- join tramite codice;
- sincronizzazione realtime Firestore;
- animazioni multiplayer tra dispositivi reali;
- Firestore Security Rules;
- UX finale della feature Break.

La logica di dominio e il Challenge Engine sono considerati consolidati; le attività residue riguardano principalmente integrazione UI e validazione multiplayer.
## Validazione Eseguita

Data: giugno 2026

Ambiente:

- Chrome (2 finestre indipendenti)
- Firebase reale

Scenario verificato:

- Creazione stanza
- Join tramite codice
- Partecipanti sincronizzati
- Countdown sincronizzato
- Gara sincronizzata
- Identico vincitore su entrambi i client
- Nessuna desincronizzazione osservata

Esito:

✅ PASS