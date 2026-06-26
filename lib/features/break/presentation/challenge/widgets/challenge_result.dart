import 'package:flutter/material.dart';

class ChallengeResult extends StatelessWidget {
  final String resultText;

  const ChallengeResult({
    super.key,
    required this.resultText,
  });

  @override
  Widget build(BuildContext context) {
    final payerName = _extractPayerName(resultText);
    final punchline = _punchlineFor(payerName);

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
              '😂',
              style: TextStyle(fontSize: 58),
            ),
            const SizedBox(height: 12),
            Text(
              'Oggi offre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedScale(
              duration: const Duration(milliseconds: 260),
              scale: 1,
              child: Text(
                payerName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              punchline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractPayerName(String value) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return value.trim();
    }

    final name = parts.last.trim();

    if (name.isEmpty) {
      return value.trim();
    }

    return name;
  }

  String _punchlineFor(String payerName) {
    final normalized = payerName.trim().toLowerCase();
    final index = normalized.codeUnits.fold<int>(
          0,
          (sum, value) => sum + value,
        ) %
        _punchlines.length;

    return _punchlines[index];
  }

  static const _punchlines = [
    'Il barista è stato avvisato.',
    'I colleghi ringraziano.',
    'Pagamento inevitabile.',
    'La pausa è servita.',
    'Missione caffè assegnata.',
    'Il gruppo approva.',
  ];
}
