import '../../../domain/models/break_participant.dart';

class ChallengeRunner {
  final String id;
  final String displayName;
  final int lane;
  final double position;
  final bool isWinner;

  const ChallengeRunner({
    required this.id,
    required this.displayName,
    required this.lane,
    this.position = 0,
    this.isWinner = false,
  });

  factory ChallengeRunner.fromParticipant({
    required BreakParticipant participant,
    required int lane,
    required String selectedPayerId,
  }) {
    return ChallengeRunner(
      id: participant.id,
      displayName: participant.displayName,
      lane: lane,
      isWinner: participant.id == selectedPayerId,
    );
  }

  ChallengeRunner copyWith({
    double? position,
  }) {
    return ChallengeRunner(
      id: id,
      displayName: displayName,
      lane: lane,
      position: position ?? this.position,
      isWinner: isWinner,
    );
  }
}
