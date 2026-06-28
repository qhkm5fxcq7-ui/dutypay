import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/calculate_shift_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  const useCase = CalculateShiftUseCase();
  final profile = UserPayProfile.defaultProfile();

  group('Multi department regression', () {
    test('same 6h daytime shift is stable across departments', () {
      final shift = Shift(
        description: 'Turno base 6h',
        start: DateTime(2026, 5, 4, 8),
        end: DateTime(2026, 5, 4, 14),
        serviceDate: DateTime(2026, 5, 4),
        absence: 'Nessuna',
        questuraMode: QuesturaMode.uffici,
        questuraOfficeProfile: QuesturaOfficeProfile.sixHours,
        spmnPresetCode: 'mattina',
      );

      final rm = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final questura = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.questura,
      );

      final polfer = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.polfer,
      );

      expect(rm.overtimeHours, closeTo(0, 0.01));
      expect(questura.overtimeHours, closeTo(0, 0.01));
      expect(polfer.overtimeHours, greaterThanOrEqualTo(0));
    });

    test('same 8h daytime shift produces overtime in RM and Questura', () {
      final shift = Shift(
        description: 'Turno base 8h',
        start: DateTime(2026, 5, 4, 8),
        end: DateTime(2026, 5, 4, 16),
        serviceDate: DateTime(2026, 5, 4),
        absence: 'Nessuna',
        questuraMode: QuesturaMode.uffici,
        questuraOfficeProfile: QuesturaOfficeProfile.sixHours,
      );

      final rm = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final questura = useCase.execute(
        shift: shift,
        profile: profile,
        department: Department.questura,
      );

      expect(rm.overtimeHours, greaterThan(0));
      expect(questura.overtimeHours, greaterThan(0));
    });

    test('same cross-midnight shift stays non-negative across departments', () {
      final shift = Shift(
        description: 'Cross midnight',
        start: DateTime(2026, 5, 4, 18, 0),
        end: DateTime(2026, 5, 5, 1, 0),
        serviceDate: DateTime(2026, 5, 4),
        absence: 'Nessuna',
        questuraMode: QuesturaMode.volanti,
        questuraPreset: QuesturaPreset.sera,
        spmnPresetCode: 'sera',
      );

      for (final department in [
        Department.repartoMobile,
        Department.questura,
        Department.polfer,
        Department.polstrada,
      ]) {
        final result = useCase.execute(
          shift: shift,
          profile: profile,
          department: department,
        );

        expect(result.overtimeHours, greaterThanOrEqualTo(0));
        expect(result.totalGross, greaterThanOrEqualTo(0));
      }
    });

    test('absence returns empty calculation for every department', () {
      final shift = Shift(
        description: 'Assenza',
        absence: 'MAL',
      );

      for (final department in [
        Department.repartoMobile,
        Department.questura,
        Department.polfer,
        Department.polstrada,
      ]) {
        final result = useCase.execute(
          shift: shift,
          profile: profile,
          department: department,
        );

        expect(result.overtimeHours, closeTo(0, 0.01));
        expect(result.totalGross, closeTo(0, 0.01));
        expect(result.breakdown, isEmpty);
      }
    });
  });
}
