import 'package:flutter/material.dart';

class ChallengeCountdown extends StatelessWidget {
  final int value;

  const ChallengeCountdown({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Text(
          '$value',
          key: ValueKey(value),
          style: const TextStyle(
            fontSize: 86,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
      ),
    );
  }
}
