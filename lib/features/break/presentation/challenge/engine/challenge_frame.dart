enum RunnerAnimation {
  idle,
  run,
  sprint,
  jump,
  stumble,
  celebrate,
  lose,
}

class ChallengeRunnerFrame {
  final String runnerId;
  final int lane;
  final double position;
  final double speed;
  final double jumpHeight;
  final double rotation;
  final RunnerAnimation animation;

  const ChallengeRunnerFrame({
    required this.runnerId,
    required this.lane,
    required this.position,
    required this.speed,
    this.jumpHeight = 0,
    this.rotation = 0,
    this.animation = RunnerAnimation.run,
  });
}

class ChallengeFrame {
  final int index;
  final Duration elapsed;
  final List<ChallengeRunnerFrame> runners;
  final double cameraZoom;
  final double cameraShake;

  const ChallengeFrame({
    required this.index,
    required this.elapsed,
    required this.runners,
    this.cameraZoom = 1,
    this.cameraShake = 0,
  });
}
