import 'dart:math';

import '../models/challenge_runner.dart';
import 'challenge_frame.dart';

class ChallengeEngine {
  const ChallengeEngine();

  List<ChallengeFrame> buildRace({
    required List<ChallengeRunner> runners,
    required String selectedPayerId,
    required String roundSeed,
    int frameCount = 36,
    Duration frameDuration = const Duration(milliseconds: 120),
  }) {
    if (runners.isEmpty) {
      return const [];
    }

    final random = Random(_seedToInt(roundSeed));
    final frames = <ChallengeFrame>[];

    for (var frameIndex = 0; frameIndex <= frameCount; frameIndex++) {
      final progress = frameIndex / frameCount;
      final runnerFrames = <ChallengeRunnerFrame>[];

      for (final runner in runners) {
        final isWinner = runner.id == selectedPayerId;
        final noise = (random.nextDouble() - 0.5) * 0.10;
        final wave = sin((progress * pi * 2) + runner.lane) * 0.04;

        final basePosition = isWinner
            ? _winnerProgress(progress)
            : _competitorProgress(progress, runner.lane);

        final position = (basePosition + noise + wave).clamp(
          0.0,
          isWinner ? 1.0 : 0.94,
        );

        runnerFrames.add(
          ChallengeRunnerFrame(
            runnerId: runner.id,
            position: frameIndex == frameCount && isWinner ? 1.0 : position,
          ),
        );
      }

      frames.add(
        ChallengeFrame(
          index: frameIndex,
          elapsed: frameDuration * frameIndex,
          runners: runnerFrames,
        ),
      );
    }

    return frames;
  }

  double _winnerProgress(double progress) {
    if (progress < 0.70) {
      return progress * 0.78;
    }

    final finalProgress = (progress - 0.70) / 0.30;
    return 0.55 + (finalProgress * 0.45);
  }

  double _competitorProgress(double progress, int lane) {
    final lanePenalty = (lane % 3) * 0.025;

    if (progress < 0.75) {
      return (progress * 0.82) - lanePenalty;
    }

    final finalProgress = (progress - 0.75) / 0.25;
    return 0.62 + (finalProgress * 0.28) - lanePenalty;
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
