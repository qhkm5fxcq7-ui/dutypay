import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const useCase = BuildDailyShiftResultUseCase();

  group('BuildDailyShiftResultUseCase - Reparto Mobile', () {
    test('standard 6h morning has no overtime', () {
      final shift = CanonicalShiftScenarios.rmStandardMorning();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(shift.workedHours, closeTo(6, 0.01));
      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.totalAmount, closeTo(0, 0.01));
    });

    test('morning with half hour extra produces 0.5h overtime', () {
      final shift = CanonicalShiftScenarios.rmMorningWithHalfHourOvertime();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(shift.workedHours, closeTo(6.5, 0.01));
      expect(result.totalOvertimeHours, closeTo(0.5, 0.01));
      expect(result.totalAmount, greaterThan(0));
    });

    test('long 13h morning produces 7h overtime', () {
      final shift = CanonicalShiftScenarios.rmLongMorningNightEdge();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(shift.workedHours, closeTo(13, 0.01));
      expect(result.totalOvertimeHours, closeTo(7, 0.01));
      expect(result.totalAmount, greaterThan(0));
    });

    test('OP in sede 15-00 produces 3h overtime', () {
      final shift = CanonicalShiftScenarios.rmOpInSedeMixedOvertime();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(shift.workedHours, closeTo(9, 0.01));
      expect(result.totalOvertimeHours, closeTo(3, 0.01));
      expect(result.totalAmount, greaterThan(0));
    });

    test('evening 17-23 has ordinary night but no overtime', () {
      final shift = CanonicalShiftScenarios.rmEveningSixHoursWithOrdinaryNight();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(shift.workedHours, closeTo(6, 0.01));
      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.totalAmount, closeTo(0, 0.01));
    });

    test('evening 17-01 has ordinary night and overtime night', () {
      final shift =
          CanonicalShiftScenarios.rmEveningWithOrdinaryAndOvertimeNight();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(shift.workedHours, closeTo(8, 0.01));
      expect(result.totalOvertimeHours, closeTo(2, 0.01));
      expect(result.totalAmount, greaterThan(0));
    });

    test('absence produces no worked hours, overtime or amount', () {
      final shift = CanonicalShiftScenarios.absence();

      final result = useCase.execute(
        shifts: [shift],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.totalAmount, closeTo(0, 0.01));
    });
  });
}
