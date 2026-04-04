import '../../shifts/presentation/models/shift.dart';
import 'allowance_calculation_result.dart';

class ShiftAllowanceResult {
  final Shift shift;
  final List<AllowanceCalculationResult> allowances;

  const ShiftAllowanceResult({
    required this.shift,
    required this.allowances,
  });

  double get totalMonthAmount {
    return allowances
        .where((a) => !a.goesToBasket)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double get totalBasketAmount {
    return allowances
        .where((a) => a.goesToBasket)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double get totalAmount => totalMonthAmount + totalBasketAmount;
}