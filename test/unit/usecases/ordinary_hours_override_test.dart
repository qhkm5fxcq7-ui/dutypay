import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  test('orario in deroga: 5h ordinarie su 7h lavorate genera 2h straordinario', () {
    final shift = Shift(
      description: 'Turno con orario in deroga',
      start: DateTime(2026, 5, 19, 7),
      end: DateTime(2026, 5, 19, 14),
      serviceDate: DateTime(2026, 5, 19),
      ordinaryHoursOverrideEnabled: true,
      ordinaryHoursOverride: 5.0,
      ordinaryHoursOverrideNote: 'Ordinario previsto 5h',
    );

    const useCase = BuildDailyShiftResultUseCase();

    final result = useCase.execute(
      shifts: [shift],
      profile: UserPayProfile.defaultProfile(),
      department: Department.repartoMobile,
    );

    final computation = result.computations[shift];

    expect(computation, isNotNull);
    expect(computation!.overtimeHours, closeTo(2.0, 0.01));
    expect(result.totalOvertimeHours, closeTo(2.0, 0.01));
  });
}