import 'package:flutter/material.dart';

class MonthCalendarDayData {
  final DateTime date;
  final bool isInCurrentMonth;
  final double amount;
  final bool isSelected;
  final bool isToday;

  const MonthCalendarDayData({
    required this.date,
    required this.isInCurrentMonth,
    required this.amount,
    required this.isSelected,
    required this.isToday,
  });
}

class MonthCalendarCard extends StatelessWidget {
  final DateTime month;
  final List<MonthCalendarDayData> days;
  final ValueChanged<DateTime> onDayTap;

  const MonthCalendarCard({
    super.key,
    required this.month,
    required this.days,
    required this.onDayTap,
  });

  String _monthLabel(DateTime date) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _amountLabel(double amount) {
    if (amount <= 0) return '';
    if (amount >= 100) return '€ ${amount.toStringAsFixed(0)}';
    if (amount >= 10) return '€ ${amount.toStringAsFixed(1)}';
    return '€ ${amount.toStringAsFixed(2)}';
  }

  _AmountStyle _amountStyle(double amount) {
    if (amount <= 0) {
      return const _AmountStyle(
        background: Colors.transparent,
        text: Colors.transparent,
        border: Colors.transparent,
      );
    }

    if (amount < 15) {
      return const _AmountStyle(
        background: Color(0xFF2A2F3A),
        text: Color(0xFFD1D5DB),
        border: Color(0xFF3A4150),
      );
    }

    if (amount < 30) {
      return const _AmountStyle(
        background: Color(0xFF0F3A2A),
        text: Color(0xFF4ADE80),
        border: Color(0xFF166534),
      );
    }

    if (amount < 70) {
      return const _AmountStyle(
        background: Color(0xFF0B3B4F),
        text: Color(0xFF38BDF8),
        border: Color(0xFF0EA5E9),
      );
    }

    return const _AmountStyle(
      background: Color(0xFF4A3410),
      text: Color(0xFFFBBF24),
      border: Color(0xFFF59E0B),
    );
  }

  Color _cellBackground(MonthCalendarDayData day) {
    if (day.isSelected) {
      return const Color(0xFF0F3A2A);
    }

    if (!day.isInCurrentMonth) {
      return const Color(0xFF151922);
    }

    if (day.amount >= 70) {
      return const Color(0xFF1B2430);
    }

    if (day.amount >= 30) {
      return const Color(0xFF18212C);
    }

    return const Color(0xFF171C26);
  }

  Color _cellBorder(MonthCalendarDayData day) {
    if (day.isSelected) {
      return const Color(0xFF22C55E);
    }

    if (day.isToday) {
      return const Color(0xFF3B82F6);
    }

    if (!day.isInCurrentMonth) {
      return Colors.white10;
    }

    return const Color(0xFF2A3140);
  }

  Color _dayTextColor(MonthCalendarDayData day) {
    if (!day.isInCurrentMonth) {
      return Colors.white30;
    }

    if (day.isSelected) {
      return Colors.white;
    }

    return Colors.white.withOpacity(0.92);
  }

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthLabel(month),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (index) {
              final isSaturday = index == 5;
              final isSunday = index == 6;

              Color color = Colors.white54;
              if (isSaturday) color = const Color(0xFF60A5FA);
              if (isSunday) color = const Color(0xFFF87171);

              return Expanded(
                child: Center(
                  child: Text(
                    weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final amountStyle = _amountStyle(day.amount);
              final amountLabel = _amountLabel(day.amount);

              return GestureDetector(
                onTap: () => onDayTap(day.date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _cellBackground(day),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _cellBorder(day),
                      width: day.isSelected ? 1.4 : 1,
                    ),
                    boxShadow: day.isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.18),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          '${day.date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dayTextColor(day),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (amountLabel.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 18,
                            minWidth: 26,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: amountStyle.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: amountStyle.border,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              amountLabel,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: amountStyle.text,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _LegendChip(
                label: '0€',
                background: Color(0xFF2A2F3A),
                text: Color(0xFFD1D5DB),
                border: Color(0xFF3A4150),
              ),
              _LegendChip(
                label: '15€+',
                background: Color(0xFF0F3A2A),
                text: Color(0xFF4ADE80),
                border: Color(0xFF166534),
              ),
              _LegendChip(
                label: '30€+',
                background: Color(0xFF0B3B4F),
                text: Color(0xFF38BDF8),
                border: Color(0xFF0EA5E9),
              ),
              _LegendChip(
                label: '70€+',
                background: Color(0xFF4A3410),
                text: Color(0xFFFBBF24),
                border: Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color text;
  final Color border;

  const _LegendChip({
    required this.label,
    required this.background,
    required this.text,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

class _AmountStyle {
  final Color background;
  final Color text;
  final Color border;

  const _AmountStyle({
    required this.background,
    required this.text,
    required this.border,
  });
}