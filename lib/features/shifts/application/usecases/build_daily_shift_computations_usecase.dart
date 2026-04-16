import '../models/daily_shift_computation.dart';
import '../models/daily_shift_computations_result.dart';
import '../usecases/build_shift_computation_usecase.dart';
import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';

class BuildDailyShiftComputationsUseCase {
  final BuildShiftComputationUseCase _buildShiftComputationUseCase;

  const BuildDailyShiftComputationsUseCase({
    BuildShiftComputationUseCase buildShiftComputationUseCase =
        const BuildShiftComputationUseCase(),
  }) : _buildShiftComputationUseCase = buildShiftComputationUseCase;

  DailyShiftComputationsResult execute({
    required List<Shift> shifts,
    required UserPayProfile profile,
    required Department department,
  }) {
    final sortedShifts = [...shifts]..sort((a, b) => a.start.compareTo(b.start));

    final computations = <Shift, DailyShiftComputation>{};
    double totalAmount = 0.0;
    double totalOvertimeHours = 0.0;

    final Map<String, double> breakdownTotals = {};

    for (final shift in sortedShifts) {
      final data = _buildShiftComputationUseCase.execute(
        shift: shift,
        profile: profile,
        department: department,
      );

      final computation = DailyShiftComputation(
        overtimeHours: data.overtimeHours,
        totalAmount: data.totalAmount,
        extraAmount: data.extraAmount,
        breakdown: data.breakdown,
      );

      computations[shift] = computation;
      totalAmount += computation.totalAmount;
      totalOvertimeHours += computation.overtimeHours;

      for (final item in computation.breakdown) {
        final label = (item['label'] as String?)?.trim();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

        if (label == null || label.isEmpty) continue;
        breakdownTotals[label] = (breakdownTotals[label] ?? 0.0) + amount;
      }
    }

    final mergedBreakdown = breakdownTotals.entries
        .map(
          (entry) => {
            'label': entry.key,
            'amount': entry.value,
          },
        )
        .toList();

    return DailyShiftComputationsResult(
      computations: computations,
      totalAmount: totalAmount,
      totalOvertimeHours: totalOvertimeHours,
      mergedBreakdown: mergedBreakdown,
    );
  }
}