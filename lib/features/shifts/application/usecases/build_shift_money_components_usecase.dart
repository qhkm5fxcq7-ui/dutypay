import '../../domain/engine/models/shift_money_components.dart';
import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import 'build_daily_shift_result_usecase.dart';

class BuildShiftMoneyComponentsUseCase {
  const BuildShiftMoneyComponentsUseCase();

  ShiftMoneyComponents execute({
    required Shift shift,
    required UserPayProfile profile,
    required Department department,
  }) {
    if (shift.absence != 'Nessuna') {
      return const ShiftMoneyComponents(
        overtimeGross: 0.0,
        overtimeHours: 0.0,
        nonOvertimeGross: 0.0,
        rfiBasketGross: 0.0,
      );
    }

    final dailyResult = const BuildDailyShiftResultUseCase().execute(
  shifts: [shift],
  profile: profile,
  department: department,
);

final computation = dailyResult.computations[shift];

if (computation == null) {
  return const ShiftMoneyComponents(
    overtimeGross: 0.0,
    overtimeHours: 0.0,
    nonOvertimeGross: 0.0,
    rfiBasketGross: 0.0,
  );
}

final totalGross = _sanitizeMoney(computation.totalAmount);
final overtimeHours = _sanitizeHours(dailyResult.totalOvertimeHours);

    final overtimeGross = _sanitizeMoney(
      computation.breakdown
          .where((item) => _isOvertimeCategory(item['category']))
          .fold<double>(
            0.0,
            (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
          ),
    );

    final rfiBasketGross = _sanitizeMoney(
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

    final nonOvertimeGross = _sanitizeMoney(
      totalGross - overtimeGross - rfiBasketGross,
    );

    return ShiftMoneyComponents(
      overtimeGross: overtimeGross,
      overtimeHours: overtimeHours,
      nonOvertimeGross: nonOvertimeGross < 0 ? 0.0 : nonOvertimeGross,
      rfiBasketGross: rfiBasketGross,
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

  double _sanitizeHours(double value) {
    if (value.isNaN || !value.isFinite || value < 0) return 0.0;
    return value;
  }
}