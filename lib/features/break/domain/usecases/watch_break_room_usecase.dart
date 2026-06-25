import '../models/break_room.dart';
import '../repositories/break_room_repository.dart';

class WatchBreakRoomUseCase {
  final BreakRoomRepository repository;

  const WatchBreakRoomUseCase(this.repository);

  Stream<BreakRoom?> execute(String roomId) {
    return repository.watchRoom(roomId);
  }
}
