import '../models/break_participant.dart';
import '../repositories/break_room_repository.dart';

class WatchBreakParticipantsUseCase {
  final BreakRoomRepository repository;

  const WatchBreakParticipantsUseCase(this.repository);

  Stream<List<BreakParticipant>> execute(String roomId) {
    return repository.watchParticipants(roomId);
  }
}
