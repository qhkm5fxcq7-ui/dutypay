import 'package:flutter/material.dart';

import '../engine/challenge_frame.dart';
import '../models/challenge_runner.dart';

class ChallengeTrack extends StatelessWidget {
  final List<ChallengeRunner> runners;

  const ChallengeTrack({
    super.key,
    required this.runners,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '☕ Operazione Caffè',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gli agenti corrono verso il traguardo...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          ...runners.map(_RunnerLane.new),
        ],
      ),
    );
  }
}

class _RunnerLane extends StatelessWidget {
  final ChallengeRunner runner;

  const _RunnerLane(this.runner);

  @override
  Widget build(BuildContext context) {
    final progress = runner.position.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            runner.displayName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CustomPaint(
                    painter: _LaneMarksPainter(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    const SizedBox(width: 92),
                    _Obstacle(label: '🚧', visible: runner.lane.isEven),
                    const Spacer(),
                    _Obstacle(label: '🟧', visible: runner.lane.isOdd),
                    const Spacer(),
                    _Obstacle(label: '☕', visible: true),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      '🏁',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: _curveFor(runner.animation),
                alignment: Alignment(
                  -1 + (progress * 1.82),
                  0,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: -7,
                        child: Container(
                          width: 24,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -runner.jumpHeight),
                        child: Transform.rotate(
                          angle: runner.rotation,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 115),
                            scale: _scaleFor(runner.animation),
                            child: Text(
                              _runnerIcon(runner.animation),
                              style: const TextStyle(fontSize: 29),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Curve _curveFor(RunnerAnimation animation) {
    switch (animation) {
      case RunnerAnimation.sprint:
      case RunnerAnimation.celebrate:
        return Curves.easeOutBack;
      case RunnerAnimation.stumble:
      case RunnerAnimation.lose:
        return Curves.easeInOutCubic;
      case RunnerAnimation.jump:
        return Curves.easeOutQuad;
      case RunnerAnimation.idle:
      case RunnerAnimation.run:
        return Curves.easeOutCubic;
    }
  }

  double _scaleFor(RunnerAnimation animation) {
    switch (animation) {
      case RunnerAnimation.sprint:
        return 1.12;
      case RunnerAnimation.jump:
        return 1.08;
      case RunnerAnimation.stumble:
        return 0.94;
      case RunnerAnimation.celebrate:
        return 1.18;
      case RunnerAnimation.lose:
        return 0.92;
      case RunnerAnimation.idle:
      case RunnerAnimation.run:
        return 1;
    }
  }

  String _runnerIcon(RunnerAnimation animation) {
    switch (animation) {
      case RunnerAnimation.sprint:
        return '👮‍♂️💨';
      case RunnerAnimation.jump:
        return '👮‍♂️';
      case RunnerAnimation.stumble:
        return '🫨';
      case RunnerAnimation.celebrate:
        return '👮‍♂️🎉';
      case RunnerAnimation.lose:
        return '😵‍💫';
      case RunnerAnimation.idle:
      case RunnerAnimation.run:
        return '👮‍♂️';
    }
  }
}

class _Obstacle extends StatelessWidget {
  final String label;
  final bool visible;

  const _Obstacle({
    required this.label,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: visible ? 0.78 : 0,
      child: Text(
        label,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class _LaneMarksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 8.0;
    const dashSpace = 8.0;
    final y = size.height / 2;

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashWidth).clamp(0.0, size.width), y),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
