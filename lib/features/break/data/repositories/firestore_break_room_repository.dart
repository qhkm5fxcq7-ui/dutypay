import 'package:uuid/uuid.dart';

import '../../domain/constants/break_constants.dart';
import '../../domain/models/break_participant.dart';
import '../../domain/models/break_room.dart';
import '../../domain/repositories/break_identity_repository.dart';
import '../../domain/repositories/break_room_repository.dart';
import '../datasources/firestore_break_datasource.dart';
import '../services/break_code_generator.dart';

class FirestoreBreakRoomRepository implements BreakRoomRepository {
  final FirestoreBreakDatasource datasource;
  final BreakIdentityRepository identityRepository;
  final BreakCodeGenerator codeGenerator;
  final Uuid uuid;

  const FirestoreBreakRoomRepository({
    required this.datasource,
    required this.identityRepository,
    required this.codeGenerator,
    this.uuid = const Uuid(),
  });

  @override
  Future<BreakRoom> createRoom({
    String? title,
  }) async {
    final identity = await identityRepository.getOrCreateIdentity();
    final now = DateTime.now();
    final roomId = uuid.v4();
    final roomCode = codeGenerator.generateRoomCode();

    final room = BreakRoom(
      id: roomId,
      roomCode: roomCode,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : BreakConstants.defaultRoomTitle,
      createdBy: identity.deviceId,
      createdAt: now,
      status: BreakRoomStatus.waiting,
      participantsCount: 1,
      maxParticipants: BreakConstants.defaultMaxParticipants,
    );

    final host = BreakParticipant(
      id: identity.deviceId,
      deviceId: identity.deviceId,
      roomId: roomId,
      displayName: _resolveDisplayName(identity.nickname),
      joinedAt: now,
      isReady: false,
      lives: 1,
      eliminated: false,
      position: 0,
      avatarSeed: identity.avatarSeed,
    );

    await datasource.createRoom(
      room: room,
      host: host,
    );

    return room;
  }

  @override
  Future<BreakRoom> joinRoom({
    required String roomCode,
    String? nickname,
  }) async {
    final normalizedCode = roomCode.trim().toUpperCase();
    final roomId = await datasource.resolveRoomIdByCode(normalizedCode);

    if (roomId == null) {
      throw StateError('Stanza non trovata');
    }

    final room = await datasource.getRoom(roomId);

    if (room == null) {
      throw StateError('Stanza non trovata');
    }

    if (room.status != BreakRoomStatus.waiting) {
      throw StateError('La stanza non è più in attesa');
    }

    if (room.participantsCount >= room.maxParticipants) {
      throw StateError('La stanza è piena');
    }

    final identity = await identityRepository.getOrCreateIdentity();
    final displayName = _resolveDisplayName(nickname ?? identity.nickname);
    final existingParticipant = await datasource.getParticipant(
      roomId: room.id,
      deviceId: identity.deviceId,
    );

    final participant = BreakParticipant(
      id: identity.deviceId,
      deviceId: identity.deviceId,
      roomId: room.id,
      displayName: displayName,
      joinedAt: existingParticipant?.joinedAt ?? DateTime.now(),
      isReady: existingParticipant?.isReady ?? false,
      lives: existingParticipant?.lives ?? 1,
      eliminated: existingParticipant?.eliminated ?? false,
      position: existingParticipant?.position ?? 0,
      avatarSeed: identity.avatarSeed,
    );

    await datasource.upsertParticipant(participant);

    if (existingParticipant == null) {
      await datasource.updateRoomFields(
        roomId: room.id,
        fields: {
          'participantsCount': room.participantsCount + 1,
        },
      );
    }

    return room.copyWith(
      participantsCount: existingParticipant == null
          ? room.participantsCount + 1
          : room.participantsCount,
    );
  }

  @override
  Stream<BreakRoom?> watchRoom(String roomId) {
    return datasource.watchRoom(roomId);
  }

  @override
  Stream<List<BreakParticipant>> watchParticipants(String roomId) {
    return datasource.watchParticipants(roomId);
  }

  @override
  Future<void> setReady({
    required String roomId,
    required bool isReady,
  }) async {
    final identity = await identityRepository.getOrCreateIdentity();

    await datasource.setReady(
      roomId: roomId,
      deviceId: identity.deviceId,
      isReady: isReady,
    );
  }

  @override
  Future<void> startRound(String roomId) async {
    final participants = await datasource.watchParticipants(roomId).first;

    if (participants.length < 2) {
      throw StateError('Servono almeno due partecipanti');
    }

    final seed = uuid.v4();
    final resultId = uuid.v4();
    final payerIndex = seed.hashCode.abs() % participants.length;
    final selectedPayer = participants[payerIndex];

    final now = DateTime.now();

    await datasource.markRoundRunning(
      roomId: roomId,
      roundSeed: seed,
      resultId: resultId,
      selectedPayerId: selectedPayer.id,
      resultText: '☕ Oggi paga il caffè: ${selectedPayer.displayName}',
      startedAt: now,
    );

    await datasource.markRoundCompleted(
      roomId: roomId,
      completedAt: now,
    );
  }

  @override
  Future<void> resetRound(String roomId) {
    return datasource.resetRound(roomId);
  }

  String _resolveDisplayName(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return 'Collega';
    }

    return cleaned;
  }
}
