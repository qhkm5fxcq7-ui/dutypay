import '../../shifts/presentation/models/shift.dart';
import '../models/allowance_calculation_input.dart';
import '../models/allowance_calculation_result.dart';
import '../models/allowance_config.dart';
import '../models/department_config.dart';
import 'allowance_engine.dart';
import '../models/allowance_summary.dart';
import '../models/shift_allowance_result.dart';
import '../models/monthly_allowance_summary.dart';

class ShiftAllowanceIntegrationService {
  final AllowanceEngine _engine;

  const ShiftAllowanceIntegrationService({
    AllowanceEngine engine = const AllowanceEngine(),
  }) : _engine = engine;

  List<AllowanceCalculationResult> calculateAllowancesForShift({
    required Shift shift,
    required DepartmentConfig departmentConfig,
    required List<String> selectedAllowanceIds,
    Map<String, bool> basketOverrides = const {},
  }) {
    if (shift.hasAbsence) return const [];

    final results = <AllowanceCalculationResult>[];
    final split = _calculateDayNightHours(shift);

    for (final allowanceId in selectedAllowanceIds) {
      final config = _findAllowanceById(
        departmentConfig.allowances,
        allowanceId,
      );

      if (config == null) continue;
      if (!_isAllowanceApplicableToShift(shift, config)) continue;

      final input = AllowanceCalculationInput(
        workedHours: shift.workedHours,
        dayHours: split.dayHours,
        nightHours: split.nightHours,
        isNightShift: split.nightHours > 0,
        sendToBasket: basketOverrides[config.id] ?? config.defaultToBasket,
      );
      List<ShiftAllowanceResult> calculateDetailedAllowancesForShifts({
  required List<Shift> shifts,
  required DepartmentConfig departmentConfig,
  required List<String> selectedAllowanceIds,
  Map<String, bool> basketOverrides = const {},
}) {
  final results = <ShiftAllowanceResult>[];

  for (final shift in shifts) {
    final shiftResults = calculateAllowancesForShift(
      shift: shift,
      departmentConfig: departmentConfig,
      selectedAllowanceIds: selectedAllowanceIds,
      basketOverrides: basketOverrides,
    );

    results.add(
      ShiftAllowanceResult(
        shift: shift,
        allowances: shiftResults,
      ),
    );
  }

  return results;
}

      results.add(
        _engine.calculate(
          config: config,
          input: input,
        ),
      );
    }

    return results;
  }

  AllowanceConfig? _findAllowanceById(
    List<AllowanceConfig> allowances,
    String allowanceId,
  ) {
    for (final allowance in allowances) {
      if (allowance.id == allowanceId) return allowance;
    }
    return null;
  }

  bool _isAllowanceApplicableToShift(
    Shift shift,
    AllowanceConfig config,
  ) {
    switch (config.id) {
      case 'ordine_pubblico':
        return shift.orderPublic != 'Nessuno';

      case 'servizio_esterno':
        return shift.externalService;

      case 'scalo_ferroviario':
        return true;

      default:
        return true;
    }
  }

  _DayNightSplit _calculateDayNightHours(Shift shift) {
    final totalMinutes = shift.end.difference(shift.start).inMinutes;
    if (totalMinutes <= 0) {
      return const _DayNightSplit(dayHours: 0, nightHours: 0);
    }

    int nightMinutes = 0;
    var cursor = shift.start;

    while (cursor.isBefore(shift.end)) {
      final next = cursor.add(const Duration(minutes: 1));

      if (_isNightMinute(cursor)) {
        nightMinutes++;
      }

      cursor = next;
    }

    final dayMinutes = totalMinutes - nightMinutes;

    return _DayNightSplit(
      dayHours: dayMinutes / 60.0,
      nightHours: nightMinutes / 60.0,
    );
  }

  bool _isNightMinute(DateTime dt) {
    final minutes = dt.hour * 60 + dt.minute;
    return minutes >= 22 * 60 || minutes < 6 * 60;
  }
    AllowanceSummary summarizeResults(
    List<AllowanceCalculationResult> results,
  ) {
    double totalMonthAmount = 0;
    double totalBasketAmount = 0;
    final totalsByAllowanceId = <String, double>{};

    for (final result in results) {
      if (result.goesToBasket) {
        totalBasketAmount += result.amount;
      } else {
        totalMonthAmount += result.amount;
      }

      totalsByAllowanceId[result.allowanceId] =
          (totalsByAllowanceId[result.allowanceId] ?? 0) + result.amount;
    }

    return AllowanceSummary(
      totalMonthAmount: totalMonthAmount,
      totalBasketAmount: totalBasketAmount,
      totalAmount: totalMonthAmount + totalBasketAmount,
      totalsByAllowanceId: totalsByAllowanceId,
    );
  }
  List<AllowanceCalculationResult> calculateAllowancesForShifts({
  required List<Shift> shifts,
  required DepartmentConfig departmentConfig,
  required List<String> selectedAllowanceIds,
  Map<String, bool> basketOverrides = const {},
}) {
  final results = <AllowanceCalculationResult>[];

  for (final shift in shifts) {
    results.addAll(
      calculateAllowancesForShift(
        shift: shift,
        departmentConfig: departmentConfig,
        selectedAllowanceIds: selectedAllowanceIds,
        basketOverrides: basketOverrides,
      ),
    );
  }

  return results;
}
MonthlyAllowanceSummary calculateMonthlySummary({
  required List<Shift> shifts,
  required DepartmentConfig departmentConfig,
  required List<String> selectedAllowanceIds,
  Map<String, bool> basketOverrides = const {},
}) {
  double totalMonthAmount = 0;
  double totalBasketAmount = 0;
  double totalWorkedHours = 0;

  final totalsByAllowanceId = <String, double>{};

  for (final shift in shifts) {
    totalWorkedHours += shift.workedHours;

    final results = calculateAllowancesForShift(
      shift: shift,
      departmentConfig: departmentConfig,
      selectedAllowanceIds: selectedAllowanceIds,
      basketOverrides: basketOverrides,
    );

    for (final result in results) {
      if (result.goesToBasket) {
        totalBasketAmount += result.amount;
      } else {
        totalMonthAmount += result.amount;
      }

      totalsByAllowanceId[result.allowanceId] =
          (totalsByAllowanceId[result.allowanceId] ?? 0) + result.amount;
    }
  }

  return MonthlyAllowanceSummary(
    totalMonthAmount: totalMonthAmount,
    totalBasketAmount: totalBasketAmount,
    totalAmount: totalMonthAmount + totalBasketAmount,
    totalsByAllowanceId: totalsByAllowanceId,
    totalShifts: shifts.length,
    totalWorkedHours: totalWorkedHours,
  );
}
}

class _DayNightSplit {
  final double dayHours;
  final double nightHours;

  const _DayNightSplit({
    required this.dayHours,
    required this.nightHours,
  });
}