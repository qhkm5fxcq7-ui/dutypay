import '../models/break_room.dart';
import '../repositories/break_room_repository.dart';

class CreateBreakRoomUseCase {
  final BreakRoomRepository repository;

  const CreateBreakRoomUseCase(this.repository);

  Future<BreakRoom> execute({
    String? title,
    String? customRoomCode,
  }) {
    return repository.createRoom(
      title: title,
      customRoomCode: customRoomCode,
    );
  }
}
