import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/calculate_shift_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const useCase = CalculateShiftUseCase();
  final profile = CanonicalShiftScenarios.defaultProfile();

  group('CalculateShiftUseCase - RM engine', () {
    test('standard 6h morning has no overtime', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.rmStandardMorning(),
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.workedHours, closeTo(6, 0.01));
      expect(result.overtimeHours, closeTo(0, 0.01));
      expect(result.totalGross, closeTo(0, 0.01));
    });

    test('6h30 morning has 0.5h overtime day', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.rmMorningWithHalfHourOvertime(),
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.workedHours, closeTo(6.5, 0.01));
      expect(result.overtimeHours, closeTo(0.5, 0.01));
      expect(result.overtimeDayHours, closeTo(0.5, 0.01));
      expect(result.totalGross, greaterThan(0));
    });

    test('17-23 has 1h ordinary night and no overtime', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.rmEveningSixHoursWithOrdinaryNight(),
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.workedHours, closeTo(6, 0.01));
      expect(result.overtimeHours, closeTo(0, 0.01));
      expect(result.nightOrdinaryHours, closeTo(1, 0.01));
      expect(result.overtimeNightHours, closeTo(0, 0.01));
    });

    test('17-01 separates ordinary night and overtime night', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.rmEveningWithOrdinaryAndOvertimeNight(),
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.workedHours, closeTo(8, 0.01));
      expect(result.overtimeHours, closeTo(2, 0.01));
      expect(result.nightOrdinaryHours, closeTo(1, 0.01));
      expect(result.overtimeNightHours, closeTo(2, 0.01));
      expect(result.overtimeDayHours, closeTo(0, 0.01));
    });

    test('absence returns empty result', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.absence(),
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.workedHours, closeTo(0, 0.01));
      expect(result.overtimeHours, closeTo(0, 0.01));
      expect(result.totalGross, closeTo(0, 0.01));
      expect(result.breakdown, isEmpty);
    });
  });

  group('CalculateShiftUseCase - Polfer engine', () {
    test('standard morning has no overtime', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.polferStandardMorning(),
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, closeTo(0, 0.01));
      expect(result.totalGross, closeTo(0, 0.01));
    });

    test('standard evening has ordinary night amount without overtime', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.polferStandardEvening(),
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, closeTo(0, 0.01));
      expect(result.nightOrdinaryHours, greaterThan(0));
      expect(result.totalGross, greaterThan(0));
    });

    test('standard night has ordinary night amount without overtime', () {
      final result = useCase.execute(
        shift: CanonicalShiftScenarios.polferStandardNight(),
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, closeTo(0, 0.01));
      expect(result.nightOrdinaryHours, greaterThan(0));
      expect(result.totalGross, greaterThan(0));
    });
  });
}
