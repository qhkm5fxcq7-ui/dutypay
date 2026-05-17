import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  test('Polfer preset mattina standard non genera falso straordinario', () {
    final shift = Shift(
      description: 'Turno Mattina',
      start: DateTime(2026, 5, 19, 6, 55),
      end: DateTime(2026, 5, 19, 13, 8),
      serviceDate: DateTime(2026, 5, 19),
      spmnPresetCode: 'mattina',
    );

    const useCase = BuildDailyShiftResultUseCase();

    final result = useCase.execute(
      shifts: [shift],
      profile: UserPayProfile.defaultProfile(),
      department: Department.polfer,
    );

    final computation = result.computations[shift];

    expect(computation, isNotNull);
    expect(computation!.overtimeHours, closeTo(0.0, 0.01));
    expect(result.totalOvertimeHours, closeTo(0.0, 0.01));
  });

  test('Polfer preset sera standard non genera falso straordinario', () {
    final shift = Shift(
      description: 'Turno Sera',
      start: DateTime(2026, 5, 19, 18, 55),
      end: DateTime(2026, 5, 20, 0, 8),
      serviceDate: DateTime(2026, 5, 20),
      spmnPresetCode: 'sera',
    );

    const useCase = BuildDailyShiftResultUseCase();

    final result = useCase.execute(
      shifts: [shift],
      profile: UserPayProfile.defaultProfile(),
      department: Department.polfer,
    );

    final computation = result.computations[shift];

    expect(computation, isNotNull);
    expect(computation!.overtimeHours, closeTo(0.0, 0.01));
    expect(result.totalOvertimeHours, closeTo(0.0, 0.01));
  });

  test('Polfer preset notte standard non genera falso straordinario', () {
    final shift = Shift(
      description: 'Turno Notte',
      start: DateTime(2026, 5, 19, 23, 55),
      end: DateTime(2026, 5, 20, 7, 8),
      serviceDate: DateTime(2026, 5, 20),
      spmnPresetCode: 'notte',
    );

    const useCase = BuildDailyShiftResultUseCase();

    final result = useCase.execute(
      shifts: [shift],
      profile: UserPayProfile.defaultProfile(),
      department: Department.polfer,
    );

    final computation = result.computations[shift];

    expect(computation, isNotNull);
    expect(computation!.overtimeHours, closeTo(0.0, 0.01));
    expect(result.totalOvertimeHours, closeTo(0.0, 0.01));
  });

  test(
    'Polfer preset notte anticipato mantiene logica preset senza falso straordinario',
    () {
      final shift = Shift(
        description: 'Turno Notte Anticipato',
        start: DateTime(2026, 5, 19, 22, 30),
        end: DateTime(2026, 5, 20, 7, 8),
        serviceDate: DateTime(2026, 5, 20),
        spmnPresetCode: 'notte',
      );

      const useCase = BuildDailyShiftResultUseCase();

      final result = useCase.execute(
        shifts: [shift],
        profile: UserPayProfile.defaultProfile(),
        department: Department.polfer,
      );

      final computation = result.computations[shift];

      expect(computation, isNotNull);
      expect(computation!.overtimeHours, closeTo(0.0, 0.01));
      expect(result.totalOvertimeHours, closeTo(0.0, 0.01));
    },
  );

  test(
  'Polfer preset notte con uscita posticipata genera solo extra oltre chiusura teorica',
  () {
    final shift = Shift(
      description: 'Turno Notte Posticipato',
      start: DateTime(2026, 5, 19, 23, 55),
      end: DateTime(2026, 5, 20, 8, 8),
      serviceDate: DateTime(2026, 5, 20),
      spmnPresetCode: 'notte',
    );

    const useCase = BuildDailyShiftResultUseCase();

    final result = useCase.execute(
      shifts: [shift],
      profile: UserPayProfile.defaultProfile(),
      department: Department.polfer,
    );

    final computation = result.computations[shift];

    expect(computation, isNotNull);
    expect(computation!.overtimeHours, closeTo(1.0, 0.01));
    expect(result.totalOvertimeHours, closeTo(1.0, 0.01));
  },
);
}