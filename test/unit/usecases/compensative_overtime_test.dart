import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  test('compensativo parziale separa solo le ore indicate dal totale pagato', () {
    final profile = UserPayProfile.defaultProfile();

    final shift = Shift(
      description: 'Rientro programmato',
      start: DateTime(2026, 5, 11, 7),
end: DateTime(2026, 5, 11, 18),
serviceDate: DateTime(2026, 5, 11),
      overtimeDestination: OvertimeDestination.compensative,
      compensativeOvertimeHours: 3,
      compensativeOvertimeNote: '13-16 recupero',
    );

    final result = const BuildDailyShiftResultUseCase().execute(
      shifts: [shift],
      profile: profile,
      department: Department.repartoMobile,
    );

    expect(result.totalOvertimeHours, closeTo(5.0, 0.01));
    expect(result.compensativeHours, closeTo(3.0, 0.01));
    expect(result.compensativeGrossEstimate, closeTo(36.00, 0.20));
expect(result.totalAmount, closeTo(24.00, 0.20));
  });
}