import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/domain/engine/models/basket_payment.dart';
import 'package:dutypay/features/shifts/domain/engine/models/overtime_basket_adjustment.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_projection_service.dart';

import '../scenarios/canonical_shift_scenarios.dart';

void main() {
  const service = PayslipProjectionService();

  group('Overtime basket regression', () {
    test('manual basket payment reduces current residual hours', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final shifts = [
        CanonicalShiftScenarios.rmLongMorningNightEdge(
          serviceDate: DateTime(2026, 1, 5),
        ),
        CanonicalShiftScenarios.rmLongMorningNightEdge(
          serviceDate: DateTime(2026, 2, 5),
        ),
        CanonicalShiftScenarios.rmLongMorningNightEdge(
          serviceDate: DateTime(2026, 3, 5),
        ),
      ];

      final withoutPayment = service.projectPayslip(
        payslipMonth: DateTime(2026, 6),
        allShifts: shifts,
        payProfile: profile.copyWith(
          monthlyOvertimePayableHoursLimit: 0,
        ),
        department: Department.repartoMobile,
      );

      final withPayment = service.projectPayslip(
        payslipMonth: DateTime(2026, 6),
        allShifts: shifts,
        payProfile: profile.copyWith(
          monthlyOvertimePayableHoursLimit: 0,
        ),
        department: Department.repartoMobile,
        basketPayments: [
          BasketPayment(
            paymentMonth: DateTime(2026, 5),
            hoursPaid: 5,
            note: 'Pagamento basket test',
          ),
        ],
      );

      expect(withoutPayment.currentBasketResidualHours, greaterThan(0));

      expect(
        withPayment.currentBasketResidualHours,
        closeTo(
          withoutPayment.currentBasketResidualHours - 5,
          0.01,
        ),
      );
    });


    test('monthly basket cap uses full daily context for double services', () {
      final profile = CanonicalShiftScenarios.defaultProfile().copyWith(
        monthlyOvertimePayableHoursLimit: 5,
      );

      final day = DateTime(2026, 5, 10);

      final shifts = [
        Shift(
          description: 'Viaggio di rientro',
          start: DateTime(day.year, day.month, day.day, 8),
          end: DateTime(day.year, day.month, day.day, 14),
          serviceDate: day,
          absence: 'Nessuna',
          orderPublic: 'Nessuno',
          externalService: false,
        ),
        Shift(
          description: 'Secondo servizio',
          start: DateTime(day.year, day.month, day.day, 14),
          end: DateTime(day.year, day.month, day.day, 20),
          serviceDate: day,
          absence: 'Nessuna',
          orderPublic: 'Nessuno',
          externalService: false,
        ),
      ];

      final result = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(result.overtimeHoursFromReferenceMonth, closeTo(6, 0.01));
      expect(result.overtimeInBasketHours, closeTo(1, 0.01));
      expect(result.currentBasketResidualHours, closeTo(1, 0.01));
    });

    test('negative overtime basket adjustment is shown as paid this month', () {
      final profile = CanonicalShiftScenarios.defaultProfile().copyWith(
        monthlyOvertimePayableHoursLimit: 0,
      );

      final shifts = [
        CanonicalShiftScenarios.rmLongMorningNightEdge(
          serviceDate: DateTime(2026, 5, 5),
        ),
      ];

      final withoutAdjustment = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
      );

      final withAdjustment = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
        overtimeBasketAdjustments: [
          OvertimeBasketAdjustment(
            id: 'adjustment_test',
            month: DateTime(2026, 7),
            hours: -2,
            note: 'Scarico manuale test',
            createdAt: DateTime(2026, 7, 1),
          ),
        ],
      );

      expect(withoutAdjustment.currentBasketResidualHours, greaterThan(2));
      expect(
        withAdjustment.currentBasketResidualHours,
        closeTo(withoutAdjustment.currentBasketResidualHours - 2, 0.01),
      );
      expect(withAdjustment.manualBasketPaidHoursForMonth, closeTo(2, 0.01));
    });

    test('basket payment serialization preserves hours and month', () {
      final payment = BasketPayment(
        paymentMonth: DateTime(2026, 5),
        hoursPaid: 100,
        note: 'Pagamento basket maggio',
      );

      final restored = BasketPayment.fromJson(payment.toJson());

      expect(restored.paymentMonth.year, 2026);
      expect(restored.paymentMonth.month, 5);
      expect(restored.hoursPaid, 100);
      expect(restored.note, 'Pagamento basket maggio');
    });
  });
}