import 'package:flutter/material.dart';

class PayslipComparisonCard extends StatelessWidget {
  final String monthLabel;
  final double realNet;
  final double estimatedNet;

  const PayslipComparisonCard({
    super.key,
    required this.monthLabel,
    required this.realNet,
    required this.estimatedNet,
  });

  double get delta => estimatedNet - realNet;

  double get accuracyPercentage {
    if (realNet <= 0) return 0;
    final diff = (estimatedNet - realNet).abs();
    final accuracy = 100 - ((diff / realNet) * 100);
    if (accuracy < 0) return 0;
    if (accuracy > 100) return 100;
    return accuracy;
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(2);
  }

  Color get deltaColor {
    if (delta.abs() < 15) return const Color(0xFF22C55E);
    if (delta.abs() < 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get deltaLabel {
    if (delta > 0) {
      return '+€ ${_formatMoney(delta)}';
    }
    if (delta < 0) {
      return '-€ ${_formatMoney(delta.abs())}';
    }
    return '€ 0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confronto reale vs stimato',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ValueBox(
                  label: 'Cedolino reale',
                  value: '€ ${_formatMoney(realNet)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBox(
                  label: 'Cedolino stimato',
                  value: '€ ${_formatMoney(estimatedNet)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ValueBox(
                  label: 'Scostamento',
                  value: deltaLabel,
                  valueColor: deltaColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBox(
                  label: 'Precisione',
                  value: '${accuracyPercentage.toStringAsFixed(1)}%',
                  valueColor: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ValueBox({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}