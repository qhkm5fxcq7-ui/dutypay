import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/domain/engine/models/basket_payment.dart';
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