import '../../entities/shift.dart';
import '../../entities/user_pay_profile.dart';
import '../helpers/date_classification_helper.dart';
import '../helpers/shift_time_helper.dart';
import '../helpers/time_band_helper.dart';
import '../models/shift_calculation_result.dart';
import 'department_policy.dart';

class QuesturaPolicy implements DepartmentPolicy {
  const QuesturaPolicy();

  static const double ordinaryNightAllowanceRate = 4.30;
  static const double territorySeraleRate = 5.00;
  static const double territoryNotturnoRate = 10.00;

  @override
  ShiftCalculationResult calculateShift(
    Shift shift,
    UserPayProfile profile,
  ) {
    final normalizedEnd = ShiftTimeHelper.normalizedEnd(
      shift.start,
      shift.end,
    );

    final workedHours = ShiftTimeHelper.calculateWorkedHours(
      shift.start,
      normalizedEnd,
    );

    final scheduledEnd = _resolveQuesturaScheduledEnd(shift);

    final ordinaryHours = shift.ordinaryHoursOverrideEnabled
        ? shift.ordinaryHoursOverride.clamp(0.0, workedHours)
        : _calculateOrdinaryHours(
            start: shift.start,
            end: normalizedEnd,
            scheduledEnd: scheduledEnd,
            workedHours: workedHours,
            shift: shift,
          );

    final realOvertimeStart = shift.start.add(
      Duration(minutes: (ordinaryHours * 60).round()),
    );

    final breakdown = <Map<String, dynamic>>[];

    final ordinaryNightHours = ordinaryHours > 0
        ? TimeBandHelper.calculateBandHours(
            shift.start,
            realOvertimeStart,
            dayBand: false,
          )
        : 0.0;

    if (ordinaryNightHours > 0) {
      breakdown.add({
        'label':
            'Indennità servizio notturno (${_formatHours(ordinaryNightHours)} × €${ordinaryNightAllowanceRate.toStringAsFixed(2)} lordi)',
        'amount': ordinaryNightHours * ordinaryNightAllowanceRate,
        'category': 'ordinary_night',
      });
    }

    final realOvertime = _appendOvertimeBreakdown(
      breakdown: breakdown,
      start: realOvertimeStart,
      end: normalizedEnd,
      profile: profile,
      labelPrefix: 'Straordinario',
    );

    final programmedOvertime = _appendProgrammedOvertimeBreakdown(
      breakdown: breakdown,
      shift: shift,
      profile: profile,
    );

    final territoryAmount = _calculateTerritoryAmount(shift);

    if (territoryAmount > 0) {
      breakdown.add({
        'label': _territoryLabel(shift),
        'amount': territoryAmount,
        'category': 'questura_territory',
      });
    }

    final totalAmount = breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return ShiftCalculationResult(
      workedHours: workedHours,
      ordinaryHours: ordinaryHours,
      overtimeHours: realOvertime.totalHours + programmedOvertime.totalHours,
      nightOrdinaryHours: ordinaryNightHours,
      overtimeDayHours: realOvertime.dayHours + programmedOvertime.dayHours,
      overtimeNightHours:
          realOvertime.nightHours + programmedOvertime.nightHours,
      overtimeHolidayDayHours:
          realOvertime.holidayDayHours + programmedOvertime.holidayDayHours,
      overtimeNightHolidayHours: realOvertime.nightHolidayHours +
          programmedOvertime.nightHolidayHours,
      totalAmount: totalAmount,
      extraAmount: totalAmount,
      breakdown: breakdown,
    );
  }

  double _calculateOrdinaryHours({
    required DateTime start,
    required DateTime end,
    required DateTime? scheduledEnd,
    required double workedHours,
    required Shift shift,
  }) {
    if (shift.questuraMode == QuesturaMode.uffici) {
      return shift.questuraOfficeOrdinaryHours.clamp(0.0, workedHours);
    }

    if (scheduledEnd == null) {
      return workedHours > 6.0 ? 6.0 : workedHours;
    }

    final effectiveOrdinaryEnd = scheduledEnd.isBefore(end) ? scheduledEnd : end;

    if (!effectiveOrdinaryEnd.isAfter(start)) return 0.0;

    final minutes = effectiveOrdinaryEnd.difference(start).inMinutes;
    return minutes > 0 ? minutes / 60.0 : 0.0;
  }

  DateTime? _resolveQuesturaScheduledEnd(Shift shift) {
    final start = shift.start;

    switch (shift.questuraPreset) {
      case QuesturaPreset.mattina:
        return DateTime(start.year, start.month, start.day, 13, 8);

      case QuesturaPreset.pomeriggio:
        return DateTime(start.year, start.month, start.day, 19, 8);

      case QuesturaPreset.sera:
        return DateTime(start.year, start.month, start.day, 0, 8)
            .add(const Duration(days: 1));

      case QuesturaPreset.notte:
        return DateTime(start.year, start.month, start.day, 7, 8)
            .add(const Duration(days: 1));

      default:
        return null;
    }
  }

