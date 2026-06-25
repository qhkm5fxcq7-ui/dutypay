import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/break_participant.dart';
import '../../domain/models/break_room.dart';
import '../../infrastructure/firestore_break_paths.dart';
import '../dto/break_participant_dto.dart';
import '../dto/break_room_dto.dart';

class FirestoreBreakDatasource {
  final FirestoreBreakPaths paths;

  const FirestoreBreakDatasource(this.paths);

  Future<void> createRoom({
    required BreakRoom room,
    required BreakParticipant host,
  }) async {
    final batch = paths.firestore.batch();

    final roomRef = paths.room(room.id);
    final codeRef = paths.roomCode(room.roomCode);
    final hostRef = paths.participant(
      roomId: room.id,
      deviceId: host.deviceId,
    );

    batch.set(roomRef, BreakRoomDto.fromDomain(room).toFirestore());
    batch.set(codeRef, {
      FirestoreBreakPaths.fieldRoomId: room.id,
      FirestoreBreakPaths.fieldRoomCode: room.roomCode,
      FirestoreBreakPaths.fieldCreatedAt: room.createdAt,
    });
    batch.set(hostRef, BreakParticipantDto.fromDomain(host).toFirestore());

    await batch.commit();
  }

  Future<String?> resolveRoomIdByCode(String roomCode) async {
    final snapshot = await paths.roomCode(roomCode).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return data[FirestoreBreakPaths.fieldRoomId] as String?;
  }

  Future<BreakRoom?> getRoom(String roomId) async {
    final snapshot = await paths.room(roomId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return BreakRoomDto.fromFirestore(data, id: snapshot.id).toDomain();
  }

  Future<BreakParticipant?> getParticipant({
    required String roomId,
    required String deviceId,
  }) async {
    final snapshot = await paths
        .participant(
          roomId: roomId,
          deviceId: deviceId,
        )
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return BreakParticipantDto.fromFirestore(data, id: snapshot.id).toDomain();
  }

  Future<void> upsertParticipant(BreakParticipant participant) async {
    await paths
        .participant(
          roomId: participant.roomId,
          deviceId: participant.deviceId,
        )
        .set(
          BreakParticipantDto.fromDomain(participant).toFirestore(),
          SetOptions(merge: true),
        );
  }

  Stream<BreakRoom?> watchRoom(String roomId) {
    return paths.room(roomId).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return BreakRoomDto.fromFirestore(data, id: snapshot.id).toDomain();
    });
  }

  Stream<List<BreakParticipant>> watchParticipants(String roomId) {
    return paths
        .participants(roomId)
        .orderBy(FirestoreBreakPaths.fieldJoinedAt)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BreakParticipantDto.fromFirestore(
          doc.data(),
          id: doc.id,
        ).toDomain();
      }).toList();
    });
  }

  Future<void> setReady({
    required String roomId,
    required String deviceId,
    required bool isReady,
  }) async {
    await paths.participant(roomId: roomId, deviceId: deviceId).update({
      FirestoreBreakPaths.fieldIsReady: isReady,
    });
  }

  Future<void> updateRoomFields({
    required String roomId,
    required Map<String, dynamic> fields,
  }) async {
    await paths.room(roomId).update(fields);
  }

  Future<void> markRoundRunning({
    required String roomId,
    required String roundSeed,
    required String resultId,
    required String selectedPayerId,
    required String resultText,
    required DateTime startedAt,
  }) async {
    await paths.room(roomId).update({
      FirestoreBreakPaths.fieldStatus: BreakRoomStatus.running.name,
      FirestoreBreakPaths.fieldRoundSeed: roundSeed,
      FirestoreBreakPaths.fieldResultId: resultId,
      FirestoreBreakPaths.fieldSelectedPayerId: selectedPayerId,
      FirestoreBreakPaths.fieldResultText: resultText,
      FirestoreBreakPaths.fieldStartedAt: startedAt,
      FirestoreBreakPaths.fieldCompletedAt: null,
    });
  }

  Future<void> markRoundCompleted({
    required String roomId,
    required DateTime completedAt,
  }) async {
    await paths.room(roomId).update({
      FirestoreBreakPaths.fieldStatus: BreakRoomStatus.completed.name,
      FirestoreBreakPaths.fieldCompletedAt: completedAt,
    });
  }

  Future<void> resetRound(String roomId) async {
    await paths.room(roomId).update({
      FirestoreBreakPaths.fieldStatus: BreakRoomStatus.waiting.name,
      FirestoreBreakPaths.fieldRoundSeed: null,
      FirestoreBreakPaths.fieldResultId: null,
      FirestoreBreakPaths.fieldSelectedPayerId: null,
      FirestoreBreakPaths.fieldResultText: null,
      FirestoreBreakPaths.fieldStartedAt: null,
      FirestoreBreakPaths.fieldCompletedAt: null,
    });
  }

  Future<void> deleteRoomCode(String roomCode) async {
    await paths.roomCode(roomCode).delete();
  }
}
