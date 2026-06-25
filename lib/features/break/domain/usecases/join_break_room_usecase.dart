import '../models/break_room.dart';
import '../repositories/break_room_repository.dart';

class JoinBreakRoomUseCase {
  final BreakRoomRepository repository;

  const JoinBreakRoomUseCase(this.repository);

  Future<BreakRoom> execute({
    required String roomCode,
    String? nickname,
  }) {
    return repository.joinRoom(
      roomCode: roomCode,
      nickname: nickname,
    );
  }
}
