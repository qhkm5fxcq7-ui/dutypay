import '../models/break_participant.dart';
import '../models/break_room.dart';

abstract interface class BreakRoomRepository {
  Future<BreakRoom> createRoom({
    String? title,
    String? customRoomCode,
  });

  Future<BreakRoom> joinRoom({
    required String roomCode,
    String? nickname,
  });

  Stream<BreakRoom?> watchRoom(String roomId);

  Stream<List<BreakParticipant>> watchParticipants(
    String roomId,
  );

  Future<void> setReady({
    required String roomId,
    required bool isReady,
  });

  Future<void> startRound(String roomId);

  Future<void> resetRound(String roomId);
}
