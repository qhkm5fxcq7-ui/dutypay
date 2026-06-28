# DUTYPAY — BREAK ARCHITECTURE

## Obiettivo

Break è il modulo sociale di DutyPay.

È completamente indipendente dal motore economico ed è progettato per aumentare:

* utilizzo quotidiano;
* coinvolgimento;
* viralità;
* community tra colleghi.

La prima funzionalità implementata è:

**Chi paga il caffè ☕**

Gli utenti possono:

* creare una stanza;
* condividere un codice;
* entrare tramite codice;
* vedere i partecipanti in tempo reale;
* sincronizzare una sfida;
* ottenere lo stesso risultato su tutti i dispositivi.

---

# Principio Fondamentale

Break è completamente separato dal Core Economico.

Non dipende da:

* turni;
* cedolino;
* basket straordinari;
* basket compensativi;
* basket RFI;
* DepartmentPolicy;
* parser cedolini;
* backup economici.

L'unico punto di accesso è:

```text
BreakPage
```

Tutto il codice risiede esclusivamente sotto:

```text
lib/features/break/
```

---

# Architettura

Pattern utilizzato:

```text
Presentation
        ↓
Use Cases
        ↓
Repository Interface
        ↓
Repository Implementation
        ↓
Datasource
        ↓
Firestore
```

La UI non comunica mai direttamente con Firestore.

---

# Struttura

La feature è composta da:

* Presentation;
* Domain;
* Data;
* Infrastructure;
* Dependency Injection.

Il Domain contiene esclusivamente logica applicativa.

La Data contiene esclusivamente persistenza.

---

# Domain Models

## BreakRoom

Rappresenta una stanza multiplayer.

Responsabilità:

* stato della stanza;
* round corrente;
* seed condiviso;
* risultato sincronizzato.

---

## BreakParticipant

Rappresenta un partecipante.

Contiene:

* identità;
* stato Ready;
* posizione;
* avatar;
* dati necessari alla sincronizzazione.

---

## BreakIdentity

Identità locale persistente.

Persistita tramite SharedPreferences.

Non vengono memorizzati:

* email;
* dati personali;
* dati stipendiali;
* informazioni di servizio.

---

# Firestore

Collezioni principali:

```text
breakRooms/{roomId}

breakRooms/{roomId}/participants/{deviceId}

breakRoomCodes/{roomCode}
```

---

## breakRooms

Contiene:

* configurazione stanza;
* stato;
* seed;
* risultato;
* metadati del round.

---

## participants

Ogni documento utilizza:

```text
deviceId
```

come chiave primaria.

Questo evita duplicati e semplifica il rientro nella stanza.

---

## breakRoomCodes

Indice utilizzato per convertire rapidamente:

```text
roomCode

↓

roomId
```

---

# DTO

La comunicazione con Firestore passa esclusivamente tramite DTO.

Pipeline:

```text
Firestore

↓

DTO

↓

Domain Model
```

DTO disponibili:

* BreakRoomDto;
* BreakParticipantDto.

---

# Local Identity

Pipeline:

```text
SharedPreferences

↓

LocalBreakIdentityDatasource

↓

BreakIdentityRepository

↓

UseCases

↓

Presentation
```

---

# Dependency Injection

Container dedicato:

```text
BreakDependencies
```

Espone:

* FirebaseFirestore;
* datasource;
* repository;
* use case;
* servizi locali.

La UI non costruisce manualmente alcuna dipendenza.

---

# Challenge Engine

Il Challenge Engine è completamente deterministico.

Componenti principali:

* ChallengeEngine;
* ChallengeFrame;
* ChallengeRunner;
* ChallengeState.

La simulazione utilizza:

* roundSeed;
* selectedPayerId;
* avatarSeed.

Ogni dispositivo produce la stessa animazione partendo dagli stessi dati.

---

# Stati Challenge

Sequenza ufficiale:

```text
Countdown

↓

Running

↓

Finished

↓

Suspense

↓

Completed
```

---

# Code Generator

Genera codici stanza nel formato:

```text
BRK-X7K4M
```

Caratteristiche:

* casuali;
* leggibili;
* privi di caratteri ambigui;
* basati su UUID.

---

# Stato implementazione

## Completato

* architettura Break;
* Domain Models;
* DTO;
* Firestore Datasource;
* Repository;
* Dependency Injection;
* Local Identity;
* Code Generator;
* Use Cases;
* Challenge Engine;
* animazione deterministica;
* sincronizzazione tramite seed.

---

## Da completare

* rifiniture UI;
* Firestore Security Rules;
* ottimizzazioni UX;
* integrazione Analytics;
* integrazione Crashlytics.

---

# Regressioni

Regression pack disponibili:

* Break Domain;
* Break DTO;
* Break Challenge Engine.

Tutti i regression pack risultano verdi.

---

# Vincoli Architetturali

È vietato:

* introdurre dipendenze verso il Core Economico;
* accedere direttamente a Firestore dalla UI;
* duplicare logica nei widget;
* rendere non deterministica la simulazione della challenge.

Ogni modifica del Challenge Engine deve mantenere la sincronizzazione tra dispositivi.

---

# Stato Attuale

Release Candidate:

**1.0.9**

Stato:

* architettura consolidata;
* backend stabile;
* Challenge Engine validato;
* regression pack completo;
* nessuna regressione nota nel modulo Break.
