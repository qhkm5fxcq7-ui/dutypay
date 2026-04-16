import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_shift_computation_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const useCase = BuildShiftComputationUseCase();
  final profile = CanonicalShiftScenarios.defaultProfile();

  group('Polfer - Regression', () {
    test('Mattina standard NON genera straordinario', () {
      final shift = CanonicalShiftScenarios.polferStandardMorning(
        serviceDate: DateTime(2026, 4, 1),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0.0);
      expect(result.totalAmount, 0.0);
    });

    test('Pomeriggio standard NON genera straordinario', () {
      final shift = CanonicalShiftScenarios.polferStandardAfternoon(
        serviceDate: DateTime(2026, 4, 1),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0.0);
      expect(result.totalAmount, 0.0);
    });

    test('Sera standard NON genera straordinario ma genera quota notturna', () {
      final shift = CanonicalShiftScenarios.polferStandardEvening(
        serviceDate: DateTime(2026, 4, 2),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0.0);
      expect(result.totalAmount, greaterThan(0));

      final hasNightAllowance = result.breakdown.any(
        (item) => item['category'] == 'ordinary_night',
      );
      expect(hasNightAllowance, isTrue);
    });

    test('Notte standard NON genera straordinario ma genera quota notturna', () {
      final shift = CanonicalShiftScenarios.polferStandardNight(
        serviceDate: DateTime(2026, 4, 2),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.overtimeHours, 0.0);
      expect(result.totalAmount, greaterThan(0));

      final hasNightAllowance = result.breakdown.any(
        (item) => item['category'] == 'ordinary_night',
      );
      expect(hasNightAllowance, isTrue);
    });

    test('Controllo territorio serale entra nel breakdown corretto', () {
      final shift = CanonicalShiftScenarios.polferWithTerritorySerale(
        serviceDate: DateTime(2026, 4, 3),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      final hasTerritory = result.breakdown.any(
        (item) => item['category'] == 'polfer_territory',
      );

      expect(result.overtimeHours, 0.0);
      expect(hasTerritory, isTrue);
      expect(result.totalAmount, greaterThan(0));
    });

    test('Scalo ridotto entra nel basket RFI e non negli extra', () {
      final shift = CanonicalShiftScenarios.polferWithScaloRidotto(
        serviceDate: DateTime(2026, 4, 2),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      final basketItems = result.breakdown.where(
        (item) => item['isBasketItem'] == true && item['basketKey'] == 'rfi',
      );

      expect(basketItems.isNotEmpty, isTrue);
      expect(result.totalAmount, greaterThan(0));
      expect(result.extraAmount, lessThan(result.totalAmount));
    });

    test('Scalo intero entra nel basket RFI e non genera straordinario', () {
      final shift = CanonicalShiftScenarios.polferWithScaloIntero(
        serviceDate: DateTime(2026, 4, 2),
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      final basketItems = result.breakdown.where(
        (item) => item['isBasketItem'] == true && item['basketKey'] == 'rfi',
      );

      expect(result.overtimeHours, 0.0);
      expect(basketItems.isNotEmpty, isTrue);
      expect(result.totalAmount, greaterThan(0));
    });

    test('Assenza restituisce zero', () {
      final shift = CanonicalShiftScenarios.absence(
        serviceDate: DateTime(2026, 4, 6),
        absenceCode: 'RIP',
      );

      final result = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalAmount, 0.0);
      expect(result.overtimeHours, 0.0);
      expect(result.breakdown.isEmpty, isTrue);
    });
  });
}