class ChallengeRunnerFrame {
  final String runnerId;
  final double position;

  const ChallengeRunnerFrame({
    required this.runnerId,
    required this.position,
  });
}

class ChallengeFrame {
  final int index;
  final Duration elapsed;
  final List<ChallengeRunnerFrame> runners;

  const ChallengeFrame({
    required this.index,
    required this.elapsed,
    required this.runners,
  });
}
