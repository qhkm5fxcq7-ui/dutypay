import '../repositories/break_room_repository.dart';

class ResetBreakRoundUseCase {
  final BreakRoomRepository repository;

  const ResetBreakRoundUseCase(this.repository);

  Future<void> execute(String roomId) {
    return repository.resetRound(roomId);
  }
}
