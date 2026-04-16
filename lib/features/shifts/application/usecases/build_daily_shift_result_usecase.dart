import '../models/daily_shift_computation.dart';
import '../models/daily_shift_result.dart';
import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import '../../domain/engine/helpers/date_classification_helper.dart';
import '../../domain/engine/helpers/shift_time_helper.dart';
import '../../domain/engine/helpers/time_band_helper.dart';

class BuildDailyShiftResultUseCase {
  const BuildDailyShiftResultUseCase();

  static const double _dailyOrdinaryHoursLimit = 6.0;
  static const double _nightAllowanceRate = 4.30;

  static const double _scaloReducedDayRate = 0.31;
  static const double _scaloReducedNightRate = 0.77;
  static const double _scaloFullDayRate = 1.00;
  static const double _scaloFullNightRate = 2.50;

  DailyShiftResult execute({
    required List<Shift> shifts,
    required UserPayProfile profile,
    required Department department,
  }) {
    final sortedShifts = [...shifts]..sort((a, b) => a.start.compareTo(b.start));

    final computations = <Shift, DailyShiftComputation>{};
    double totalAmount = 0.0;
    double totalOvertimeHours = 0.0;
    double consumedOrdinaryHours = 0.0;
    double rfiBasketAmount = 0.0;
    final Map<String, double> breakdownTotals = {};

    for (final shift in sortedShifts) {
      final computation = _buildContextAwareComputation(
        shift: shift,
        profile: profile,
        department: department,
        ordinaryHoursAlreadyConsumed: consumedOrdinaryHours,
      );

      computations[shift] = computation;
      totalOvertimeHours += computation.overtimeHours;

      if (department != Department.polfer) {
        consumedOrdinaryHours += shift.hasAbsence ? 0.0 : shift.workedHours;
      }

      final normalAmount = computation.breakdown
          .where((item) => item['isBasketItem'] != true)
          .fold<double>(
            0.0,
            (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
          );

      final shiftRfiBasketAmount = computation.breakdown
          .where(
            (item) =>
                item['isBasketItem'] == true && item['basketKey'] == 'rfi',
          )
          .fold<double>(
            0.0,
            (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
          );

      totalAmount += normalAmount;
      rfiBasketAmount += shiftRfiBasketAmount;

      for (final item in computation.breakdown) {
        final label = (item['label'] as String?)?.trim();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final isBasket = item['isBasketItem'] == true;
        final basketKey = item['basketKey'];

        if (label == null || label.isEmpty) continue;

        if (isBasket && basketKey == 'rfi') {
          continue;
        }

        breakdownTotals[label] = (breakdownTotals[label] ?? 0.0) + amount;
      }
    }

    final mergedBreakdown = breakdownTotals.entries
        .map(
          (entry) => <String, dynamic>{
            'label': entry.key,
            'amount': entry.value,
          },
        )
        .toList();

    return DailyShiftResult(
      computations: computations,
      totalAmount: totalAmount,
      totalOvertimeHours: totalOvertimeHours,
      mergedBreakdown: mergedBreakdown,
      rfiBasketAmount: rfiBasketAmount,
    );
  }

  DailyShiftComputation _buildContextAwareComputation({
    required Shift shift,
    required UserPayProfile profile,
    required Department department,
    required double ordinaryHoursAlreadyConsumed,
  }) {
    if (shift.hasAbsence) {
      return const DailyShiftComputation(
        overtimeHours: 0.0,
        totalAmount: 0.0,
        extraAmount: 0.0,
        breakdown: [],
      );
    }

    final normalizedEnd = ShiftTimeHelper.normalizedEnd(shift.start, shift.end);
    final shiftWorkedHours = shift.workedHours;

    late final double ordinaryHoursForShift;
    late final double overtimeHoursForShift;

    if (department == Department.polfer) {
      final scheduledEnd = _resolvePolferScheduledEnd(shift);

      if (scheduledEnd == null) {
        final remainingOrdinaryHours =
            (_dailyOrdinaryHoursLimit - ordinaryHoursAlreadyConsumed)
                .clamp(0.0, _dailyOrdinaryHoursLimit);

        ordinaryHoursForShift = shiftWorkedHours <= remainingOrdinaryHours
            ? shiftWorkedHours
            : remainingOrdinaryHours;

        overtimeHoursForShift =
            (shiftWorkedHours - ordinaryHoursForShift).clamp(
          0.0,
          shiftWorkedHours,
        );
      } else {
        final ordinaryEnd =
            scheduledEnd.isBefore(normalizedEnd) ? scheduledEnd : normalizedEnd;

        final ordinaryMinutes = ordinaryEnd.isAfter(shift.start)
            ? ordinaryEnd.difference(shift.start).inMinutes
            : 0;

        ordinaryHoursForShift =
            (ordinaryMinutes / 60.0).clamp(0.0, shiftWorkedHours);

        overtimeHoursForShift =
            (shiftWorkedHours - ordinaryHoursForShift).clamp(
          0.0,
          shiftWorkedHours,
        );
      }
    } else {
      final remainingOrdinaryHours =
          (_dailyOrdinaryHoursLimit - ordinaryHoursAlreadyConsumed)
              .clamp(0.0, _dailyOrdinaryHoursLimit);

      ordinaryHoursForShift = shiftWorkedHours <= remainingOrdinaryHours
          ? shiftWorkedHours
          : remainingOrdinaryHours;

      overtimeHoursForShift =
          (shiftWorkedHours - ordinaryHoursForShift).clamp(
        0.0,
        shiftWorkedHours,
      );
    }

    final overtimeStart = shift.start.add(
      Duration(minutes: (ordinaryHoursForShift * 60).round()),
    );

    final ordinaryNightHours = ordinaryHoursForShift > 0
        ? TimeBandHelper.calculateNightOnlyHours(shift.start, overtimeStart)
        : 0.0;

    final overtimeSegments = overtimeHoursForShift > 0
        ? _buildOvertimeSegments(overtimeStart, normalizedEnd)
        : const <_OvertimeSegment>[];

    double overtimeDayHours = 0.0;
    double overtimeNightHours = 0.0;
    double overtimeHolidayDayHours = 0.0;
    double overtimeNightHolidayHours = 0.0;

    for (final segment in overtimeSegments) {
      if (segment.isNight && segment.isHoliday) {
        overtimeNightHolidayHours += segment.hours;
      } else if (segment.isNight) {
        overtimeNightHours += segment.hours;
      } else if (segment.isHoliday) {
        overtimeHolidayDayHours += segment.hours;
      } else {
        overtimeDayHours += segment.hours;
      }
    }

        final overtimeAmountMultiplier =
        department == Department.repartoMobile
            ? 1.0
            : _resolvedOvertimeNetMultiplier(profile);

    final overtimeDayAmount =
        overtimeDayHours * profile.overtimeDayRate * overtimeAmountMultiplier;
    final overtimeNightAmount = overtimeNightHours *
        profile.overtimeNightOrHolidayRate *
        overtimeAmountMultiplier;
    final overtimeHolidayDayAmount = overtimeHolidayDayHours *
        profile.overtimeNightOrHolidayRate *
        overtimeAmountMultiplier;
    final overtimeNightHolidayAmount = overtimeNightHolidayHours *
        profile.overtimeNightAndHolidayRate *
        overtimeAmountMultiplier;

    final ordinaryNightAmount = ordinaryNightHours * _nightAllowanceRate;

    final breakdown = <Map<String, dynamic>>[];

    if (overtimeNightHolidayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario notturno festivo (${overtimeNightHolidayHours.toStringAsFixed(1)}h × €${(profile.overtimeNightAndHolidayRate * overtimeAmountMultiplier).toStringAsFixed(2)})',
        'amount': overtimeNightHolidayAmount,
        'category': 'overtime_night_holiday',
      });
    }

    if (overtimeNightHours > 0) {
      breakdown.add({
        'label':
            'Straordinario notturno (${overtimeNightHours.toStringAsFixed(1)}h × €${(profile.overtimeNightOrHolidayRate * overtimeAmountMultiplier).toStringAsFixed(2)})',
        'amount': overtimeNightAmount,
        'category': 'overtime_night',
      });
    }

    if (overtimeHolidayDayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario festivo (${overtimeHolidayDayHours.toStringAsFixed(1)}h × €${(profile.overtimeNightOrHolidayRate * overtimeAmountMultiplier).toStringAsFixed(2)})',
        'amount': overtimeHolidayDayAmount,
        'category': 'overtime_holiday_day',
      });
    }

    if (overtimeDayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario diurno (${overtimeDayHours.toStringAsFixed(1)}h × €${(profile.overtimeDayRate * overtimeAmountMultiplier).toStringAsFixed(2)})',
        'amount': overtimeDayAmount,
        'category': 'overtime_day',
      });
    }

    if (ordinaryNightAmount > 0) {
      breakdown.add({
        'label':
            'Indennità servizio notturno (${ordinaryNightHours.toStringAsFixed(1)}h × €${_nightAllowanceRate.toStringAsFixed(2)} lordi)',
        'amount': ordinaryNightAmount,
        'category': 'ordinary_night',
      });
    }

    _appendTransitionalAccessoryItems(
      breakdown: breakdown,
      shift: shift,
      profile: profile,
      normalizedEnd: normalizedEnd,
    );

    final totalAmount = breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    final extraAmount = breakdown
        .where(
          (item) =>
              item['isBasketItem'] != true &&
              item['category'] != 'order_public',
        )
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );

    return DailyShiftComputation(
      overtimeHours: overtimeHoursForShift,
      totalAmount: totalAmount,
      extraAmount: extraAmount,
      breakdown: breakdown,
    );
  }

  void _appendTransitionalAccessoryItems({
    required List<Map<String, dynamic>> breakdown,
    required Shift shift,
    required UserPayProfile profile,
    required DateTime normalizedEnd,
  }) {
    final orderPublicAmount = shift.getOrderPublicAmount(profile);
    final externalServiceAmount = shift.getExternalServiceAmount(profile);
    final festiveAmount = shift.getFestiveAmount(profile);
    final specialHolidayAmount = shift.getSpecialHolidayAmount(profile);
    final territoryControlAmount = shift.getPolferTerritoryControlAmount(profile);
    final comfortCdgAmount = shift.getGenereDiConfortoCdgAmount(profile);
    final comfortAmount = shift.getGenereDiConfortoAmount(profile);
    final mealAmount = shift.getTicketPastoAmount(profile);
    final manualAmount = shift.getManualExtraAmount();
    final scaloAmount = _calculatePolferScaloAmount(
      shift: shift,
      normalizedEnd: normalizedEnd,
    );

    if (orderPublicAmount > 0) {
      breakdown.add({
        'label': 'Ordine pubblico ${shift.effectiveOrderPublicLabel}',
        'amount': orderPublicAmount,
        'category': 'order_public',
      });
    }

    if (externalServiceAmount > 0) {
      breakdown.add({
        'label': 'Indennità presenza servizi esterni',
        'amount': externalServiceAmount,
        'category': 'external_service',
      });
    }

    if (festiveAmount > 0) {
      breakdown.add({
        'label': 'Indennità servizio festivo',
        'amount': festiveAmount,
        'category': 'festive_service',
      });
    }

    if (specialHolidayAmount > 0) {
      breakdown.add({
        'label': 'Indennità festività particolare',
        'amount': specialHolidayAmount,
        'category': 'special_holiday',
      });
    }

    if (territoryControlAmount > 0) {
      breakdown.add({
        'label': shift.polferTerritoryControlLabel,
        'amount': territoryControlAmount,
        'category': 'polfer_territory',
      });
    }

    if (scaloAmount > 0) {
      breakdown.add({
        'label': _polferScaloLabel(shift),
        'amount': scaloAmount,
        'category': 'polfer_scalo',
        'basketKey': 'rfi',
        'isBasketItem': true,
      });
    }

        if (comfortCdgAmount > 0) {
      breakdown.add({
        'label': 'Genere di conforto CDG',
        'amount': 0.0,
        'benefitAmount': comfortCdgAmount,
        'category': 'comfort_cdg',
        'isBenefit': true,
      });
    }

    if (comfortAmount > 0) {
      breakdown.add({
        'label': 'Genere di conforto',
        'amount': 0.0,
        'benefitAmount': comfortAmount,
        'category': 'comfort',
        'isBenefit': true,
      });
    }

    if (mealAmount > 0) {
      breakdown.add({
        'label': 'Ticket pasto',
        'amount': 0.0,
        'benefitAmount': mealAmount,
        'category': 'ticket_meal',
        'isBenefit': true,
      });
    }

    if (shift.hasCompensazione) {
      breakdown.add({
        'label': 'Compensazione',
        'amount': 12.0,
        'category': 'compensazione',
      });
    }

    if (shift.hasReperibilita) {
      breakdown.add({
        'label': 'Reperibilità',
        'amount': 17.5,
        'category': 'reperibilita',
      });
    }

    if (manualAmount > 0) {
      breakdown.add({
        'label': shift.effectiveManualExtraLabel,
        'amount': manualAmount,
        'category': 'manual_extra',
      });
    }
  }

  double _resolvedOvertimeNetMultiplier(UserPayProfile profile) {
    final raw = profile.straordinarioNetMultiplier;
    if (raw.isNaN || !raw.isFinite || raw <= 0 || raw > 1) {
      return 0.67;
    }
    return raw;
  }

  DateTime? _resolvePolferScheduledEnd(Shift shift) {
    final start = shift.start;
    final startMinutes = start.hour * 60 + start.minute;

    if (startMinutes >= 360 && startMinutes <= 539) {
      return DateTime(start.year, start.month, start.day, 13, 8);
    }

    if (startMinutes >= 720 && startMinutes <= 899) {
      return DateTime(start.year, start.month, start.day, 19, 8);
    }

    if (startMinutes >= 1080 && startMinutes <= 1259) {
      return DateTime(start.year, start.month, start.day, 0, 8)
          .add(const Duration(days: 1));
    }

    if (startMinutes >= 1320 || startMinutes <= 179) {
      return DateTime(start.year, start.month, start.day, 7, 8)
          .add(const Duration(days: 1));
    }

    return null;
  }

  double _calculatePolferScaloAmount({
    required Shift shift,
    required DateTime normalizedEnd,
  }) {
    if (shift.polferScaloMode == PolferScaloMode.none) return 0.0;

    final totalNightHours = TimeBandHelper.calculateNightOnlyHours(
      shift.start,
      normalizedEnd,
    );
    final totalDayHours =
        (shift.workedHours - totalNightHours).clamp(0.0, shift.workedHours);

    final reducedDayHours = shift.polferScaloManualOverride
        ? shift.polferScaloReducedDayHours
        : shift.polferScaloMode == PolferScaloMode.ridotta
            ? totalDayHours
            : 0.0;

    final reducedNightHours = shift.polferScaloManualOverride
        ? shift.polferScaloReducedNightHours
        : shift.polferScaloMode == PolferScaloMode.ridotta
            ? totalNightHours
            : 0.0;

    final fullDayHours = shift.polferScaloManualOverride
        ? shift.polferScaloFullDayHours
        : shift.polferScaloMode == PolferScaloMode.intera
            ? totalDayHours
            : 0.0;

    final fullNightHours = shift.polferScaloManualOverride
        ? shift.polferScaloFullNightHours
        : shift.polferScaloMode == PolferScaloMode.intera
            ? totalNightHours
            : 0.0;

    return (reducedDayHours * _scaloReducedDayRate) +
        (reducedNightHours * _scaloReducedNightRate) +
        (fullDayHours * _scaloFullDayRate) +
        (fullNightHours * _scaloFullNightRate);
  }

  String _polferScaloLabel(Shift shift) {
    final hasReduced = shift.polferScaloReducedDayHours > 0 ||
        shift.polferScaloReducedNightHours > 0 ||
        (!shift.polferScaloManualOverride &&
            shift.polferScaloMode == PolferScaloMode.ridotta);

    final hasFull = shift.polferScaloFullDayHours > 0 ||
        shift.polferScaloFullNightHours > 0 ||
        (!shift.polferScaloManualOverride &&
            shift.polferScaloMode == PolferScaloMode.intera);

    if (shift.polferScaloManualOverride && hasReduced && hasFull) {
      return 'Scalo ferroviario misto (basket RFI)';
    }

    if (hasReduced && !hasFull) {
      return shift.polferScaloManualOverride
          ? 'Scalo ferroviario ridotto (manuale • basket RFI)'
          : 'Scalo ferroviario ridotto (basket RFI)';
    }

    if (hasFull && !hasReduced) {
      return shift.polferScaloManualOverride
          ? 'Scalo ferroviario intero (manuale • basket RFI)'
          : 'Scalo ferroviario intero (basket RFI)';
    }

    return 'Scalo ferroviario (basket RFI)';
  }

  List<_OvertimeSegment> _buildOvertimeSegments(
    DateTime overtimeStart,
    DateTime overtimeEnd,
  ) {
    if (!overtimeEnd.isAfter(overtimeStart)) return const [];

    final segments = <_OvertimeSegment>[];
    var cursor = overtimeStart;

    while (cursor.isBefore(overtimeEnd)) {
      final next = TimeBandHelper.nextBoundary(cursor, overtimeEnd);
      final minutes = next.difference(cursor).inMinutes;

      if (minutes > 0) {
        segments.add(
          _OvertimeSegment(
            hours: minutes / 60.0,
            isNight: TimeBandHelper.isNightMoment(cursor),
            isHoliday: DateClassificationHelper.isHolidayDate(cursor),
          ),
        );
      }

      cursor = next;
    }

    return segments;
  }
}

class _OvertimeSegment {
  final double hours;
  final bool isNight;
  final bool isHoliday;

  const _OvertimeSegment({
    required this.hours,
    required this.isNight,
    required this.isHoliday,
  });
}