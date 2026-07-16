import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/break/domain/constants/break_constants.dart';
import 'package:dutypay/features/break/domain/models/break_participant.dart';
import 'package:dutypay/features/break/domain/models/break_room.dart';

void main() {
  group('Break domain regression', () {
    test('BreakRoom map round-trip preserves all fields', () {
      final createdAt = DateTime(2026, 6, 1, 10, 30);
      final startedAt = DateTime(2026, 6, 1, 10, 35);
      final completedAt = DateTime(2026, 6, 1, 10, 40);

      final room = BreakRoom(
        id: 'room_1',
        roomCode: 'ABCD12',
        title: 'Chi offre?',
        createdBy: 'user_1',
        createdAt: createdAt,
        status: BreakRoomStatus.completed,
        participantsCount: 4,
        maxParticipants: 8,
        selectedPayerId: 'user_2',
        roundSeed: 'seed_123',
        resultId: 'result_1',
        resultText: 'Paga Mario',
        startedAt: startedAt,
        completedAt: completedAt,
      );

      final restored = BreakRoom.fromMap(room.toMap());

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

    test('BreakParticipant map round-trip preserves all fields', () {
      final joinedAt = DateTime(2026, 6, 1, 10, 31);

      final participant = BreakParticipant(
        id: 'participant_1',
        roomId: 'room_1',
        displayName: 'Mario',
        joinedAt: joinedAt,
        isReady: true,
        lives: 2,
        eliminated: true,
        position: 3,
        avatarSeed: 'avatar_1',
        deviceId: 'device_1',
      );

      final restored = BreakParticipant.fromMap(participant.toMap());

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

    test('BreakRoomStatus parser supports known values and falls back safely',
        () {
      expect(
        BreakRoomStatus.fromValue('waiting'),
        BreakRoomStatus.waiting,
      );
      expect(
        BreakRoomStatus.fromValue('running'),
        BreakRoomStatus.running,
      );
      expect(
        BreakRoomStatus.fromValue('completed'),
        BreakRoomStatus.completed,
      );
      expect(
        BreakRoomStatus.fromValue('unknown'),
        BreakRoomStatus.waiting,
      );
      expect(
        BreakRoomStatus.fromValue(null),
        BreakRoomStatus.waiting,
      );
    });

    test('BreakRoom fromMap uses safe defaults for missing fields', () {
      final room = BreakRoom.fromMap(const {});

      expect(room.id, '');
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

    test('BreakRoom copyWith changes only requested fields', () {
      final createdAt = DateTime(2026, 6, 1, 10, 30);

      final room = BreakRoom(
        id: 'room_1',
        roomCode: 'ABCD12',
        title: 'Chi offre?',
        createdBy: 'user_1',
        createdAt: createdAt,
        participantsCount: 2,
      );

      final updated = room.copyWith(status: BreakRoomStatus.running);

      expect(updated.status, BreakRoomStatus.running);
      expect(updated.id, room.id);
      expect(updated.roomCode, room.roomCode);
      expect(updated.title, room.title);
      expect(updated.createdBy, room.createdBy);
      expect(updated.createdAt, room.createdAt);
      expect(updated.participantsCount, room.participantsCount);
      expect(updated.maxParticipants, room.maxParticipants);
    });

    test('BreakParticipant copyWith changes only requested fields', () {
      final joinedAt = DateTime(2026, 6, 1, 10, 31);

      final participant = BreakParticipant(
        id: 'participant_1',
        roomId: 'room_1',
        displayName: 'Mario',
        joinedAt: joinedAt,
        avatarSeed: 'avatar_1',
        deviceId: 'device_1',
      );

      final updated = participant.copyWith(
        isReady: true,
        lives: 2,
      );

      expect(updated.isReady, isTrue);
      expect(updated.lives, 2);
      expect(updated.id, participant.id);
      expect(updated.roomId, participant.roomId);
      expect(updated.displayName, participant.displayName);
      expect(updated.joinedAt, participant.joinedAt);
      expect(updated.eliminated, participant.eliminated);
      expect(updated.position, participant.position);
      expect(updated.avatarSeed, participant.avatarSeed);
      expect(updated.deviceId, participant.deviceId);
    });
  });
}
