import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_monthly_summary_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const useCase = BuildMonthlySummaryUseCase();

  group('BuildMonthlySummaryUseCase - RM', () {
    test('empty month returns zero totals', () {
      final summary = useCase.execute(
        shifts: const [],
        selectedMonth: DateTime(2026, 5),
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.totalAmount, closeTo(0, 0.01));
      expect(summary.totalOvertimeHours, closeTo(0, 0.01));
      expect(summary.workedDays, 0);
      expect(summary.averagePerDay, closeTo(0, 0.01));
      expect(summary.rfiBasketAmount, closeTo(0, 0.01));
      expect(summary.daysInMonth, 31);
    });

    test('standard shift counts one worked day but no overtime', () {
      final summary = useCase.execute(
        shifts: [
          CanonicalShiftScenarios.rmStandardMorning(
            serviceDate: DateTime(2026, 5, 1),
          ),
        ],
        selectedMonth: DateTime(2026, 5),
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.workedDays, 1);
      expect(summary.totalOvertimeHours, closeTo(0, 0.01));
      expect(summary.totalAmount, greaterThan(0));
      expect(summary.averagePerDay, closeTo(summary.totalAmount, 0.01));
    });

    test('long shift adds overtime and amount', () {
      final summary = useCase.execute(
        shifts: [
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 5, 2),
          ),
        ],
        selectedMonth: DateTime(2026, 5),
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.workedDays, 1);
      expect(summary.totalOvertimeHours, closeTo(7, 0.01));
      expect(summary.totalAmount, greaterThan(0));
      expect(summary.averagePerDay, closeTo(summary.totalAmount, 0.01));
    });

    test('multiple shifts on same day count as one worked day', () {
      final day = DateTime(2026, 5, 3);

      final summary = useCase.execute(
        shifts: [
          CanonicalShiftScenarios.rmStandardMorning(serviceDate: day),
          CanonicalShiftScenarios.rmMorningWithHalfHourOvertime(
            serviceDate: day,
          ),
        ],
        selectedMonth: DateTime(2026, 5),
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.workedDays, 1);
      expect(summary.totalOvertimeHours, greaterThan(0));
      expect(summary.totalAmount, greaterThanOrEqualTo(0));
    });

    test(
      'RM overnight service keeps accounting date and does not consume previous day ordinary hours',
      () {
        final morningDay = DateTime(2026, 7, 3);
        final accountingDay = DateTime(2026, 7, 4);

        final morningShift = CanonicalShiftScenarios.rmStandardMorning(
          serviceDate: morningDay,
          description: 'Mattina 3 luglio',
        );

        final overnightShift = Shift(
          description: 'OP pernottamento',
          start: DateTime(2026, 7, 3, 20, 0),
          end: DateTime(2026, 7, 4, 10, 0),
          serviceDate: accountingDay,
          absence: 'Nessuna',
          orderPublic: 'Pernotto',
          externalService: false,
        );

        final summary = useCase.execute(
          shifts: [morningShift, overnightShift],
          selectedMonth: DateTime(2026, 7),
          profile: CanonicalShiftScenarios.defaultProfile(),
          department: Department.repartoMobile,
        );

        expect(overnightShift.serviceDate, accountingDay);
        expect(overnightShift.workedHours, closeTo(14, 0.01));
        expect(overnightShift.overtimeHours, closeTo(8, 0.01));
        expect(summary.workedDays, 2);
        expect(summary.totalOvertimeHours, closeTo(8, 0.01));
      },
    );

    test('filters shifts outside selected month', () {
      final summary = useCase.execute(
        shifts: [
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 5, 2),
          ),
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 6, 2),
          ),
        ],
        selectedMonth: DateTime(2026, 5),
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.workedDays, 1);
      expect(summary.totalOvertimeHours, closeTo(7, 0.01));
    });

    test('absence does not count as worked day', () {
      final summary = useCase.execute(
        shifts: [
          CanonicalShiftScenarios.absence(
            serviceDate: DateTime(2026, 5, 8),
          ),
        ],
        selectedMonth: DateTime(2026, 5),
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.workedDays, 0);
      expect(summary.totalOvertimeHours, closeTo(0, 0.01));
      expect(summary.totalAmount, closeTo(0, 0.01));
      expect(summary.averagePerDay, closeTo(0, 0.01));
    });
  });
}
