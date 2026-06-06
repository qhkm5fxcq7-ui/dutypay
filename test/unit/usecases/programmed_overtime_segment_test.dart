import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  final useCase = BuildDailyShiftResultUseCase();
  final profile = UserPayProfile.defaultProfile();

  test('programmato: 07-16 con programmato 13-16 genera 3h overtime', () {
    final shift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 16),
      programmedOvertimeEnabled: true,
      programmedOvertimeStart: DateTime(2026, 5, 4, 13),
      programmedOvertimeEnd: DateTime(2026, 5, 4, 16),
    );

    final result = useCase.execute(
      shifts: [shift],
      profile: profile,
      department: Department.repartoMobile,
    );

    expect(result.totalOvertimeHours, closeTo(3.0, 0.01));
  });

  test('programmato compensativo: 3h non entrano nel pagato', () {
    final shift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 16),
      programmedOvertimeEnabled: true,
      programmedOvertimeStart: DateTime(2026, 5, 4, 13),
      programmedOvertimeEnd: DateTime(2026, 5, 4, 16),
      overtimeDestination: OvertimeDestination.compensative,
    );

    final result = useCase.execute(
      shifts: [shift],
      profile: profile,
      department: Department.repartoMobile,
    );

    expect(result.compensativeHours, closeTo(3.0, 0.01));
    expect(result.totalOvertimeHours, closeTo(3.0, 0.01));
    expect(result.totalAmount, closeTo(0.0, 0.01));
  });

  test('programmato fuori range turno viene conteggiato integralmente', () {
    final shift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 13),
      programmedOvertimeEnabled: true,
      programmedOvertimeStart: DateTime(2026, 5, 4, 12),
      programmedOvertimeEnd: DateTime(2026, 5, 4, 18),
    );

    final result = useCase.execute(
      shifts: [shift],
      profile: profile,
      department: Department.repartoMobile,
    );

    expect(result.totalOvertimeHours, closeTo(6.0, 0.01));
  });
}