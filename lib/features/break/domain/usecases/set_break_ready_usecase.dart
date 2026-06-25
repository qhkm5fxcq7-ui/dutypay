import '../repositories/break_room_repository.dart';

class SetBreakReadyUseCase {
  final BreakRoomRepository repository;

  const SetBreakReadyUseCase(this.repository);

  Future<void> execute({
    required String roomId,
    required bool isReady,
  }) {
    return repository.setReady(
      roomId: roomId,
      isReady: isReady,
    );
  }
}
