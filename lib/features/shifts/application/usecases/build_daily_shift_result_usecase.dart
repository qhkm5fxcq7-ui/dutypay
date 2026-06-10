import '../models/daily_shift_computation.dart';
import '../models/daily_shift_result.dart';
import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import '../../domain/engine/helpers/date_classification_helper.dart';
import '../../domain/engine/helpers/shift_time_helper.dart';
import '../../domain/engine/helpers/time_band_helper.dart';
import 'build_shift_computation_usecase.dart';

class BuildDailyShiftResultUseCase {
  final BuildShiftComputationUseCase _buildShiftComputationUseCase;

  const BuildDailyShiftResultUseCase({
    BuildShiftComputationUseCase buildShiftComputationUseCase =
        const BuildShiftComputationUseCase(),
  }) : _buildShiftComputationUseCase = buildShiftComputationUseCase;

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
    double consumedPayableOvertimeHours = 0.0;
    double rfiBasketAmount = 0.0;
    double compensativeHours = 0.0;
double compensativeGrossEstimate = 0.0;
    final Map<String, double> breakdownTotals = {};

    final overtimeMonthlyLimit = _sanitizeHours(
      profile.monthlyOvertimePayableHoursLimit,
    );

    for (final shift in sortedShifts) {
      final rawComputation = _buildContextAwareComputation(
        shift: shift,
        profile: profile,
        department: department,
        ordinaryHoursAlreadyConsumed: consumedOrdinaryHours,
      );

      final computation = _applyMonthlyOvertimeBasketCap(
        computation: rawComputation,
        payableOvertimeHoursAlreadyConsumed: consumedPayableOvertimeHours,
        monthlyOvertimeLimit: overtimeMonthlyLimit,
      );

      final isCompensative =
    shift.overtimeDestination ==
    OvertimeDestination.compensative;

      computations[shift] = computation;
      totalOvertimeHours += computation.overtimeHours;

      if (department != Department.polfer) {
        consumedOrdinaryHours += shift.hasAbsence ? 0.0 : shift.workedHours;
      }

      final payableOvertimeHoursForShift = _extractPayableOvertimeHours(
        computation.breakdown,
      );
      consumedPayableOvertimeHours += payableOvertimeHoursForShift;

      final overtimeGross = computation.breakdown
    .where((item) {
      if (item['isBasketItem'] == true) {
        return false;
      }

      return _isOvertimeCategory(item['category']);
    })
    .fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

final programmedHours = _calculateProgrammedOvertimeHours(
  shift: shift,
  normalizedEnd: ShiftTimeHelper.normalizedEnd(
    shift.start,
    shift.end,
  ),
);

final requestedCompensativeHours = isCompensative
    ? _sanitizeHours(shift.compensativeOvertimeHours)
    : 0.0;

final automaticCompensativeHours =
    programmedHours > 0
        ? programmedHours
        : payableOvertimeHoursForShift;

final effectiveCompensativeHours = isCompensative
    ? (requestedCompensativeHours > 0
        ? requestedCompensativeHours.clamp(
            0.0,
            computation.overtimeHours,
          )
        : automaticCompensativeHours.clamp(
            0.0,
            computation.overtimeHours,
          ))
    : 0.0;

final compensativeRatio = computation.overtimeHours > 0
    ? (effectiveCompensativeHours / computation.overtimeHours).clamp(0.0, 1.0)
    : 0.0;

final compensativeOvertimeGross =
    _sanitizeMoney(
  effectiveCompensativeHours * profile.overtimeDayRate,
);

final baseNonBasketAmount = computation.breakdown
    .where((item) => item['isBasketItem'] != true)
    .fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

final normalAmount = isCompensative && compensativeRatio >= 0.999
    ? computation.breakdown
        .where(
          (item) =>
              item['isBasketItem'] != true &&
              !_isOvertimeCategory(item['category']),
        )
        .fold<double>(
          0.0,
          (sum, item) =>
              sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        )
    : _sanitizeMoney(
    (computation.overtimeHours - effectiveCompensativeHours) *
        profile.overtimeDayRate,
  );

totalAmount += _sanitizeMoney(normalAmount);

if (effectiveCompensativeHours > 0) {
  compensativeHours += effectiveCompensativeHours;
  compensativeGrossEstimate += compensativeOvertimeGross;
}
final shiftRfiBasketAmount = computation.breakdown
    .where(
      (item) =>
          item['isBasketItem'] == true && item['basketKey'] == 'rfi',
    )
    .fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
      rfiBasketAmount += shiftRfiBasketAmount;

      for (final item in computation.breakdown) {
        final label = (item['label'] as String?)?.trim();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        final isBasket = item['isBasketItem'] == true;
        final basketKey = item['basketKey'];

        if (label == null || label.isEmpty) continue;

        if (isBasket && (basketKey == 'rfi' || basketKey == 'overtime')) {
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
      compensativeHours: compensativeHours,
compensativeGrossEstimate: compensativeGrossEstimate,
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

    if (department == Department.questura) {
  final computation = _buildShiftComputationUseCase.execute(
    shift: shift,
    profile: profile,
    department: department,
  );

  return DailyShiftComputation(
    overtimeHours: computation.overtimeHours,
    totalAmount: computation.totalAmount,
    extraAmount: computation.extraAmount,
    breakdown: computation.breakdown,
  );
}

    

    final normalizedEnd = ShiftTimeHelper.normalizedEnd(shift.start, shift.end);
final shiftWorkedHours = shift.workedHours;

final ordinaryLimit = shift.ordinaryHoursOverrideEnabled &&
        shift.ordinaryHoursOverride > 0
    ? shift.ordinaryHoursOverride
    : _dailyOrdinaryHoursLimit;

late final double ordinaryHoursForShift;
late final double overtimeHoursForShift;

final programmedOvertimeHours = _calculateProgrammedOvertimeHours(
  shift: shift,
  normalizedEnd: normalizedEnd,
);

final nonProgrammedWorkedHours =
    (shiftWorkedHours - programmedOvertimeHours).clamp(
  0.0,
  shiftWorkedHours,
);

if (programmedOvertimeHours > 0) {
  final remainingOrdinaryHours =
      (ordinaryLimit - ordinaryHoursAlreadyConsumed)
          .clamp(0.0, ordinaryLimit);

  ordinaryHoursForShift =
      nonProgrammedWorkedHours <= remainingOrdinaryHours
          ? nonProgrammedWorkedHours
          : remainingOrdinaryHours;

  overtimeHoursForShift =
      programmedOvertimeHours +
      (nonProgrammedWorkedHours - ordinaryHoursForShift).clamp(
        0.0,
        nonProgrammedWorkedHours,
      );
} else if (
    (
      department == Department.polfer &&
      shift.spmnPresetCode.trim().toLowerCase() != 'aggiornamento' &&
      shift.description.trim().toLowerCase() != 'aggiornamento'
    ) ||
    (
      department == Department.questura &&
      shift.questuraMode == QuesturaMode.volanti &&
      shift.questuraPreset != QuesturaPreset.none &&
      shift.questuraPreset != QuesturaPreset.aggiornamento &&
      shift.description.trim().toLowerCase() != 'aggiornamento'
    )
) {

    
      final scheduledEnd =
    _resolvePolferScheduledEnd(shift) ??
    _resolveQuesturaScheduledEnd(shift);

      if (scheduledEnd == null) {
        final remainingOrdinaryHours =
    (ordinaryLimit - ordinaryHoursAlreadyConsumed)
        .clamp(0.0, ordinaryLimit);

        ordinaryHoursForShift = shiftWorkedHours <= remainingOrdinaryHours
            ? shiftWorkedHours
            : remainingOrdinaryHours;

        overtimeHoursForShift =
            (shiftWorkedHours - ordinaryHoursForShift).clamp(
          0.0,
          shiftWorkedHours,
        );
      } else {
  if (shift.ordinaryHoursOverrideEnabled &&
      shift.ordinaryHoursOverride > 0) {
    ordinaryHoursForShift =
        shift.ordinaryHoursOverride.clamp(0.0, shiftWorkedHours);

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
}
    } else {
      final remainingOrdinaryHours =
    (ordinaryLimit - ordinaryHoursAlreadyConsumed)
        .clamp(0.0, ordinaryLimit);

      ordinaryHoursForShift = shiftWorkedHours <= remainingOrdinaryHours
          ? shiftWorkedHours
          : remainingOrdinaryHours;

      overtimeHoursForShift =
          (shiftWorkedHours - ordinaryHoursForShift).clamp(
        0.0,
        shiftWorkedHours,
      );
    }

    DateTime overtimeStart;

final polferScheduledEnd =
    department == Department.polfer
        ? _resolvePolferScheduledEnd(shift)
        : null;

final questuraScheduledEnd =
    department == Department.questura
        ? _resolveQuesturaScheduledEnd(shift)
        : null;

if (polferScheduledEnd != null) {
  overtimeStart = polferScheduledEnd;
} else if (questuraScheduledEnd != null) {
  overtimeStart = questuraScheduledEnd;
} else {
  overtimeStart = shift.start.add(
    Duration(
      minutes: (ordinaryHoursForShift * 60).round(),
    ),
  );
}

    final ordinaryNightHours = ordinaryHoursForShift > 0
        ? TimeBandHelper.calculateNightOnlyHours(shift.start, overtimeStart)
        : 0.0;

    final overtimeSegments = <_OvertimeSegment>[];

void appendSegments(DateTime from, DateTime to) {
  if (!to.isAfter(from)) return;

  overtimeSegments.addAll(
    _buildOvertimeSegments(from, to),
  );
}

final programmedStart = shift.programmedOvertimeStart;
final programmedEnd = shift.programmedOvertimeEnd;

if (shift.programmedOvertimeEnabled &&
    programmedStart != null &&
    programmedEnd != null &&
    programmedEnd.isAfter(programmedStart)) {
  appendSegments(programmedStart, programmedEnd);
}

if (polferScheduledEnd != null) {
  final preset = _resolveOperationalPresetCode(shift);

  DateTime scheduledStart;

  switch (preset) {
    case 'mattina':
      scheduledStart = DateTime(
        shift.start.year,
        shift.start.month,
        shift.start.day,
        6,
        55,
      );
      break;

    case 'pomeriggio':
      scheduledStart = DateTime(
        shift.start.year,
        shift.start.month,
        shift.start.day,
        12,
        55,
      );
      break;

    case 'sera':
      scheduledStart = DateTime(
        shift.start.year,
        shift.start.month,
        shift.start.day,
        18,
        55,
      );
      break;

    case 'notte':
      scheduledStart = DateTime(
        shift.start.year,
        shift.start.month,
        shift.start.day,
        23,
        55,
      );
      break;

    default:
      scheduledStart = shift.start;
  }

  if (shift.start.isBefore(scheduledStart)) {
    appendSegments(
      shift.start,
      scheduledStart,
    );
  }

  if (normalizedEnd.isAfter(polferScheduledEnd)) {
    appendSegments(
      polferScheduledEnd,
      normalizedEnd,
    );
  }
} else if (!shift.programmedOvertimeEnabled) {
  overtimeSegments.addAll(
    overtimeHoursForShift > 0
        ? _buildOvertimeSegments(
            overtimeStart,
            normalizedEnd,
          )
        : const <_OvertimeSegment>[],
  );
}
if (shift.ordinaryHoursOverrideEnabled &&
    shift.ordinaryHoursOverride > 0 &&
    !shift.programmedOvertimeEnabled &&
    overtimeHoursForShift > 0) {
  overtimeSegments
    ..clear()
    ..addAll(
      _buildOvertimeSegments(
        normalizedEnd.subtract(
          Duration(
            minutes: (overtimeHoursForShift * 60).round(),
          ),
        ),
        normalizedEnd,
      ),
    );
}

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

    final overtimeDayRate = profile.overtimeDayRate * overtimeAmountMultiplier;
    final overtimeNightOrHolidayRate =
        profile.overtimeNightOrHolidayRate * overtimeAmountMultiplier;
    final overtimeNightHolidayRate =
        profile.overtimeNightAndHolidayRate * overtimeAmountMultiplier;

    final overtimeDayAmount = overtimeDayHours * overtimeDayRate;
    final overtimeNightAmount = overtimeNightHours * overtimeNightOrHolidayRate;
    final overtimeHolidayDayAmount =
        overtimeHolidayDayHours * overtimeNightOrHolidayRate;
    final overtimeNightHolidayAmount =
        overtimeNightHolidayHours * overtimeNightHolidayRate;
    final ordinaryNightRate = department == Department.questura ? 2.32 : _nightAllowanceRate;
    final ordinaryNightAmount = ordinaryNightHours * ordinaryNightRate;

    final breakdown = <Map<String, dynamic>>[];

    if (overtimeNightHolidayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario notturno festivo (${_formatCompactHours(overtimeNightHolidayHours)} × €${overtimeNightHolidayRate.toStringAsFixed(2)})',
        'amount': overtimeNightHolidayAmount,
        'hours': overtimeNightHolidayHours,
        'hourlyRate': overtimeNightHolidayRate,
        'category': 'overtime_night_holiday',
      });
    }

    if (overtimeNightHours > 0) {
      breakdown.add({
        'label':
            'Straordinario notturno (${_formatCompactHours(overtimeNightHours)} × €${overtimeNightOrHolidayRate.toStringAsFixed(2)})',
        'amount': overtimeNightAmount,
        'hours': overtimeNightHours,
        'hourlyRate': overtimeNightOrHolidayRate,
        'category': 'overtime_night',
      });
    }

    if (overtimeHolidayDayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario festivo (${_formatCompactHours(overtimeHolidayDayHours)} × €${overtimeNightOrHolidayRate.toStringAsFixed(2)})',
        'amount': overtimeHolidayDayAmount,
        'hours': overtimeHolidayDayHours,
        'hourlyRate': overtimeNightOrHolidayRate,
        'category': 'overtime_holiday_day',
      });
    }

