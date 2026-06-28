import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

import '../scenarios/canonical_shift_scenarios.dart';

void main() {
  const useCase = BuildDailyShiftResultUseCase();
  final profile = UserPayProfile.defaultProfile();

  group('Polfer regression pack', () {
    test('preset mattina non genera falso straordinario', () {
      final shift = CanonicalShiftScenarios.polferStandardMorning();

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
    });

    test('preset pomeriggio non genera falso straordinario', () {
      final shift = CanonicalShiftScenarios.polferStandardAfternoon();

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
    });

    test('preset sera cross-midnight resta stabile', () {
      final shift = CanonicalShiftScenarios.polferStandardEvening();

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.totalAmount, greaterThanOrEqualTo(0));
      expect(result.computations[shift], isNotNull);
    });

    test('preset notte cross-midnight resta stabile', () {
      final shift = CanonicalShiftScenarios.polferStandardNight();

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.totalAmount, greaterThanOrEqualTo(0));
      expect(result.computations[shift], isNotNull);
    });

    test('uscita posticipata dopo notte genera straordinario', () {
      final shift = Shift(
        description: 'Polfer notte posticipata',
        start: DateTime(2026, 5, 19, 23, 55),
        end: DateTime(2026, 5, 20, 8, 8),
        serviceDate: DateTime(2026, 5, 20),
        absence: 'Nessuna',
        spmnPresetCode: 'notte',
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalOvertimeHours, closeTo(1, 0.01));
    });

    test('scalo ridotto entra nel basket RFI', () {
      final shift = CanonicalShiftScenarios.polferWithScaloRidotto();

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.rfiBasketAmount, greaterThan(0));
    });

    test('scalo intero entra nel basket RFI', () {
      final shift = CanonicalShiftScenarios.polferWithScaloIntero();

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.rfiBasketAmount, greaterThan(0));
    });

    test('scalo manuale include lo straordinario programmato nelle ore distribuibili', () {
      final day = DateTime(2026, 5, 20);

      final shift = Shift(
        description: 'Scalo manuale con programmato',
        start: DateTime(day.year, day.month, day.day, 7, 0),
        end: DateTime(day.year, day.month, day.day, 14, 0),
        serviceDate: day,
        absence: 'Nessuna',
        spmnPresetCode: 'mattina',
        polferScaloManualOverride: true,
        polferScaloReducedDayHours: 8,
        polferScaloReducedNightHours: 0,
        polferScaloFullDayHours: 2,
        polferScaloFullNightHours: 0,
        programmedOvertimeEnabled: true,
        programmedOvertimeStart: DateTime(day.year, day.month, day.day, 14, 0),
        programmedOvertimeEnd: DateTime(day.year, day.month, day.day, 17, 0),
        programmedOvertimeNote: 'Programmato test',
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      final computation = result.computations[shift];

      expect(computation, isNotNull);
      expect(result.totalOvertimeHours, greaterThanOrEqualTo(3));
      expect(computation!.breakdown, isNotEmpty);
    });

    test('assenza Polfer produce zero', () {
      final shift = CanonicalShiftScenarios.absence(
        absenceCode: 'MAL',
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.polfer,
      );

      expect(result.totalAmount, closeTo(0, 0.01));
      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.rfiBasketAmount, closeTo(0, 0.01));
    });
  });
}
