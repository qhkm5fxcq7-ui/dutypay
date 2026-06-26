import '../../../domain/models/break_participant.dart';
import '../engine/challenge_frame.dart';

class ChallengeRunner {
  final String id;
  final String displayName;
  final int lane;
  final double position;
  final double jumpHeight;
  final double rotation;
  final RunnerAnimation animation;
  final bool isWinner;

  const ChallengeRunner({
    required this.id,
    required this.displayName,
    required this.lane,
    this.position = 0,
    this.jumpHeight = 0,
    this.rotation = 0,
    this.animation = RunnerAnimation.idle,
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
    double? jumpHeight,
    double? rotation,
    RunnerAnimation? animation,
    bool? isWinner,
  }) {
    return ChallengeRunner(
      id: id,
      displayName: displayName,
      lane: lane,
      position: position ?? this.position,
      jumpHeight: jumpHeight ?? this.jumpHeight,
      rotation: rotation ?? this.rotation,
      animation: animation ?? this.animation,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}
