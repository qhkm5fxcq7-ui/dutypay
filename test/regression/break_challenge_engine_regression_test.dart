import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/break/domain/models/break_participant.dart';
import 'package:dutypay/features/break/presentation/challenge/engine/challenge_engine.dart';
import 'package:dutypay/features/break/presentation/challenge/engine/challenge_frame.dart';
import 'package:dutypay/features/break/presentation/challenge/models/challenge_runner.dart';

void main() {
  const engine = ChallengeEngine();

  List<ChallengeRunner> runners({
    String selectedPayerId = 'p2',
  }) {
    final participants = [
      BreakParticipant(
        id: 'p1',
        roomId: 'room_1',
        displayName: 'Mario',
        joinedAt: DateTime(2026, 6, 1, 10, 0),
        avatarSeed: 'a1',
        deviceId: 'd1',
      ),
      BreakParticipant(
        id: 'p2',
        roomId: 'room_1',
        displayName: 'Luigi',
        joinedAt: DateTime(2026, 6, 1, 10, 1),
        avatarSeed: 'a2',
        deviceId: 'd2',
      ),
      BreakParticipant(
        id: 'p3',
        roomId: 'room_1',
        displayName: 'Anna',
        joinedAt: DateTime(2026, 6, 1, 10, 2),
        avatarSeed: 'a3',
        deviceId: 'd3',
      ),
    ];

    return [
      for (var i = 0; i < participants.length; i++)
        ChallengeRunner.fromParticipant(
          participant: participants[i],
          lane: i,
          selectedPayerId: selectedPayerId,
        ),
    ];
  }

  group('Break ChallengeEngine regression', () {
    test('empty runners produce no frames', () {
      final frames = engine.buildRace(
        runners: const [],
        selectedPayerId: 'p1',
        roundSeed: 'seed',
      );

      expect(frames, isEmpty);
    });

    test('buildRace produces frameCount plus initial frame', () {
      final frames = engine.buildRace(
        runners: runners(),
        selectedPayerId: 'p2',
        roundSeed: 'seed_123',
        frameCount: 10,
        frameDuration: const Duration(milliseconds: 100),
      );

      expect(frames.length, 11);
      expect(frames.first.index, 0);
      expect(frames.last.index, 10);
      expect(frames.first.elapsed, Duration.zero);
      expect(frames.last.elapsed, const Duration(milliseconds: 1000));
    });

    test('winner reaches finish line in final frame', () {
      final frames = engine.buildRace(
        runners: runners(selectedPayerId: 'p2'),
        selectedPayerId: 'p2',
        roundSeed: 'seed_123',
      );

      final finalFrame = frames.last;
      final winner = finalFrame.runners.firstWhere(
        (runner) => runner.runnerId == 'p2',
      );

      expect(winner.position, closeTo(1.0, 0.0001));
      expect(winner.animation, RunnerAnimation.celebrate);
    });

    test('non winners do not reach finish line in final frame', () {
      final frames = engine.buildRace(
        runners: runners(selectedPayerId: 'p2'),
        selectedPayerId: 'p2',
        roundSeed: 'seed_123',
      );

      final finalFrame = frames.last;
      final losers = finalFrame.runners.where(
        (runner) => runner.runnerId != 'p2',
      );

      for (final loser in losers) {
        expect(loser.position, lessThan(1.0));
        expect(loser.animation, RunnerAnimation.lose);
      }
    });

    test('same seed and same runners produce deterministic frames', () {
      final first = engine.buildRace(
        runners: runners(selectedPayerId: 'p2'),
        selectedPayerId: 'p2',
        roundSeed: 'seed_123',
        frameCount: 12,
      );

      final second = engine.buildRace(
        runners: runners(selectedPayerId: 'p2'),
        selectedPayerId: 'p2',
        roundSeed: 'seed_123',
        frameCount: 12,
      );

      expect(second.length, first.length);

      for (var frameIndex = 0; frameIndex < first.length; frameIndex++) {
        final a = first[frameIndex];
        final b = second[frameIndex];

        expect(b.index, a.index);
        expect(b.elapsed, a.elapsed);
        expect(b.cameraZoom, closeTo(a.cameraZoom, 0.0001));
        expect(b.cameraShake, closeTo(a.cameraShake, 0.0001));
        expect(b.runners.length, a.runners.length);

        for (var runnerIndex = 0;
            runnerIndex < a.runners.length;
            runnerIndex++) {
          final ar = a.runners[runnerIndex];
          final br = b.runners[runnerIndex];

          expect(br.runnerId, ar.runnerId);
          expect(br.lane, ar.lane);
          expect(br.position, closeTo(ar.position, 0.0001));
          expect(br.speed, closeTo(ar.speed, 0.0001));
          expect(br.jumpHeight, closeTo(ar.jumpHeight, 0.0001));
          expect(br.rotation, closeTo(ar.rotation, 0.0001));
          expect(br.animation, ar.animation);
        }
      }
    });

    test('different selected payer changes final winner', () {
      final frames = engine.buildRace(
        runners: runners(selectedPayerId: 'p3'),
        selectedPayerId: 'p3',
        roundSeed: 'seed_123',
      );

      final finalFrame = frames.last;
      final winner = finalFrame.runners.firstWhere(
        (runner) => runner.runnerId == 'p3',
      );

      expect(winner.position, closeTo(1.0, 0.0001));
      expect(winner.animation, RunnerAnimation.celebrate);
    });

    test('all generated runner positions stay inside valid range', () {
      final frames = engine.buildRace(
        runners: runners(selectedPayerId: 'p1'),
        selectedPayerId: 'p1',
        roundSeed: 'seed_range',
        frameCount: 42,
      );

      for (final frame in frames) {
        for (final runner in frame.runners) {
          expect(runner.position, greaterThanOrEqualTo(0));
          expect(runner.position, lessThanOrEqualTo(1));
          expect(runner.speed, greaterThan(0));
        }
      }
    });

    test('final frames enable camera shake only near the end', () {
      final frames = engine.buildRace(
        runners: runners(),
        selectedPayerId: 'p2',
        roundSeed: 'seed_camera',
        frameCount: 20,
      );

      expect(frames.first.cameraShake, closeTo(0, 0.0001));
      expect(frames.last.cameraShake, greaterThan(0));
    });
  });
}
