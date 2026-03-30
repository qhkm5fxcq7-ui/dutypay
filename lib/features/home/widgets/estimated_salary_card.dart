import 'package:flutter/material.dart';

class EstimatedSalaryCard extends StatelessWidget {
  final double baseNet;
  final double extraNet;
  final double extraGross;
  final double taxes;
  final String monthLabel;
  final int workedDays;
  final int totalDays;
  final double avgPerDay;
  final double projectedTotal;

  const EstimatedSalaryCard({
    super.key,
    required this.baseNet,
    required this.extraNet,
    required this.extraGross,
    required this.taxes,
    required this.monthLabel,
    required this.workedDays,
    required this.totalDays,
    required this.avgPerDay,
    required this.projectedTotal,
  });

  @override
  Widget build(BuildContext context) {
    final total = baseNet + extraNet;
    final safeTaxes = taxes.abs() < 0.005 ? 0.0 : taxes;
    final hasWorkedDays = workedDays > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Proiezione mese',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      label: 'ORA',
                      textColor: const Color(0xFF4ADE80),
                      backgroundColor: const Color(0xFF22C55E).withOpacity(0.12),
                    ),
                  ],
                ),
              ),
              Text(
                monthLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Soldi che stai accumulando con i turni di questo mese',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '€ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 18),
          _row('Quota fissa netta', baseNet),
          _row('Extra netti', extraNet, valueColor: const Color(0xFF4ADE80)),
          _row('Extra lordi', extraGross),
          _row(
            'Tasse stimate',
            safeTaxes == 0.0 ? 0.0 : -safeTaxes,
            valueColor: const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 16),
          if (hasWorkedDays) ...[
            Text(
              '$workedDays giorno${workedDays == 1 ? '' : 'i'} lavorato${workedDays == 1 ? '' : 'i'} su $totalDays',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Media giornaliera: € ${avgPerDay.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Proiezione fine mese: € ${projectedTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF22C55E),
              ),
            ),
          ] else ...[
            Text(
              'Nessun turno inserito per questo mese',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.70),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Basata sui turni inseriti',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _row(String label, double value, {Color? valueColor}) {
    final displayValue = value.abs() < 0.005 ? 0.0 : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '€ ${displayValue.toStringAsFixed(2)}',
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}