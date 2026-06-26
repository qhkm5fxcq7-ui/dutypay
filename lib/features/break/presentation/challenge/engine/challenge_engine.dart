import 'dart:math';

import '../models/challenge_runner.dart';
import 'challenge_frame.dart';

class ChallengeEngine {
  const ChallengeEngine();

  List<ChallengeFrame> buildRace({
    required List<ChallengeRunner> runners,
    required String selectedPayerId,
    required String roundSeed,
    int frameCount = 42,
    Duration frameDuration = const Duration(milliseconds: 115),
  }) {
    if (runners.isEmpty) {
      return const [];
    }

    final frames = <ChallengeFrame>[];

    for (var frameIndex = 0; frameIndex <= frameCount; frameIndex++) {
      final progress = frameIndex / frameCount;
      final runnerFrames = <ChallengeRunnerFrame>[];

      for (final runner in runners) {
        final isWinner = runner.id == selectedPayerId;
        final random =
            Random(_seedToInt('$roundSeed-${runner.id}-$frameIndex'));
        final noise = (random.nextDouble() - 0.5) * 0.075;
        final wave = sin((progress * pi * 4) + runner.lane) * 0.045;

        final basePosition = isWinner
            ? _winnerProgress(progress)
            : _competitorProgress(progress, runner.lane);

        final position = (basePosition + noise + wave).clamp(
          0.0,
          isWinner ? 1.0 : 0.95,
        );

        runnerFrames.add(
          ChallengeRunnerFrame(
            runnerId: runner.id,
            lane: runner.lane,
            position: frameIndex == frameCount && isWinner ? 1.0 : position,
            speed: _speedFor(progress, isWinner: isWinner),
            jumpHeight: _jumpHeightFor(
              progress: progress,
              lane: runner.lane,
            ),
            rotation: _rotationFor(
              progress: progress,
              lane: runner.lane,
            ),
            animation: _animationFor(
              progress: progress,
              isWinner: isWinner,
              frameIndex: frameIndex,
              frameCount: frameCount,
              lane: runner.lane,
            ),
          ),
        );
      }

      frames.add(
        ChallengeFrame(
          index: frameIndex,
          elapsed: frameDuration * frameIndex,
          runners: runnerFrames,
          cameraZoom: 1 + (progress * 0.025),
          cameraShake: progress > 0.88 ? 0.012 : 0,
        ),
      );
    }

    return frames;
  }

  double _winnerProgress(double progress) {
    if (progress < 0.30) {
      return progress * 0.78;
    }

    if (progress < 0.72) {
      return 0.23 + ((progress - 0.30) / 0.42) * 0.36;
    }

    final finalProgress = (progress - 0.72) / 0.28;
    return 0.59 + _easeOutCubic(finalProgress) * 0.41;
  }

  double _competitorProgress(double progress, int lane) {
    final lanePenalty = (lane % 3) * 0.025;

    if (progress < 0.35) {
      return (progress * 0.88) - lanePenalty;
    }

    if (progress < 0.78) {
      return 0.29 + ((progress - 0.35) / 0.43) * 0.34 - lanePenalty;
    }

    final finalProgress = (progress - 0.78) / 0.22;
    return 0.63 + _easeOutCubic(finalProgress) * 0.25 - lanePenalty;
  }

  double _speedFor(
    double progress, {
    required bool isWinner,
  }) {
    if (progress > 0.84 && isWinner) {
      return 1.45;
    }

    if (progress > 0.84) {
      return 0.78;
    }

    if (progress > 0.45 && progress < 0.62) {
      return 1.18;
    }

    return 1.0;
  }

  double _jumpHeightFor({
    required double progress,
    required int lane,
  }) {
    final jumpWindowStart = 0.34 + (lane * 0.035);
    final jumpWindowEnd = jumpWindowStart + 0.12;

    if (progress < jumpWindowStart || progress > jumpWindowEnd) {
      return 0;
    }

    final localProgress =
        (progress - jumpWindowStart) / (jumpWindowEnd - jumpWindowStart);

    return sin(localProgress * pi) * 18;
  }

  double _rotationFor({
    required double progress,
    required int lane,
  }) {
    final stumbleStart = 0.58 + (lane * 0.025);
    final stumbleEnd = stumbleStart + 0.08;

    if (progress < stumbleStart || progress > stumbleEnd) {
      return 0;
    }

    final localProgress =
        (progress - stumbleStart) / (stumbleEnd - stumbleStart);

    return sin(localProgress * pi) * 0.18;
  }

  RunnerAnimation _animationFor({
    required double progress,
    required bool isWinner,
    required int frameIndex,
    required int frameCount,
    required int lane,
  }) {
    if (frameIndex == frameCount && isWinner) {
      return RunnerAnimation.celebrate;
    }

    if (frameIndex == frameCount && !isWinner) {
      return RunnerAnimation.lose;
    }

    final jumpWindowStart = 0.34 + (lane * 0.035);
    final jumpWindowEnd = jumpWindowStart + 0.12;

    if (progress >= jumpWindowStart && progress <= jumpWindowEnd) {
      return RunnerAnimation.jump;
    }

    final stumbleStart = 0.58 + (lane * 0.025);
    final stumbleEnd = stumbleStart + 0.08;

    if (progress >= stumbleStart && progress <= stumbleEnd) {
      return RunnerAnimation.stumble;
    }

    if (progress > 0.84 && isWinner) {
      return RunnerAnimation.sprint;
    }

    return RunnerAnimation.run;
  }

  double _easeOutCubic(double value) {
    final normalized = value.clamp(0.0, 1.0);
    return 1 - pow(1 - normalized, 3).toDouble();
  }

  int _seedToInt(String seed) {
    var hash = 0;

    for (final codeUnit in seed.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return hash;
  }
}
