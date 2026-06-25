import 'package:flutter/material.dart';

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
            '🏁 Gara a ostacoli',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 26),
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
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
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
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                  -1 + (progress * 1.82),
                  0,
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '👮‍♂️',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