    if (overtimeDayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario diurno (${_formatCompactHours(overtimeDayHours)} × €${overtimeDayRate.toStringAsFixed(2)})',
        'amount': overtimeDayAmount,
        'hours': overtimeDayHours,
        'hourlyRate': overtimeDayRate,
        'category': 'overtime_day',
      });
    }

    if (ordinaryNightAmount > 0) {
      breakdown.add({
        'label':
            'Indennità servizio notturno (${_formatCompactHours(ordinaryNightHours)} × €${ordinaryNightRate.toStringAsFixed(2)} lordi)',
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

  DailyShiftComputation _applyMonthlyOvertimeBasketCap({
    required DailyShiftComputation computation,
    required double payableOvertimeHoursAlreadyConsumed,
    required double monthlyOvertimeLimit,
  }) {
    if (computation.breakdown.isEmpty) {
      return computation;
    }

    if (monthlyOvertimeLimit <= 0) {
      return computation;
    }

    double remainingPayableHours =
        (monthlyOvertimeLimit - payableOvertimeHoursAlreadyConsumed).clamp(
      0.0,
      monthlyOvertimeLimit,
    );

    final adjustedBreakdown = <Map<String, dynamic>>[];

    for (final rawItem in computation.breakdown) {
      final item = Map<String, dynamic>.from(rawItem);
      final category = item['category'];

      if (!_isOvertimeCategory(category)) {
        adjustedBreakdown.add(item);
        continue;
      }

      final itemHours = _sanitizeHours((item['hours'] as num?)?.toDouble() ?? 0);
      final itemAmount =
          _sanitizeMoney((item['amount'] as num?)?.toDouble() ?? 0.0);
      final hourlyRate = itemHours > 0
          ? _sanitizeMoney(
              (item['hourlyRate'] as num?)?.toDouble() ?? (itemAmount / itemHours),
            )
          : 0.0;

      if (itemHours <= 0 || itemAmount <= 0) {
        adjustedBreakdown.add(item);
        continue;
      }

      final payableHours = itemHours <= remainingPayableHours
          ? itemHours
          : remainingPayableHours;
      final basketHours = (itemHours - payableHours).clamp(0.0, itemHours);

      if (payableHours > 0) {
        final payableAmount = _sanitizeMoney(payableHours * hourlyRate);
        adjustedBreakdown.add({
          ...item,
          'hours': payableHours,
          'amount': payableAmount,
          'label': _overtimeLabel(
            category: category,
            hours: payableHours,
            hourlyRate: hourlyRate,
            isBasket: false,
          ),
        });
      }

      if (basketHours > 0) {
        final basketAmount = _sanitizeMoney(basketHours * hourlyRate);
        adjustedBreakdown.add({
          'label': _overtimeLabel(
            category: category,
            hours: basketHours,
            hourlyRate: hourlyRate,
            isBasket: true,
          ),
          'amount': basketAmount,
          'hours': basketHours,
          'hourlyRate': hourlyRate,
          'category': category,
          'isBasketItem': true,
          'basketKey': 'overtime',
        });
      }

      remainingPayableHours =
          (remainingPayableHours - payableHours).clamp(0.0, monthlyOvertimeLimit);
    }

    final totalAmount = adjustedBreakdown
        .where((item) => item['isBasketItem'] != true)
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );

    final extraAmount = adjustedBreakdown
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
      overtimeHours: computation.overtimeHours,
      totalAmount: totalAmount,
      extraAmount: extraAmount,
      breakdown: adjustedBreakdown,
    );
  }

  double _extractPayableOvertimeHours(List<Map<String, dynamic>> breakdown) {
    return breakdown
        .where(
          (item) =>
              _isOvertimeCategory(item['category']) &&
              item['isBasketItem'] != true,
        )
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['hours'] as num?)?.toDouble() ?? 0.0),
        );
  }

  bool _isOvertimeCategory(dynamic category) {
    return category == 'overtime_day' ||
        category == 'overtime_night' ||
        category == 'overtime_holiday_day' ||
        category == 'overtime_night_holiday';
  }

  String _overtimeLabel({
    required dynamic category,
    required double hours,
    required double hourlyRate,
    required bool isBasket,
  }) {
    final hoursLabel = _formatCompactHours(hours);
    final rateLabel = hourlyRate.toStringAsFixed(2);
    final basketSuffix = isBasket ? ' basket' : '';

    switch (category) {
      case 'overtime_night_holiday':
        return 'Straordinario notturno festivo$basketSuffix ($hoursLabel × €$rateLabel)';
      case 'overtime_night':
        return 'Straordinario notturno$basketSuffix ($hoursLabel × €$rateLabel)';
      case 'overtime_holiday_day':
        return 'Straordinario festivo$basketSuffix ($hoursLabel × €$rateLabel)';
      case 'overtime_day':
      default:
        return 'Straordinario diurno$basketSuffix ($hoursLabel × €$rateLabel)';
    }
  }

  String _formatCompactHours(double value) {
    if (value.isNaN || !value.isFinite || value <= 0) {
      return '0m';
    }

    final totalMinutes = (value * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';

    return '${hours}h ${minutes}m';
  }

  double _calculateProgrammedOvertimeHours({
  required Shift shift,
  required DateTime normalizedEnd,
}) {
  if (!shift.programmedOvertimeEnabled) return 0.0;

  final start = shift.programmedOvertimeStart;
  final end = shift.programmedOvertimeEnd;

  if (start == null || end == null) return 0.0;
  if (!end.isAfter(start)) return 0.0;

  final minutes = end.difference(start).inMinutes;
  if (minutes <= 0) return 0.0;

  return minutes / 60.0;
}

double _calculateProgrammedNightHours(Shift shift) {
  if (!shift.programmedOvertimeEnabled) return 0.0;

  final start = shift.programmedOvertimeStart;
  final end = shift.programmedOvertimeEnd;

  if (start == null || end == null) return 0.0;
  if (!end.isAfter(start)) return 0.0;

  return TimeBandHelper.calculateNightOnlyHours(start, end);
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
    final missionAmount = shift.hasMission ? shift.missionAmount : 0.0;
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

    if (missionAmount > 0) {
      breakdown.add({
        'label': 'Missione',
        'amount': missionAmount,
        'category': 'missione',
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

  double _sanitizeHours(double value) {
    if (value.isNaN || !value.isFinite || value < 0) return 0.0;
    return value;
  }

  double _sanitizeMoney(double value) {
    if (value.isNaN || !value.isFinite) return 0.0;
    return value;
  }
  String _resolveOperationalPresetCode(Shift shift) {
  final spmnCode = shift.spmnPresetCode.trim().toLowerCase();

  if (spmnCode.isNotEmpty && spmnCode != 'none') {
    return spmnCode;
  }

  if (shift.questuraPreset != QuesturaPreset.none) {
    return shift.questuraPreset.name.toLowerCase();
  }

  return '';
}
DateTime? _resolvePolferScheduledEnd(Shift shift) {
  final preset = _resolveOperationalPresetCode(shift);
  final start = shift.start;

  switch (preset) {
  case 'mattina':
    return DateTime(start.year, start.month, start.day, 13, 8);
  case 'pomeriggio':
    return DateTime(start.year, start.month, start.day, 19, 8);
  case 'sera':
    return DateTime(start.year, start.month, start.day, 0, 8)
        .add(const Duration(days: 1));
  case 'notte':
    return DateTime(start.year, start.month, start.day, 7, 8)
        .add(const Duration(days: 1));
  case 'aggiornamento':
    return DateTime(start.year, start.month, start.day, 14, 0);
  default:
    break;
}

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

DateTime? _resolveQuesturaScheduledEnd(Shift shift) {
  switch (shift.questuraPreset) {
    case QuesturaPreset.mattina:
      return DateTime(shift.start.year, shift.start.month, shift.start.day, 13, 8);
    case QuesturaPreset.pomeriggio:
      return DateTime(shift.start.year, shift.start.month, shift.start.day, 19, 8);
    case QuesturaPreset.sera:
      return DateTime(shift.start.year, shift.start.month, shift.start.day + 1, 0, 8);
    case QuesturaPreset.notte:
      return DateTime(shift.start.year, shift.start.month, shift.start.day + 1, 7, 8);
    case QuesturaPreset.none:
    case QuesturaPreset.smontante:
    case QuesturaPreset.riposo:
    case QuesturaPreset.aggiornamento:
      return null;
  }
}

  double _calculatePolferScaloAmount({
    required Shift shift,
    required DateTime normalizedEnd,
  }) {
    if (shift.polferScaloMode == PolferScaloMode.none) return 0.0;

    final workedNightHours = TimeBandHelper.calculateNightOnlyHours(
  shift.start,
  normalizedEnd,
);

final programmedHours = _calculateProgrammedOvertimeHours(
  shift: shift,
  normalizedEnd: normalizedEnd,
);

final programmedNightHours = _calculateProgrammedNightHours(shift);

final totalWorkedHours = shift.workedHours + programmedHours;
final totalNightHours = workedNightHours + programmedNightHours;
final totalDayHours =
    (totalWorkedHours - totalNightHours).clamp(0.0, totalWorkedHours);

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