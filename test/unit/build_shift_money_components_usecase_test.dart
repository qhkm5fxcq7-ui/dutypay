import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_shift_money_components_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';

import '../scenarios/canonical_shift_scenarios.dart';

void main() {
  const usecase = BuildShiftMoneyComponentsUseCase();

  group('BuildShiftMoneyComponentsUseCase - Reparto Mobile', () {
    test('RM standard morning -> no overtime, no RFI basket', () {
      final shift = CanonicalShiftScenarios.rmStandardMorning();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, 0);
      expect(result.overtimeGross, 0);
      expect(result.nonOvertimeGross, 0);
      expect(result.rfiBasketGross, 0);
    });

    test('RM half hour overtime -> overtime gross > 0', () {
      final shift = CanonicalShiftScenarios.rmMorningWithHalfHourOvertime();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, closeTo(0.5, 0.01));
      expect(result.overtimeGross, greaterThan(0));
      expect(result.rfiBasketGross, 0);
    });

    test('RM OP in sede mixed overtime -> overtime and non-overtime separated',
        () {
      final shift = CanonicalShiftScenarios.rmOpInSedeMixedOvertime();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, closeTo(3.0, 0.01));
      expect(result.overtimeGross, greaterThan(0));
      expect(result.nonOvertimeGross, greaterThan(0));
      expect(result.rfiBasketGross, 0);
    });
  });

  group('BuildShiftMoneyComponentsUseCase - Polfer', () {
    test('Polfer standard morning -> no overtime, no RFI basket', () {
      final shift = CanonicalShiftScenarios.polferStandardMorning();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0);
      expect(result.overtimeGross, 0);
      expect(result.rfiBasketGross, 0);
    });

    test('Polfer standard evening -> no overtime, non-overtime gross > 0', () {
      final shift = CanonicalShiftScenarios.polferStandardEvening();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0);
      expect(result.overtimeGross, 0);
      expect(result.nonOvertimeGross, greaterThan(0));
      expect(result.rfiBasketGross, 0);
    });

    test('Polfer with scalo intero -> RFI basket only, no overtime', () {
      final shift = CanonicalShiftScenarios.polferWithScaloIntero();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0);
      expect(result.overtimeGross, 0);
      expect(result.rfiBasketGross, greaterThan(0));
    });
  });

  group('Manual accessories', () {
    test('Compensazione -> non-overtime gross is 52.0', () {
      final shift = CanonicalShiftScenarios.shiftWithCompensazione();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeGross, 0);
      expect(result.rfiBasketGross, 0);
      expect(result.nonOvertimeGross, closeTo(52.0, 0.01));
    });

    test('Reperibilita -> non-overtime gross is 57.5', () {
      final shift = CanonicalShiftScenarios.shiftWithReperibilita();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeGross, 0);
      expect(result.rfiBasketGross, 0);
      expect(result.nonOvertimeGross, closeTo(57.5, 0.01));
    });

    test('Compensazione + Reperibilita -> non-overtime gross is 69.5', () {
      final shift = CanonicalShiftScenarios.shiftWithBothManualAccessories();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeGross, 0);
      expect(result.rfiBasketGross, 0);
      expect(result.nonOvertimeGross, closeTo(69.5, 0.01));
    });
  });
}
