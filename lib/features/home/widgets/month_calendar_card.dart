import 'package:flutter/material.dart';

class MonthCalendarDayData {
  final DateTime date;
  final bool isInCurrentMonth;
  final double amount;
  final bool isSelected;
  final bool isToday;
  final String? absenceBadge;
  final bool hasTicket;
  final bool hasConforto;

  /// Previsione SPMN visiva, separata dai turni reali.
  /// Esempi: SERA, POM, MAT, NOTTE, SMONT, RIP, AGG
  final String? predictedSpmnLabel;

  const MonthCalendarDayData({
    required this.date,
    required this.isInCurrentMonth,
    required this.amount,
    required this.isSelected,
    required this.isToday,
    this.absenceBadge,
    this.hasTicket = false,
    this.hasConforto = false,
    this.predictedSpmnLabel,
  });

  bool get hasAmount => amount > 0;

  bool get hasAbsence =>
      absenceBadge != null && absenceBadge!.trim().isNotEmpty;

  bool get hasPredictedSpmn =>
      predictedSpmnLabel != null && predictedSpmnLabel!.trim().isNotEmpty;

  bool get hasContent => hasAmount || hasAbsence;
}

class MonthCalendarCard extends StatelessWidget {
  final DateTime month;
  final List<MonthCalendarDayData> days;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback? onOpenMonthNotes;

  final int ticketPastoCount;
  final int genereDiConfortoCount;
  final double ticketPastoTotal;
  final double genereDiConfortoTotal;
  final double totalOvertimeHours;

