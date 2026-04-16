import '../../presentation/models/shift.dart';
import 'daily_shift_computation.dart';

class DailyShiftResult {
  final Map<Shift, DailyShiftComputation> computations;
  final double totalAmount;
  final double totalOvertimeHours;
  final List<Map<String, dynamic>> mergedBreakdown;
  final double rfiBasketAmount;

  const DailyShiftResult({
    required this.computations,
    required this.totalAmount,
    required this.totalOvertimeHours,
    required this.mergedBreakdown,
    required this.rfiBasketAmount,
  });
}