import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_shift_computation_usecase.dart';
import 'package:dutypay/features/shifts/application/usecases/calculate_shift_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const viewUseCase = BuildShiftComputationUseCase();
  const engineUseCase = CalculateShiftUseCase();
  final profile = CanonicalShiftScenarios.defaultProfile();

  double _hoursByCategory(
    List<Map<String, dynamic>> breakdown,
    String category,
  ) {
    return breakdown
        .where((item) => item['category'] == category)
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['hours'] as num?)?.toDouble() ?? 0.0),
        );
  }

  group('Reparto Mobile - Regression', () {
    test('Turno standard 6h NON genera straordinario', () {
      final shift = CanonicalShiftScenarios.rmStandardMorning(
        serviceDate: DateTime(2026, 4, 10),
      );

      final result = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, 0.0);
      expect(result.totalAmount, 0.0);
    });

    test('Turno con mezzora oltre le 6h genera straordinario', () {
      final shift = CanonicalShiftScenarios.rmMorningWithHalfHourOvertime(
        serviceDate: DateTime(2026, 4, 2),
      );

      final result = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, closeTo(0.5, 0.01));
      expect(result.totalAmount, greaterThan(0));
    });

    test('Turno lungo OP fuori sede genera straordinario', () {
      final shift = CanonicalShiftScenarios.rmLongOpFuoriSede(
        serviceDate: DateTime(2026, 4, 10),
      );

      final result = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, closeTo(5.0, 0.01));
      expect(result.totalAmount, greaterThan(0));

      final hasOrderPublic = result.breakdown.any(
        (item) => item['category'] == 'order_public',
      );
      expect(hasOrderPublic, isTrue);
    });

    test('Turno lungo con bordo notturno mantiene breakdown coerente', () {
      final shift = CanonicalShiftScenarios.rmLongMorningNightEdge(
        serviceDate: DateTime(2026, 4, 2),
      );

      final result = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, closeTo(7.0, 0.01));
      expect(result.totalAmount, greaterThan(0));

      final hasOvertime = result.breakdown.any(
        (item) =>
            (item['category'] as String?)?.startsWith('overtime') == true,
      );
      expect(hasOvertime, isTrue);
    });

    test('Turno OP in sede con overtime misto ha breakdown overtime', () {
      final shift = CanonicalShiftScenarios.rmOpInSedeMixedOvertime(
        serviceDate: DateTime(2026, 4, 15),
      );

      final result = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHours, closeTo(3.0, 0.01));
      expect(result.totalAmount, greaterThan(0));

      final hasOvertimeEntry = result.breakdown.any(
        (item) => ((item['category'] as String?) ?? '').contains('overtime'),
      );

      expect(hasOvertimeEntry, isTrue);
    });

    test('RM 17:00 -> 23:00 riconosce 1h notturna ordinaria senza straordinario', () {
      final shift = CanonicalShiftScenarios.rmEveningSixHoursWithOrdinaryNight(
        serviceDate: DateTime(2026, 4, 10),
      );

      final engineResult = engineUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final viewResult = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(engineResult.workedHours, closeTo(6.0, 0.01));
      expect(engineResult.overtimeHours, closeTo(0.0, 0.01));
      expect(engineResult.nightOrdinaryHours, closeTo(1.0, 0.01));
      expect(engineResult.overtimeNightHours, closeTo(0.0, 0.01));

      expect(
        _hoursByCategory(viewResult.breakdown, 'ordinary_night'),
        closeTo(1.0, 0.01),
      );
      expect(
        _hoursByCategory(viewResult.breakdown, 'overtime_night'),
        closeTo(0.0, 0.01),
      );
    });

        test('RM 17:00 -> 01:00 separa notturno ordinario e notturno straordinario', () {
      final shift =
          CanonicalShiftScenarios.rmEveningWithOrdinaryAndOvertimeNight(
        serviceDate: DateTime(2026, 4, 10),
      );

      final engineResult = engineUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final viewResult = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(engineResult.workedHours, closeTo(8.0, 0.01));
      expect(engineResult.overtimeHours, closeTo(2.0, 0.01));
      expect(engineResult.nightOrdinaryHours, closeTo(1.0, 0.01));
      expect(engineResult.overtimeNightHours, closeTo(2.0, 0.01));
      expect(engineResult.overtimeDayHours, closeTo(0.0, 0.01));
      expect(engineResult.overtimeHolidayDayHours, closeTo(0.0, 0.01));
      expect(engineResult.overtimeNightHolidayHours, closeTo(0.0, 0.01));

      expect(
        _hoursByCategory(viewResult.breakdown, 'ordinary_night'),
        closeTo(1.0, 0.01),
      );
      expect(
        _hoursByCategory(viewResult.breakdown, 'overtime_night'),
        closeTo(2.0, 0.01),
      );
      expect(
        _hoursByCategory(viewResult.breakdown, 'overtime_day'),
        closeTo(0.0, 0.01),
      );
      expect(
        _hoursByCategory(viewResult.breakdown, 'overtime_holiday_day'),
        closeTo(0.0, 0.01),
      );
      expect(
        _hoursByCategory(viewResult.breakdown, 'overtime_night_holiday'),
        closeTo(0.0, 0.01),
      );
    });

    test('Assenza restituisce zero', () {
      final shift = CanonicalShiftScenarios.absence(
        serviceDate: DateTime(2026, 4, 6),
        absenceCode: 'C.O.',
      );

      final result = viewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(result.totalAmount, 0.0);
      expect(result.overtimeHours, 0.0);
      expect(result.breakdown.isEmpty, isTrue);
    });
  });
}