import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_shift_computation_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const usecase = BuildShiftComputationUseCase();

  Map<String, dynamic> findItemByCategory(
    List<Map<String, dynamic>> breakdown,
    String category,
  ) {
    return breakdown.firstWhere(
      (item) => item['category'] == category,
      orElse: () => <String, dynamic>{},
    );
  }

  group('Manual accessories', () {
    test('Compensazione appears in breakdown and contributes to totals', () {
      final shift = CanonicalShiftScenarios.shiftWithCompensazione();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final compensazioneItem = findItemByCategory(
        result.breakdown,
        'compensazione',
      );

      expect(compensazioneItem.isNotEmpty, true);
      expect(
        (compensazioneItem['amount'] as num).toDouble(),
        closeTo(12.0, 0.01),
      );

      expect(result.extraAmount, greaterThanOrEqualTo(12.0));
      expect(result.totalAmount, greaterThanOrEqualTo(12.0));
    });

    test('Reperibilita appears in breakdown and contributes to totals', () {
      final shift = CanonicalShiftScenarios.shiftWithReperibilita();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final reperibilitaItem = findItemByCategory(
        result.breakdown,
        'reperibilita',
      );

      expect(reperibilitaItem.isNotEmpty, true);
      expect(
        (reperibilitaItem['amount'] as num).toDouble(),
        closeTo(17.5, 0.01),
      );

      expect(result.extraAmount, greaterThanOrEqualTo(17.5));
      expect(result.totalAmount, greaterThanOrEqualTo(17.5));
    });

    test('Compensazione + Reperibilita both appear and sum correctly', () {
      final shift = CanonicalShiftScenarios.shiftWithBothManualAccessories();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final compensazioneItem = findItemByCategory(
        result.breakdown,
        'compensazione',
      );
      final reperibilitaItem = findItemByCategory(
        result.breakdown,
        'reperibilita',
      );

      expect(compensazioneItem.isNotEmpty, true);
      expect(reperibilitaItem.isNotEmpty, true);

      expect(
        (compensazioneItem['amount'] as num).toDouble(),
        closeTo(12.0, 0.01),
      );
      expect(
        (reperibilitaItem['amount'] as num).toDouble(),
        closeTo(17.5, 0.01),
      );

      final manualAccessoriesSum =
          (compensazioneItem['amount'] as num).toDouble() +
          (reperibilitaItem['amount'] as num).toDouble();

      expect(manualAccessoriesSum, closeTo(29.5, 0.01));
      expect(result.extraAmount, greaterThanOrEqualTo(29.5));
      expect(result.totalAmount, greaterThanOrEqualTo(29.5));
    });

    test('Manual accessories do not enter RFI basket logic', () {
      final shift = CanonicalShiftScenarios.shiftWithBothManualAccessories();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final basketItems = result.breakdown.where(
        (item) => item['isBasketItem'] == true,
      );

      expect(basketItems.isEmpty, true);
    });

    test('Manual accessories do not create overtime', () {
      final shift = CanonicalShiftScenarios.shiftWithBothManualAccessories();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, 0);
    });
  });

  group('Manual accessories - Polfer compatibility', () {
    test('Compensazione works also in Polfer flow', () {
      final shift = CanonicalShiftScenarios.shiftWithCompensazione();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      final compensazioneItem = findItemByCategory(
        result.breakdown,
        'compensazione',
      );

      expect(compensazioneItem.isNotEmpty, true);
      expect(
        (compensazioneItem['amount'] as num).toDouble(),
        closeTo(12.0, 0.01),
      );
    });

    test('Reperibilita works also in Polfer flow', () {
      final shift = CanonicalShiftScenarios.shiftWithReperibilita();
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = usecase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      final reperibilitaItem = findItemByCategory(
        result.breakdown,
        'reperibilita',
      );

      expect(reperibilitaItem.isNotEmpty, true);
      expect(
        (reperibilitaItem['amount'] as num).toDouble(),
        closeTo(17.5, 0.01),
      );
    });
  });
}