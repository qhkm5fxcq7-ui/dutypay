import 'package:flutter/material.dart';

class ChallengeResult extends StatelessWidget {
  final String resultText;

  const ChallengeResult({
    super.key,
    required this.resultText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '☕',
              style: TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 14),
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
