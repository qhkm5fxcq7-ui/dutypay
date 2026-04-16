import '../../entities/shift.dart';
import '../../entities/user_pay_profile.dart';
import '../models/shift_calculation_result.dart';

abstract class DepartmentPolicy {
  ShiftCalculationResult calculateShift(
    Shift shift,
    UserPayProfile profile,
  );
}