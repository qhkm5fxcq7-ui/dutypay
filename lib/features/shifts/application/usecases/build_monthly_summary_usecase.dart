import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import '../models/monthly_summary.dart';
import 'build_daily_shift_result_usecase.dart';
import '../models/daily_shift_result.dart';

class BuildMonthlySummaryUseCase {
  const BuildMonthlySummaryUseCase();

  MonthlySummary execute({
    required List<Shift> shifts,
    required DateTime selectedMonth,
    required UserPayProfile profile,
    required Department department,
  }) {
    const dailyUseCase = BuildDailyShiftResultUseCase();

    final monthShifts = shifts.where((shift) {
      return shift.serviceDate.year == selectedMonth.year &&
          shift.serviceDate.month == selectedMonth.month;
    }).toList();

    final Map<String, List<Shift>> groupedShifts = {};

    for (final shift in monthShifts) {
      final key =
          '${shift.serviceDate.year}-${shift.serviceDate.month}-${shift.serviceDate.day}';
      groupedShifts.putIfAbsent(key, () => []).add(shift);
    }

    final Map<String, DailyShiftResult> dailyResults = {};

    final workedDays = <String>{};

    double totalAmount = 0.0;
    double totalOvertimeHours = 0.0;
    double totalRfiBasket = 0.0;

    for (final entry in groupedShifts.entries) {
      final result = dailyUseCase.execute(
        shifts: entry.value,
        profile: profile,
        department: department,
      );

      dailyResults[entry.key] = result;

      final dailyTotal = result.computations.values.fold<double>(
  0.0,
  (sum, computation) => sum + computation.totalAmount,
);

totalAmount += dailyTotal;
      totalOvertimeHours += result.totalOvertimeHours;
      totalRfiBasket += result.rfiBasketAmount;

      final hasWorked = entry.value.any((shift) => !shift.hasAbsence);
      if (hasWorked) {
        workedDays.add(entry.key);
      }
    }

    final workedDaysCount = workedDays.length;
    final averagePerDay =
        workedDaysCount > 0 ? totalAmount / workedDaysCount : 0.0;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final todayTotal = dailyResults.containsKey(todayKey)
    ? dailyResults[todayKey]!.computations.values.fold<double>(
    0.0,
    (sum, computation) => sum + computation.totalAmount,
  )
    : 0.0;

    final startOfWeek =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));

    double weekTotal = 0.0;
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';

      if (dailyResults.containsKey(key)) {
        final weekResult = dailyResults[key];
if (weekResult != null) {
  weekTotal += weekResult.computations.values.fold<double>(
    0.0,
    (sum, computation) => sum + computation.totalAmount,
  );
}
      }
    }

    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    final remainingDays = isCurrentMonth
        ? ((daysInMonth - now.day) > 0 ? (daysInMonth - now.day) : 0)
        : 0;

    final projectedExtraFuture =
        workedDaysCount > 0 ? averagePerDay * remainingDays : 0.0;

    return MonthlySummary(
      totalAmount: totalAmount,
      totalOvertimeHours: totalOvertimeHours,
      workedDays: workedDaysCount,
      averagePerDay: averagePerDay,
      todayTotal: todayTotal,
      weekTotal: weekTotal,
      daysInMonth: daysInMonth,
      remainingDays: remainingDays,
      projectedExtraFuture: projectedExtraFuture,
      rfiBasketAmount: totalRfiBasket,
    );
  }
}