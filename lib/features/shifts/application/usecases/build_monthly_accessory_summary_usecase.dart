import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import '../models/monthly_accessory_summary.dart';
import 'build_daily_shift_result_usecase.dart';

class BuildMonthlyAccessorySummaryUseCase {
  const BuildMonthlyAccessorySummaryUseCase();

  MonthlyAccessorySummary execute({
    required DateTime month,
    required List<Shift> allShifts,
    required UserPayProfile profile,
    required Department department,
  }) {
    const dailyUseCase = BuildDailyShiftResultUseCase();

    double nonOvertimeGross = 0.0;
    double overtimeGross = 0.0;
    double overtimeHours = 0.0;
    double rfiBasketGross = 0.0;

    final monthShifts = allShifts.where((shift) {
      return shift.serviceDate.year == month.year &&
          shift.serviceDate.month == month.month;
    }).toList();

    final shiftCount = monthShifts.length;

    final dailyResult = dailyUseCase.execute(
      shifts: monthShifts,
      profile: profile,
      department: department,
    );

    for (final shift in monthShifts) {
      final computation = dailyResult.computations[shift];
      if (computation == null) continue;

      final shiftTotalGross = _sanitizeMoney(computation.totalAmount);

      final shiftOvertimeGross = _sanitizeMoney(
        computation.breakdown
            .where((item) => _isOvertimeCategory(item['category']))
            .fold<double>(
              0.0,
              (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
            ),
      );

      final shiftRfiBasketGross = _sanitizeMoney(
        computation.breakdown
            .where(
              (item) =>
                  item['isBasketItem'] == true && item['basketKey'] == 'rfi',
            )
            .fold<double>(
              0.0,
              (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
            ),
      );

      final shiftNonOvertimeGross = _sanitizeMoney(
        shiftTotalGross - shiftOvertimeGross - shiftRfiBasketGross,
      );

      nonOvertimeGross += shiftNonOvertimeGross < 0 ? 0.0 : shiftNonOvertimeGross;
      overtimeGross += shiftOvertimeGross;
      overtimeHours += computation.overtimeHours;
      rfiBasketGross += shiftRfiBasketGross;
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

  bool _isOvertimeCategory(dynamic category) {
    return category == 'overtime_day' ||
        category == 'overtime_night' ||
        category == 'overtime_holiday_day' ||
        category == 'overtime_night_holiday';
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