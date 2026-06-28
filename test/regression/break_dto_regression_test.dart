import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/break/data/dto/break_participant_dto.dart';
import 'package:dutypay/features/break/data/dto/break_room_dto.dart';
import 'package:dutypay/features/break/domain/constants/break_constants.dart';
import 'package:dutypay/features/break/domain/models/break_participant.dart';
import 'package:dutypay/features/break/domain/models/break_room.dart';

void main() {
  group('Break DTO regression', () {
    test('BreakRoom DTO domain round-trip preserves all fields', () {
      final room = BreakRoom(
        id: 'room_1',
        roomCode: 'ABCD12',
        title: 'Chi offre?',
        createdBy: 'user_1',
        createdAt: DateTime(2026, 6, 1, 10, 30),
        status: BreakRoomStatus.completed,
        participantsCount: 4,
        maxParticipants: 8,
        selectedPayerId: 'user_2',
        roundSeed: 'seed_123',
        resultId: 'result_1',
        resultText: 'Paga Mario',
        startedAt: DateTime(2026, 6, 1, 10, 35),
        completedAt: DateTime(2026, 6, 1, 10, 40),
      );

      final restored = BreakRoomDto.fromDomain(room).toDomain();

      expect(restored.id, room.id);
      expect(restored.roomCode, room.roomCode);
      expect(restored.title, room.title);
      expect(restored.createdBy, room.createdBy);
      expect(restored.createdAt, room.createdAt);
      expect(restored.status, room.status);
      expect(restored.participantsCount, room.participantsCount);
      expect(restored.maxParticipants, room.maxParticipants);
      expect(restored.selectedPayerId, room.selectedPayerId);
      expect(restored.roundSeed, room.roundSeed);
      expect(restored.resultId, room.resultId);
      expect(restored.resultText, room.resultText);
      expect(restored.startedAt, room.startedAt);
      expect(restored.completedAt, room.completedAt);
    });

    test('BreakParticipant DTO domain round-trip preserves all fields', () {
      final participant = BreakParticipant(
        id: 'participant_1',
        roomId: 'room_1',
        displayName: 'Mario',
        joinedAt: DateTime(2026, 6, 1, 10, 31),
        isReady: true,
        lives: 2,
        eliminated: true,
        position: 3,
        avatarSeed: 'avatar_1',
        deviceId: 'device_1',
      );

      final restored = BreakParticipantDto.fromDomain(participant).toDomain();

      expect(restored.id, participant.id);
      expect(restored.roomId, participant.roomId);
      expect(restored.displayName, participant.displayName);
      expect(restored.joinedAt, participant.joinedAt);
      expect(restored.isReady, participant.isReady);
      expect(restored.lives, participant.lives);
      expect(restored.eliminated, participant.eliminated);
      expect(restored.position, participant.position);
      expect(restored.avatarSeed, participant.avatarSeed);
      expect(restored.deviceId, participant.deviceId);
    });

    test('BreakRoom fromFirestore reads complete payload', () {
      final createdAt = DateTime(2026, 6, 1, 10, 30);
      final startedAt = DateTime(2026, 6, 1, 10, 35);
      final completedAt = DateTime(2026, 6, 1, 10, 40);

      final dto = BreakRoomDto.fromFirestore(
        {
          'roomCode': 'ABCD12',
          'title': 'Chi offre?',
          'createdBy': 'user_1',
          'createdAt': createdAt,
          'status': 'completed',
          'participantsCount': 4,
          'maxParticipants': 8,
          'selectedPayerId': 'user_2',
          'roundSeed': 'seed_123',
          'resultId': 'result_1',
          'resultText': 'Paga Mario',
          'startedAt': startedAt,
          'completedAt': completedAt,
        },
        id: 'room_1',
      );

      final room = dto.toDomain();

      expect(room.id, 'room_1');
      expect(room.roomCode, 'ABCD12');
      expect(room.title, 'Chi offre?');
      expect(room.createdBy, 'user_1');
      expect(room.createdAt, createdAt);
      expect(room.status, BreakRoomStatus.completed);
      expect(room.participantsCount, 4);
      expect(room.maxParticipants, 8);
      expect(room.selectedPayerId, 'user_2');
      expect(room.roundSeed, 'seed_123');
      expect(room.resultId, 'result_1');
      expect(room.resultText, 'Paga Mario');
      expect(room.startedAt, startedAt);
      expect(room.completedAt, completedAt);
    });

    test('BreakRoom fromFirestore uses safe defaults for missing fields', () {
      final dto = BreakRoomDto.fromFirestore(const {}, id: 'room_1');
      final room = dto.toDomain();

      expect(room.id, 'room_1');
      expect(room.roomCode, '');
      expect(room.title, BreakConstants.defaultRoomTitle);
      expect(room.createdBy, '');
      expect(room.status, BreakRoomStatus.waiting);
      expect(room.participantsCount, 0);
      expect(room.maxParticipants, BreakConstants.defaultMaxParticipants);
      expect(room.selectedPayerId, isNull);
      expect(room.roundSeed, isNull);
      expect(room.resultId, isNull);
      expect(room.resultText, isNull);
      expect(room.startedAt, isNull);
      expect(room.completedAt, isNull);
    });

    test('BreakParticipant fromFirestore reads complete payload', () {
      final joinedAt = DateTime(2026, 6, 1, 10, 31);

      final dto = BreakParticipantDto.fromFirestore(
        {
          'deviceId': 'device_1',
          'roomId': 'room_1',
          'displayName': 'Mario',
          'joinedAt': joinedAt,
          'isReady': true,
          'lives': 2,
          'eliminated': true,
          'position': 3,
          'avatarSeed': 'avatar_1',
        },
        id: 'participant_1',
      );

      final participant = dto.toDomain();

      expect(participant.id, 'participant_1');
      expect(participant.deviceId, 'device_1');
      expect(participant.roomId, 'room_1');
      expect(participant.displayName, 'Mario');
      expect(participant.joinedAt, joinedAt);
      expect(participant.isReady, isTrue);
      expect(participant.lives, 2);
      expect(participant.eliminated, isTrue);
      expect(participant.position, 3);
      expect(participant.avatarSeed, 'avatar_1');
    });

    test('BreakParticipant fromFirestore uses safe defaults for missing fields', () {
      final dto = BreakParticipantDto.fromFirestore(const {}, id: 'p1');
      final participant = dto.toDomain();

      expect(participant.id, 'p1');
      expect(participant.deviceId, 'p1');
      expect(participant.roomId, '');
      expect(participant.displayName, '');
      expect(participant.isReady, isFalse);
      expect(participant.lives, 1);
      expect(participant.eliminated, isFalse);
      expect(participant.position, 0);
      expect(participant.avatarSeed, '');
    });
  });
}
