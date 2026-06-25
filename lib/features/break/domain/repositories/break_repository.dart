import '../models/break_participant.dart';
import '../models/break_room.dart';

abstract class BreakRepository {
  Future<BreakRoom> createRoom({
    required String title,
    required String createdBy,
  });

  Future<BreakRoom> joinRoom({
    required String code,
    required String displayName,
  });

  Stream<BreakRoom?> watchRoom(String roomId);

  Stream<List<BreakParticipant>> watchParticipants(String roomId);

  Future<void> setReady({
    required String roomId,
    required String participantId,
    required bool isReady,
  });

  Future<void> startRound({
    required String roomId,
    required String startedByParticipantId,
  });

  Future<void> resetRound(String roomId);
}
