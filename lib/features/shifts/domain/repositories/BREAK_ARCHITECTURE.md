# DUTYPAY — BREAK ARCHITECTURE

## Obiettivo

Break è una feature sociale sperimentale di DutyPay.

La sua finalità è aumentare l'utilizzo quotidiano dell'app e favorire il passaparola tra colleghi senza interferire con il motore economico.

Funzione principale:

> **Chi paga il caffè ☕**

Gli utenti potranno:

* creare una stanza;
* condividere un codice;
* far entrare altri colleghi;
* visualizzare i partecipanti in tempo reale;
* avviare una sfida sincronizzata;
* ottenere lo stesso risultato su tutti i dispositivi.

---

# Principio Fondamentale

Break è completamente indipendente dal core economico.

Non deve dipendere da:

* motore turni;
* cedolino;
* basket straordinari;
* basket RFI;
* basket compensativo;
* backup/import/export;
* profili stipendiali;
* policy reparto.

L'unico punto di ingresso conosciuto dal resto dell'app è:

```text
BreakPage
```

Tutta la logica della feature risiede esclusivamente sotto:

```text
lib/features/break/
```

---

# Struttura della Feature

```text
lib/features/break/

├── data/
│   ├── datasources/
│   │   ├── firestore_break_datasource.dart
│   │   └── local_break_identity_datasource.dart
│   │
│   ├── dto/
│   │   ├── break_room_dto.dart
│   │   └── break_participant_dto.dart
│   │
│   ├── repositories/
│   │   ├── firestore_break_room_repository.dart
│   │   └── break_identity_repository_impl.dart
│   │
│   └── services/
│       └── break_code_generator.dart
│
├── di/
│   └── break_dependencies.dart
│
├── domain/
│   ├── constants/
│   │   └── break_constants.dart
│   │
│   ├── models/
│   │   ├── break_identity.dart
│   │   ├── break_room.dart
│   │   └── break_participant.dart
│   │
│   ├── repositories/
│   │   ├── break_identity_repository.dart
│   │   └── break_room_repository.dart
│   │
│   └── usecases/
│       ├── create_break_room_usecase.dart
│       ├── join_break_room_usecase.dart
│       ├── watch_break_room_usecase.dart
│       ├── watch_break_participants_usecase.dart
│       ├── set_break_ready_usecase.dart
│       ├── start_break_round_usecase.dart
│       ├── reset_break_round_usecase.dart
│       ├── get_local_identity_usecase.dart
│       └── save_nickname_usecase.dart
│
├── infrastructure/
│   └── firestore_break_paths.dart
│
└── presentation/
    ├── break_page.dart
    └── widgets/
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

La Presentation non accede mai direttamente a Firestore.

---

# Domain Models

## BreakRoom

Responsabilità:

* rappresentare una stanza;
* mantenere lo stato della partita;
* contenere il risultato sincronizzato.

Campi principali:

```text
id
roomCode
title
createdBy
createdAt
status
participantsCount
maxParticipants
selectedPayerId
roundSeed
resultId
resultText
startedAt
completedAt
```

Status disponibili:

```text
waiting
running
completed
```

---

## BreakParticipant

Responsabilità:

* rappresentare un partecipante.

Campi:

```text
id
deviceId
roomId
displayName
joinedAt
isReady
lives
eliminated
position
avatarSeed
```

---

## BreakIdentity

Identità locale anonima.

Campi:

```text
deviceId
nickname
avatarSeed
```

Non vengono raccolti:

* email;
* matricola;
* nome reale obbligatorio;
* dati di servizio;
* dati stipendiali.

---

# Firestore

Struttura prevista:

```text
breakRooms/{roomId}

breakRooms/{roomId}/participants/{deviceId}

breakRoomCodes/{roomCode}
```

## breakRooms

Contiene:

* dati stanza;
* stato;
* risultato;
* seed;
* contatori.

---

## participants

Ogni partecipante utilizza:

```text
deviceId
```

come identificativo del documento.

Vantaggi:

* nessun duplicato;
* rientro nella stanza;
* aggiornamento semplice dello stato.

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

Firestore comunica esclusivamente tramite DTO.

Pipeline:

```text
Firestore
     ↕
DTO
     ↕
Domain Model
```

DTO presenti:

* BreakRoomDto
* BreakParticipantDto

---

# Local Identity

Gestione completamente locale.

Componenti:

* BreakIdentity
* LocalBreakIdentityDatasource
* BreakIdentityRepository
* BreakIdentityRepositoryImpl
* GetLocalIdentityUseCase
* SaveNicknameUseCase

Persistenza:

```text
SharedPreferences
```

---

# Dependency Container

La feature utilizza un container dedicato.

File:

```text
lib/features/break/di/break_dependencies.dart
```

La UI utilizza esclusivamente:

```text
BreakDependencies.instance
```

Responsabilità:

* FirebaseFirestore;
* FirestoreBreakPaths;
* FirestoreBreakDatasource;
* repository;
* use case;
* datasource locali.

---

# Code Generator

Classe:

```text
BreakCodeGenerator
```

Genera codici stanza del tipo:

```text
BRK-X7K4M
```

Caratteristiche:

* brevi;
* leggibili;
* casuali;
* basati su UUID;
* privi di caratteri ambigui.

---

# Stato Implementazione

## Completato

* Tab Break
* Architettura feature
* Domain Models
* Repository Interfaces
* DTO
* Firestore Paths
* Firestore Datasource
* Firestore Repository
* Local Identity
* Code Generator
* Use Cases
* Dependency Container

---

## Da implementare

* dialog nickname;
* create room UI;
* join room UI;
* BreakRoomPage;
* partecipanti realtime;
* ready state;
* avvio partita;
* animazione sincronizzata;
* Firestore Security Rules.

---

# Roadmap Tecnica

1. Collegare `BreakPage` al dependency container.
2. Richiedere il nickname al primo avvio.
3. Implementare "Crea stanza".
4. Implementare "Entra tramite codice".
5. Collegare `BreakRoomPage`.
6. Mostrare i partecipanti realtime.
7. Gestire lo stato Ready.
8. Avviare il round.
9. Sincronizzare il risultato tramite:

   * `roundSeed`;
   * `selectedPayerId`;
   * `resultId`.
10. Completare l'hardening delle Firestore Rules prima della release pubblica.
