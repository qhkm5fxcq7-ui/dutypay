import '../models/shift_calculation_result.dart';
import '../../entities/shift.dart';
import '../../entities/user_pay_profile.dart';
import '../helpers/shift_time_helper.dart';
import '../helpers/time_band_helper.dart';
import 'department_policy.dart';

class PolferPolicy implements DepartmentPolicy {
  const PolferPolicy();

  static const double standardHours = 6.0;
  static const double fallbackNightAllowance = 4.30;

  static const double territorySeraleRate = 5.00;
  static const double territoryNotturnoRate = 10.00;

  static const double scaloReducedDayRate = 0.31;
  static const double scaloReducedNightRate = 0.77;
  static const double scaloFullDayRate = 1.00;
  static const double scaloFullNightRate = 2.50;

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

    final scheduledEnd = _resolvePolferScheduledEnd(shift);

    final ordinaryHours = shift.ordinaryHoursOverrideEnabled
        ? shift.ordinaryHoursOverride.clamp(0.0, workedHours)
        : _calculateOrdinaryHours(
            start: shift.start,
            end: normalizedEnd,
            scheduledEnd: scheduledEnd,
            workedHours: workedHours,
          );

    final overtimeHours =
        workedHours > ordinaryHours ? workedHours - ordinaryHours : 0.0;

    final dayHours = TimeBandHelper.calculateBandHours(
      shift.start,
      normalizedEnd,
      dayBand: true,
    );

    final nightHours = TimeBandHelper.calculateBandHours(
      shift.start,
      normalizedEnd,
      dayBand: false,
    );

    final programmedDayHours = _calculateProgrammedBandHours(
      shift,
      dayBand: true,
    );

    final programmedNightHours = _calculateProgrammedBandHours(
      shift,
      dayBand: false,
    );

    final scaloDayHours = dayHours + programmedDayHours;
    final scaloNightHours = nightHours + programmedNightHours;

    final ordinaryNightHours = overtimeHours > 0
        ? (nightHours - overtimeHours).clamp(0.0, nightHours)
        : nightHours;

    final ordinaryNightAmount = ordinaryNightHours * fallbackNightAllowance;

    final territoryAmount = _calculateTerritoryAmount(shift);

    final scaloAmount = _calculateScaloAmount(
      shift: shift,
      dayHours: scaloDayHours,
      nightHours: scaloNightHours,
    );

    final breakdown = <Map<String, dynamic>>[];

    if (ordinaryNightAmount > 0) {
      breakdown.add({
        'label':
            'Indennità servizio notturno (${ordinaryNightHours.toStringAsFixed(1)}h × €${fallbackNightAllowance.toStringAsFixed(2)} lordi)',
        'amount': ordinaryNightAmount,
        'category': 'ordinary_night',
      });
    }

    if (territoryAmount > 0) {
      breakdown.add({
        'label': _territoryLabel(shift),
        'amount': territoryAmount,
        'category': 'polfer_territory',
      });
    }

    if (scaloAmount > 0) {
      breakdown.add({
        'label': _scaloLabel(shift),
        'amount': scaloAmount,
        'category': 'polfer_scalo',
        'basketKey': 'rfi',
        'isBasketItem': true,
      });
    }

    final totalAmount = breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    final extraAmount =
        breakdown.where((item) => item['isBasketItem'] != true).fold<double>(
              0.0,
              (sum, item) =>
                  sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
            );

    return ShiftCalculationResult(
      workedHours: workedHours,
      ordinaryHours: ordinaryHours,
      overtimeHours: overtimeHours,
      nightOrdinaryHours: ordinaryNightHours,
      overtimeDayHours: 0.0,
      overtimeNightHours: 0.0,
      overtimeHolidayDayHours: 0.0,
      overtimeNightHolidayHours: 0.0,
      totalAmount: totalAmount,
      extraAmount: extraAmount,
      breakdown: breakdown,
    );
  }

  double _calculateOrdinaryHours({
    required DateTime start,
    required DateTime end,
    required DateTime? scheduledEnd,
    required double workedHours,
  }) {
    if (scheduledEnd == null) {
      return workedHours > standardHours ? standardHours : workedHours;
    }

    final effectiveOrdinaryEnd =
        scheduledEnd.isBefore(end) ? scheduledEnd : end;

    if (!effectiveOrdinaryEnd.isAfter(start)) return 0.0;

    final minutes = effectiveOrdinaryEnd.difference(start).inMinutes;
    return minutes > 0 ? minutes / 60.0 : 0.0;
  }

  DateTime? _resolvePolferScheduledEnd(Shift shift) {
    final start = shift.start;
    final startMinutes = start.hour * 60 + start.minute;

    // Mattina circa 06:00 - 08:59 -> fine teorica 13:08
    if (startMinutes >= 360 && startMinutes <= 539) {
      return DateTime(start.year, start.month, start.day, 13, 8);
    }

    // Pomeriggio circa 12:00 - 14:59 -> fine teorica 19:08
    if (startMinutes >= 720 && startMinutes <= 899) {
      return DateTime(start.year, start.month, start.day, 19, 8);
    }

    // Sera circa 18:00 - 20:59 -> fine teorica 00:08 del giorno dopo
    if (startMinutes >= 1080 && startMinutes <= 1259) {
      return DateTime(start.year, start.month, start.day, 0, 8)
          .add(const Duration(days: 1));
    }

    // Notte circa 22:00 - 02:59 -> fine teorica 07:08 del giorno dopo
    if (startMinutes >= 1320 || startMinutes <= 179) {
      return DateTime(start.year, start.month, start.day, 7, 8)
          .add(const Duration(days: 1));
    }

    return null;
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

  double _calculateProgrammedBandHours(
    Shift shift, {
    required bool dayBand,
  }) {
    if (!shift.programmedOvertimeEnabled) return 0.0;

    final start = shift.programmedOvertimeStart;
    final end = shift.programmedOvertimeEnd;

    if (start == null || end == null) return 0.0;
    if (!end.isAfter(start)) return 0.0;

    return TimeBandHelper.calculateBandHours(
      start,
      end,
      dayBand: dayBand,
    );
  }

  double _calculateScaloAmount({
    required Shift shift,
    required double dayHours,
    required double nightHours,
  }) {
    if (shift.polferScaloMode == PolferScaloMode.none) return 0.0;

    final effectiveReducedDayHours = shift.polferScaloManualOverride
        ? shift.polferScaloReducedDayHours
        : shift.polferScaloMode == PolferScaloMode.ridotta
            ? dayHours
            : 0.0;

    final effectiveReducedNightHours = shift.polferScaloManualOverride
        ? shift.polferScaloReducedNightHours
        : shift.polferScaloMode == PolferScaloMode.ridotta
            ? nightHours
            : 0.0;

    final effectiveFullDayHours = shift.polferScaloManualOverride
        ? shift.polferScaloFullDayHours
        : shift.polferScaloMode == PolferScaloMode.intera
            ? dayHours
            : 0.0;

    final effectiveFullNightHours = shift.polferScaloManualOverride
        ? shift.polferScaloFullNightHours
        : shift.polferScaloMode == PolferScaloMode.intera
            ? nightHours
            : 0.0;

    return (effectiveReducedDayHours * scaloReducedDayRate) +
        (effectiveReducedNightHours * scaloReducedNightRate) +
        (effectiveFullDayHours * scaloFullDayRate) +
        (effectiveFullNightHours * scaloFullNightRate);
  }

  String _scaloLabel(Shift shift) {
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
}