  const MonthCalendarCard({
    super.key,
    required this.month,
    required this.days,
    required this.onDayTap,
    this.onOpenMonthNotes,
    this.ticketPastoCount = 0,
    this.genereDiConfortoCount = 0,
    this.ticketPastoTotal = 0.0,
    this.genereDiConfortoTotal = 0.0,
    this.totalOvertimeHours = 0.0,
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

  double _monthlyTotal() {
    return days
        .where((d) => d.isInCurrentMonth)
        .fold<double>(0, (sum, d) => sum + d.amount);
  }

  int _workedDaysCount() {
    return days.where((d) => d.isInCurrentMonth && d.hasContent).length;
  }

  int _predictedDaysCount() {
    return days
        .where(
          (d) => d.isInCurrentMonth && !d.hasContent && d.hasPredictedSpmn,
        )
        .length;
  }

  String _normalizedAbsenceLabel(String? badge) {
    final value = (badge ?? '').trim().toUpperCase();

    switch (value) {
      case 'FERIE':
      case 'C.O':
      case 'C.O.':
        return 'C.O.';
      case 'MAL':
      case 'MALATTIA':
      case 'C.S':
      case 'C.S.':
        return 'C.S.';
      case 'RIP':
      case 'RIPOSO':
        return 'RIP';
      default:
        return value;
    }
  }

  String _normalizedPredictedLabel(String? label) {
    final value = (label ?? '').trim().toUpperCase();

    switch (value) {
      case 'SERA':
        return 'SERA';
      case 'POMERIGGIO':
      case 'POM':
        return 'POM';
      case 'MATTINA':
      case 'MAT':
        return 'MAT';
      case 'NOTTE':
        return 'NOTTE';
      case 'SMONTANTE':
      case 'SMONT':
        return 'SMONT';
      case 'RIPOSO':
      case 'RIP':
        return 'RIP';
      case 'AGGIORNAMENTO':
      case 'AGG':
        return 'AGG';
      default:
        return value;
    }
  }

  _BadgeStyle? _badgeStyle(String? badge) {
    final value = _normalizedAbsenceLabel(badge);
    if (value.isEmpty) return null;

    switch (value) {
      case 'C.O.':
        return const _BadgeStyle(
          background: Color(0xFF3A1717),
          text: Color(0xFFFFB3B3),
          border: Color(0xFFE35D5D),
        );
      case 'C.S.':
        return const _BadgeStyle(
          background: Color(0xFF311846),
          text: Color(0xFFE8C7FF),
          border: Color(0xFFB26AF8),
        );
      case 'RIP':
        return const _BadgeStyle(
          background: Color(0xFF1E2E16),
          text: Color(0xFFDDF7A5),
          border: Color(0xFF9ACF38),
        );
      default:
        return const _BadgeStyle(
          background: Color(0xFF202834),
          text: Color(0xFFD3DBE6),
          border: Color(0xFF334152),
        );
    }
  }

  _BadgeStyle? _predictedBadgeStyle(String? label) {
    final value = _normalizedPredictedLabel(label);
    if (value.isEmpty) return null;

    switch (value) {
      case 'SERA':
        return const _BadgeStyle(
          background: Color(0xFF14283A),
          text: Color(0xFF9AD9FF),
          border: Color(0xFF67B7FF),
        );
      case 'POM':
        return const _BadgeStyle(
          background: Color(0xFF2C2415),
          text: Color(0xFFFFD98A),
          border: Color(0xFFFFC14D),
        );
      case 'MAT':
        return const _BadgeStyle(
          background: Color(0xFF173124),
          text: Color(0xFFB6F3D3),
          border: Color(0xFF5CE1A8),
        );
      case 'NOTTE':
        return const _BadgeStyle(
          background: Color(0xFF24193C),
          text: Color(0xFFD9C2FF),
          border: Color(0xFF9D7BFF),
        );
      case 'SMONT':
        return const _BadgeStyle(
          background: Color(0xFF1E2631),
          text: Color(0xFFD3DBE6),
          border: Color(0xFF5E738C),
        );
      case 'RIP':
        return const _BadgeStyle(
          background: Color(0xFF1E2E16),
          text: Color(0xFFDDF7A5),
          border: Color(0xFF9ACF38),
        );
      case 'AGG':
        return const _BadgeStyle(
          background: Color(0xFF1C2F1E),
          text: Color(0xFFB8F7C2),
          border: Color(0xFF56D88D),
        );
      default:
        return const _BadgeStyle(
          background: Color(0xFF202834),
          text: Color(0xFFD3DBE6),
          border: Color(0xFF334152),
        );
    }
  }

  Color _cellBackground(MonthCalendarDayData day) {
    if (day.isSelected) return const Color(0xFF132A22);
    if (!day.isInCurrentMonth) return const Color(0xFF111720);
    if (day.hasAbsence) return const Color(0xFF161D27);
    if (!day.hasContent && day.hasPredictedSpmn) return const Color(0xFF131B24);
    return const Color(0xFF141C26);
  }

  Color _cellBorder(MonthCalendarDayData day) {
    if (day.isSelected) return const Color(0xFF5CE1A8);
    if (day.isToday) return const Color(0xFF67B7FF);
    if (!day.isInCurrentMonth) return const Color(0xFF202A37);
    if (day.hasAbsence) return const Color(0xFF324050);
    if (!day.hasContent && day.hasPredictedSpmn) {
      return const Color(0xFF355066);
    }
    if (day.hasAmount || day.hasTicket || day.hasConforto) {
      return const Color(0xFF2A5A47);
    }
    return const Color(0xFF253140);
  }

  Color _dayTextColor(MonthCalendarDayData day) {
    if (!day.isInCurrentMonth) return const Color(0xFF556274);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    final monthTotal = _monthlyTotal();
    final workedDays = _workedDaysCount();
    final predictedDays = _predictedDaysCount();
    final benefitTotal = ticketPastoTotal + genereDiConfortoTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.grid_view_rounded,
              size: 18,
              color: _CalendarPalette.info,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _monthLabel(month),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            InkWell(
              onTap: onOpenMonthNotes,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _CalendarPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _CalendarPalette.cardBorder),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: _CalendarPalette.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tocca un giorno per vedere subito i turni inseriti e il totale maturato. I preset SPMN previsti sono mostrati solo come anteprima.',
          style: TextStyle(
            fontSize: 13.4,
            color: _CalendarPalette.textSecondary,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _CalendarPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _CalendarPalette.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Totale mese',
                      value: '€ ${_formatMoney(monthTotal)}',
                      valueColor: const Color(0xFF5CE1A8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Giorni con attività',
                      value: '$workedDays',
                      valueColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Ticket 7€',
                      value:
                          '$ticketPastoCount • € ${_formatMoney(ticketPastoTotal)}',
                      valueColor: const Color(0xFF67B7FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Conforto 1,02€',
                      value:
                          '$genereDiConfortoCount • € ${_formatMoney(genereDiConfortoTotal)}',
                      valueColor: const Color(0xFFFFC14D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Benefit mese',
                      value: '€ ${_formatMoney(benefitTotal)}',
                      valueColor: const Color(0xFF9AD9FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Straordinario',
                      value: '${totalOvertimeHours.toStringAsFixed(1)} h',
                      valueColor: const Color(0xFF5CE1A8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TopInfoBlock(
                      label: 'Previsione SPMN',
                      value: '$predictedDays giorni',
                      valueColor: const Color(0xFF9AD9FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _TopInfoBlock(
                      label: 'Legenda',
                      value: 'reale > previsto',
                      valueColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: _CalendarPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CalendarPalette.cardBorder),
          ),
          child: Row(
            children: List.generate(7, (index) {
              final isSaturday = index == 5;
              final isSunday = index == 6;

              Color color = _CalendarPalette.textSecondary;
              if (isSaturday) color = const Color(0xFF7DBFFF);
              if (isSunday) color = const Color(0xFFFF9C9C);

              return Expanded(
                child: Center(
                  child: Text(
                    weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final normalizedBadge = _normalizedAbsenceLabel(day.absenceBadge);
            final badgeStyle = _badgeStyle(day.absenceBadge);
            final predictedLabel =
                _normalizedPredictedLabel(day.predictedSpmnLabel);
            final predictedStyle = _predictedBadgeStyle(day.predictedSpmnLabel);

            return InkWell(
              onTap: () => onDayTap(day.date),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                decoration: BoxDecoration(
                  color: _cellBackground(day),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _cellBorder(day),
                    width: day.isSelected ? 1.8 : 1.1,
                  ),
                  boxShadow: day.isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF5CE1A8).withOpacity(0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: _dayTextColor(day),
                      ),
                    ),
                    const Spacer(),
                    if (day.hasAbsence && badgeStyle != null)
                      SizedBox(
                        width: double.infinity,
                        height: 24,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeStyle.background,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: badgeStyle.border,
                                width: 1.1,
                              ),
                            ),
                            child: Text(
                              normalizedBadge,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9.2,
                                fontWeight: FontWeight.w900,
                                color: badgeStyle.text,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (!day.hasContent &&
                        day.hasPredictedSpmn &&
                        predictedStyle != null)
                      SizedBox(
                        width: double.infinity,
                        height: 24,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: predictedStyle.background,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: predictedStyle.border,
                                width: 1.1,
                              ),
                            ),
                            child: Text(
                              predictedLabel,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                color: predictedStyle.text,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (day.hasTicket || day.hasConforto)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (day.hasTicket)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF67B7FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (day.hasConforto) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFC14D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 4),
                      if (day.hasAmount)
                        Container(
                          width: 26,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5CE1A8),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF5CE1A8).withOpacity(0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final isNegative = integer.startsWith('-');
    final digits = isNegative ? integer.substring(1) : integer;

    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }

    final formattedInt = buffer.toString().split('').reversed.join();
    return '${isNegative ? '-' : ''}$formattedInt,$decimal';
  }
}

class _TopInfoBlock extends StatelessWidget {
  const _TopInfoBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF253140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: _CalendarPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  final Color background;
  final Color text;
  final Color border;

  const _BadgeStyle({
    required this.background,
    required this.text,
    required this.border,
  });
}

class _CalendarPalette {
  static const surface = Color(0xFF18212C);
  static const cardBorder = Color(0xFF253140);
  static const textSecondary = Color(0xFF9AA8B7);
  static const info = Color(0xFF67B7FF);
}