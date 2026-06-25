import '../repositories/break_room_repository.dart';

class StartBreakRoundUseCase {
  final BreakRoomRepository repository;

  const StartBreakRoundUseCase(this.repository);

  Future<void> execute(String roomId) {
    return repository.startRound(roomId);
  }
}