  _OvertimeTotals _appendProgrammedOvertimeBreakdown({
    required List<Map<String, dynamic>> breakdown,
    required Shift shift,
    required UserPayProfile profile,
  }) {
    if (!shift.programmedOvertimeEnabled ||
        shift.programmedOvertimeStart == null ||
        shift.programmedOvertimeEnd == null) {
      return const _OvertimeTotals();
    }

    final programmedStart = shift.programmedOvertimeStart!;
    final programmedEnd = ShiftTimeHelper.normalizedEnd(
      programmedStart,
      shift.programmedOvertimeEnd!,
    );

    return _appendOvertimeBreakdown(
      breakdown: breakdown,
      start: programmedStart,
      end: programmedEnd,
      profile: profile,
      labelPrefix: 'Straordinario programmato',
    );
  }

  _OvertimeTotals _appendOvertimeBreakdown({
    required List<Map<String, dynamic>> breakdown,
    required DateTime start,
    required DateTime end,
    required UserPayProfile profile,
    required String labelPrefix,
  }) {
    if (!end.isAfter(start)) return const _OvertimeTotals();

    double dayHours = 0.0;
    double nightHours = 0.0;
    double holidayDayHours = 0.0;
    double nightHolidayHours = 0.0;

    var cursor = start;

    while (cursor.isBefore(end)) {
      final next = TimeBandHelper.nextBoundary(cursor, end);
      final minutes = next.difference(cursor).inMinutes;

      if (minutes > 0) {
        final hours = minutes / 60.0;
        final isNight = TimeBandHelper.isNightMoment(cursor);
        final isHoliday = DateClassificationHelper.isHolidayDate(cursor);

        if (isNight && isHoliday) {
          nightHolidayHours += hours;
        } else if (isNight) {
          nightHours += hours;
        } else if (isHoliday) {
          holidayDayHours += hours;
        } else {
          dayHours += hours;
        }
      }

      cursor = next;
    }

    if (nightHolidayHours > 0) {
      _addOvertimeItem(
        breakdown: breakdown,
        label: '$labelPrefix notturno festivo',
        category: 'overtime_night_holiday',
        hours: nightHolidayHours,
        hourlyRate: profile.overtimeNightAndHolidayRate,
      );
    }

    if (nightHours > 0) {
      _addOvertimeItem(
        breakdown: breakdown,
        label: '$labelPrefix notturno',
        category: 'overtime_night',
        hours: nightHours,
        hourlyRate: profile.overtimeNightOrHolidayRate,
      );
    }

    if (holidayDayHours > 0) {
      _addOvertimeItem(
        breakdown: breakdown,
        label: '$labelPrefix festivo',
        category: 'overtime_holiday_day',
        hours: holidayDayHours,
        hourlyRate: profile.overtimeNightOrHolidayRate,
      );
    }

    if (dayHours > 0) {
      _addOvertimeItem(
        breakdown: breakdown,
        label: '$labelPrefix diurno',
        category: 'overtime_day',
        hours: dayHours,
        hourlyRate: profile.overtimeDayRate,
      );
    }

    return _OvertimeTotals(
      dayHours: dayHours,
      nightHours: nightHours,
      holidayDayHours: holidayDayHours,
      nightHolidayHours: nightHolidayHours,
    );
  }

  void _addOvertimeItem({
    required List<Map<String, dynamic>> breakdown,
    required String label,
    required String category,
    required double hours,
    required double hourlyRate,
  }) {
    breakdown.add({
      'label':
          '$label (${_formatHours(hours)} × €${hourlyRate.toStringAsFixed(2)})',
      'amount': hours * hourlyRate,
      'hours': hours,
      'hourlyRate': hourlyRate,
      'category': category,
    });
  }

  double _calculateTerritoryAmount(Shift shift) {
    switch (shift.polferTerritoryControlType) {
      case PolferTerritoryControlType.none:
        return 0.0;
      case PolferTerritoryControlType.serale:
        return territorySeraleRate;
      case PolferTerritoryControlType.notturno:
        return territoryNotturnoRate;
    }
  }

  String _territoryLabel(Shift shift) {
    switch (shift.polferTerritoryControlType) {
      case PolferTerritoryControlType.none:
        return 'Nessuno';
      case PolferTerritoryControlType.serale:
        return 'Controllo del territorio serale';
      case PolferTerritoryControlType.notturno:
        return 'Controllo del territorio notturno';
    }
  }

  String _formatHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (m == 0) return '${h}h';
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

class _OvertimeTotals {
  final double dayHours;
  final double nightHours;
  final double holidayDayHours;
  final double nightHolidayHours;

  const _OvertimeTotals({
    this.dayHours = 0.0,
    this.nightHours = 0.0,
    this.holidayDayHours = 0.0,
    this.nightHolidayHours = 0.0,
  });

  double get totalHours =>
      dayHours + nightHours + holidayDayHours + nightHolidayHours;
}