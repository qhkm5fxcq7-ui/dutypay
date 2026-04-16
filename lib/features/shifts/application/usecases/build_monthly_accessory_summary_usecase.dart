import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import '../models/monthly_accessory_summary.dart';
import 'build_shift_money_components_usecase.dart';

class BuildMonthlyAccessorySummaryUseCase {
  const BuildMonthlyAccessorySummaryUseCase();

  MonthlyAccessorySummary execute({
    required DateTime month,
    required List<Shift> allShifts,
    required UserPayProfile profile,
    required Department department,
  }) {
    const shiftMoneyUseCase = BuildShiftMoneyComponentsUseCase();

    double nonOvertimeGross = 0.0;
    double overtimeGross = 0.0;
    double overtimeHours = 0.0;
    double rfiBasketGross = 0.0;
    int shiftCount = 0;

    final monthShifts = allShifts.where((shift) {
      return shift.serviceDate.year == month.year &&
          shift.serviceDate.month == month.month;
    });

    for (final shift in monthShifts) {
      shiftCount++;

      final components = shiftMoneyUseCase.execute(
        shift: shift,
        profile: profile,
        department: department,
      );

      nonOvertimeGross += components.nonOvertimeGross;
      overtimeGross += components.overtimeGross;
      overtimeHours += components.overtimeHours;
      rfiBasketGross += components.rfiBasketGross;
    }

    final totalGross = nonOvertimeGross + overtimeGross + rfiBasketGross;

    return MonthlyAccessorySummary(
      month: DateTime(month.year, month.month),
      shiftCount: shiftCount,
      nonOvertimeGross: _sanitizeMoney(nonOvertimeGross),
      overtimeGross: _sanitizeMoney(overtimeGross),
      overtimeHours: _sanitizeNonNegative(overtimeHours),
      rfiBasketGross: _sanitizeMoney(rfiBasketGross),
      totalGross: _sanitizeMoney(totalGross),
    );
  }

  double _sanitizeMoney(double value) {
    if (value.isNaN || !value.isFinite) return 0.0;
    return value;
  }

  double _sanitizeNonNegative(double value) {
    if (value.isNaN || !value.isFinite) return 0.0;
    if (value < 0) return 0.0;
    return value;
  }
}