import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_monthly_accessory_summary_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const useCase = BuildMonthlyAccessorySummaryUseCase();

  group('BuildMonthlyAccessorySummaryUseCase - RM', () {
    test('standard shift has no overtime gross', () {
      final summary = useCase.execute(
        month: DateTime(2026, 5),
        allShifts: [
          CanonicalShiftScenarios.rmStandardMorning(
            serviceDate: DateTime(2026, 5, 1),
          ),
        ],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.shiftCount, 1);
      expect(summary.overtimeHours, closeTo(0, 0.01));
      expect(summary.overtimeGross, closeTo(0, 0.01));
      expect(summary.rfiBasketGross, closeTo(0, 0.01));
      expect(summary.totalGross, closeTo(summary.nonOvertimeGross, 0.01));
    });

    test('long RM shift produces overtime gross and hours', () {
      final summary = useCase.execute(
        month: DateTime(2026, 5),
        allShifts: [
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 5, 2),
          ),
        ],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.shiftCount, 1);
      expect(summary.overtimeHours, closeTo(7, 0.01));
      expect(summary.overtimeGross, greaterThan(0));
      expect(
        summary.totalGross,
        closeTo(summary.nonOvertimeGross + summary.overtimeGross, 0.01),
      );
    });

    test('multiple shifts in same month are aggregated', () {
      final summary = useCase.execute(
        month: DateTime(2026, 5),
        allShifts: [
          CanonicalShiftScenarios.rmMorningWithHalfHourOvertime(
            serviceDate: DateTime(2026, 5, 1),
          ),
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 5, 2),
          ),
          CanonicalShiftScenarios.rmOpInSedeMixedOvertime(
            serviceDate: DateTime(2026, 5, 3),
          ),
        ],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.shiftCount, 3);
      expect(summary.overtimeHours, closeTo(10.5, 0.01));
      expect(summary.overtimeGross, greaterThan(0));
      expect(
        summary.totalGross,
        closeTo(summary.nonOvertimeGross + summary.overtimeGross, 0.01),
      );
    });

    test(
      'same-day additional services do not become basket overtime',
      () {
        final serviceDay = DateTime(2026, 7, 4);

        final overnightService = Shift(
          description: 'OP Roma via Montpellier',
          start: DateTime(2026, 7, 3, 20),
          end: DateTime(2026, 7, 4, 10),
          serviceDate: serviceDay,
          absence: 'Nessuna',
          orderPublic: 'Pernotto',
          externalService: false,
        );

        final lunch = Shift(
          description: 'Pranzo',
          start: DateTime(2026, 7, 4, 13),
          end: DateTime(2026, 7, 4, 15),
          serviceDate: serviceDay,
          absence: 'Nessuna',
          orderPublic: 'Nessuno',
          externalService: false,
        );

        final dinner = Shift(
          description: 'Cena',
          start: DateTime(2026, 7, 4, 19),
          end: DateTime(2026, 7, 4, 21),
          serviceDate: serviceDay,
          absence: 'Nessuna',
          orderPublic: 'Nessuno',
          externalService: false,
        );

        final summary = useCase.execute(
          month: DateTime(2026, 7),
          allShifts: [overnightService, lunch, dinner],
          profile: CanonicalShiftScenarios.defaultProfile(),
          department: Department.repartoMobile,
        );

        expect(overnightService.overtimeHours, closeTo(8, 0.01));
        expect(lunch.overtimeHours, closeTo(0, 0.01));
        expect(dinner.overtimeHours, closeTo(0, 0.01));
        expect(summary.shiftCount, 3);
        expect(summary.overtimeHours, closeTo(8, 0.01));
      },
    );

    test('filters shifts by selected month only', () {
      final may = useCase.execute(
        month: DateTime(2026, 5),
        allShifts: [
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 5, 2),
          ),
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 6, 2),
          ),
        ],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      final june = useCase.execute(
        month: DateTime(2026, 6),
        allShifts: [
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 5, 2),
          ),
          CanonicalShiftScenarios.rmLongMorningNightEdge(
            serviceDate: DateTime(2026, 6, 2),
          ),
        ],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(may.shiftCount, 1);
      expect(june.shiftCount, 1);
      expect(may.overtimeHours, closeTo(7, 0.01));
      expect(june.overtimeHours, closeTo(7, 0.01));
    });

    test('absence is counted but does not add gross or overtime', () {
      final summary = useCase.execute(
        month: DateTime(2026, 5),
        allShifts: [
          CanonicalShiftScenarios.absence(
            serviceDate: DateTime(2026, 5, 8),
          ),
        ],
        profile: CanonicalShiftScenarios.defaultProfile(),
        department: Department.repartoMobile,
      );

      expect(summary.shiftCount, 1);
      expect(summary.overtimeHours, closeTo(0, 0.01));
      expect(summary.overtimeGross, closeTo(0, 0.01));
      expect(summary.totalGross, closeTo(0, 0.01));
    });
  });
}
