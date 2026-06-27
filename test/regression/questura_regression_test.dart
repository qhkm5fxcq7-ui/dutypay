import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  const useCase = BuildDailyShiftResultUseCase();
  final profile = UserPayProfile.defaultProfile();

  group('Questura regression', () {
    test('ufficio 6h standard non genera straordinario', () {
      final shift = Shift(
        description: 'Ufficio 6h',
        start: DateTime(2026, 5, 4, 8),
        end: DateTime(2026, 5, 4, 14),
        serviceDate: DateTime(2026, 5, 4),
        questuraMode: QuesturaMode.uffici,
        questuraOfficeProfile: QuesturaOfficeProfile.sixHours,
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.questura,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
      expect(result.computations[shift], isNotNull);
    });

    test('ufficio 7h genera straordinario', () {
      final shift = Shift(
        description: 'Ufficio 7h',
        start: DateTime(2026, 5, 4, 8),
        end: DateTime(2026, 5, 4, 15),
        serviceDate: DateTime(2026, 5, 4),
        questuraMode: QuesturaMode.uffici,
        questuraOfficeProfile: QuesturaOfficeProfile.sixHours,
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.questura,
      );

      expect(result.totalOvertimeHours, greaterThan(0));
    });

    test('volante mattina standard non genera straordinario', () {
      final shift = Shift(
        description: 'Volante mattina',
        start: DateTime(2026, 5, 4, 7),
        end: DateTime(2026, 5, 4, 13),
        serviceDate: DateTime(2026, 5, 4),
        questuraMode: QuesturaMode.volanti,
        questuraPreset: QuesturaPreset.mattina,
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.questura,
      );

      expect(result.totalOvertimeHours, closeTo(0, 0.01));
    });

    test('volante notte cross-midnight non esplode', () {
      final shift = Shift(
        description: 'Volante notte',
        start: DateTime(2026, 5, 4, 19),
        end: DateTime(2026, 5, 5, 1),
        serviceDate: DateTime(2026, 5, 4),
        questuraMode: QuesturaMode.volanti,
        questuraPreset: QuesturaPreset.notte,
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.questura,
      );

      expect(result.computations[shift], isNotNull);
      expect(result.totalOvertimeHours, greaterThanOrEqualTo(0));
    });

    test('assenza produce zero', () {
      final shift = Shift(
        description: 'Assenza',
        absence: 'MAL',
      );

      final result = useCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.questura,
      );

      expect(result.totalAmount, closeTo(0, 0.01));
      expect(result.totalOvertimeHours, closeTo(0, 0.01));
    });
  });
}
