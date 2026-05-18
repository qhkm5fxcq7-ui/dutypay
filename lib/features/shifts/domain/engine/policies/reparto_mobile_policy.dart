import '../models/shift_calculation_result.dart';
import '../../entities/shift.dart';
import '../../entities/user_pay_profile.dart';
import '../helpers/date_classification_helper.dart';
import '../helpers/shift_time_helper.dart';
import '../helpers/time_band_helper.dart';
import 'department_policy.dart';

class RepartoMobilePolicy implements DepartmentPolicy {
  const RepartoMobilePolicy();

  static const double standardHours = 6.0;
  static const double fallbackNightAllowance = 4.30;

  @override
  ShiftCalculationResult calculateShift(
    Shift shift,
    UserPayProfile profile,
  ) {
    final workedHours = ShiftTimeHelper.calculateWorkedHours(
      shift.start,
      shift.end,
    );

    final ordinaryThreshold =
    shift.ordinaryHoursOverrideEnabled
        ? shift.ordinaryHoursOverride
        : standardHours;

final ordinaryHours =
    workedHours > ordinaryThreshold
        ? ordinaryThreshold
        : workedHours;

final overtimeHours =
    workedHours > ordinaryThreshold
        ? workedHours - ordinaryThreshold
        : 0.0;

    final ordinaryRangeEnd = shift.start.add(
      Duration(minutes: (ordinaryHours * 60).round()),
    );

    final nightOrdinaryHours = TimeBandHelper.calculateNightOnlyHours(
      shift.start,
      ordinaryRangeEnd,
    );

    final overtimeStart = ordinaryRangeEnd;
    final overtimeEnd = ShiftTimeHelper.normalizedEnd(
      shift.start,
      shift.end,
    );

    final segments = _buildOvertimeSegments(overtimeStart, overtimeEnd);

    double overtimeDayHours = 0.0;
    double overtimeNightHours = 0.0;
    double overtimeHolidayDayHours = 0.0;
    double overtimeNightHolidayHours = 0.0;

    for (final segment in segments) {
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

    final overtimeDayAmount =
        overtimeDayHours * profile.overtimeDayRate;

    final overtimeNightAmount =
        overtimeNightHours * profile.overtimeNightOrHolidayRate;

    final overtimeHolidayDayAmount =
        overtimeHolidayDayHours * profile.overtimeNightOrHolidayRate;

    final overtimeNightHolidayAmount =
        overtimeNightHolidayHours * profile.overtimeNightAndHolidayRate;

    // RM rule:
    // ordinary night and overtime night are distinct dimensions.
    // Do NOT subtract overtime night from ordinary night.
    final ordinaryNightAmount =
        nightOrdinaryHours * fallbackNightAllowance;

    final breakdown = <Map<String, dynamic>>[];

    if (overtimeNightHolidayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario notturno festivo (${overtimeNightHolidayHours.toStringAsFixed(1)}h × €${profile.overtimeNightAndHolidayRate.toStringAsFixed(2)} lordi)',
        'amount': overtimeNightHolidayAmount,
        'hours': overtimeNightHolidayHours,
        'category': 'overtime_night_holiday',
      });
    }

    if (overtimeNightHours > 0) {
      breakdown.add({
        'label':
            'Straordinario notturno (${overtimeNightHours.toStringAsFixed(1)}h × €${profile.overtimeNightOrHolidayRate.toStringAsFixed(2)} lordi)',
        'amount': overtimeNightAmount,
        'hours': overtimeNightHours,
        'category': 'overtime_night',
      });
    }

    if (overtimeHolidayDayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario festivo (${overtimeHolidayDayHours.toStringAsFixed(1)}h × €${profile.overtimeNightOrHolidayRate.toStringAsFixed(2)} lordi)',
        'amount': overtimeHolidayDayAmount,
        'hours': overtimeHolidayDayHours,
        'category': 'overtime_holiday_day',
      });
    }

    if (overtimeDayHours > 0) {
      breakdown.add({
        'label':
            'Straordinario diurno (${overtimeDayHours.toStringAsFixed(1)}h × €${profile.overtimeDayRate.toStringAsFixed(2)} lordi)',
        'amount': overtimeDayAmount,
        'hours': overtimeDayHours,
        'category': 'overtime_day',
      });
    }

    if (nightOrdinaryHours > 0) {
      breakdown.add({
        'label':
            'Indennità servizio notturno (${nightOrdinaryHours.toStringAsFixed(1)}h × €${fallbackNightAllowance.toStringAsFixed(2)} lordi)',
        'amount': ordinaryNightAmount,
        'hours': nightOrdinaryHours,
        'category': 'ordinary_night',
      });
    }

    final totalAmount = breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return ShiftCalculationResult(
      workedHours: workedHours,
      ordinaryHours: ordinaryHours,
      overtimeHours: overtimeHours,
      nightOrdinaryHours: nightOrdinaryHours,
      overtimeDayHours: overtimeDayHours,
      overtimeNightHours: overtimeNightHours,
      overtimeHolidayDayHours: overtimeHolidayDayHours,
      overtimeNightHolidayHours: overtimeNightHolidayHours,
      totalAmount: totalAmount,
      extraAmount: totalAmount,
      breakdown: breakdown,
    );
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