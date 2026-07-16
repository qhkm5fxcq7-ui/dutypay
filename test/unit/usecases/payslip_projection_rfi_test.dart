import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/domain/engine/models/rfi_basket_payment.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_projection_service.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const service = PayslipProjectionService();

  group('PayslipProjectionService - RFI basket', () {
    test('RFI matured but not paid does NOT increase estimated payslip total',
        () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final baseline = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: const [],
        payProfile: profile,
        department: Department.polfer,
      );

      final withMaturedOnly = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [
          CanonicalShiftScenarios.polferWithScaloIntero(
            serviceDate: DateTime(2026, 4, 2),
          ),
        ],
        payProfile: profile,
        department: Department.polfer,
      );

      expect(withMaturedOnly.rfiMaturedGrossForMonth, greaterThan(0));
      expect(withMaturedOnly.manualRfiBasketPaidGrossForMonth, 0);
      expect(withMaturedOnly.currentRfiBasketResidualGrossEstimate,
          greaterThan(0));

      // Regola chiave:
      // il maturato va nel basket ma NON deve entrare nel cedolino stimato
      expect(
        withMaturedOnly.estimatedPayslipTotal,
        closeTo(baseline.estimatedPayslipTotal, 0.01),
      );
    });

    test('RFI paid in month increases estimated payslip total', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final shift = CanonicalShiftScenarios.polferWithScaloIntero(
        serviceDate: DateTime(2026, 4, 2),
      );

      final maturedOnly = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [shift],
        payProfile: profile,
        department: Department.polfer,
      );

      expect(maturedOnly.rfiMaturedGrossForMonth, greaterThan(0));
      expect(maturedOnly.manualRfiBasketPaidGrossForMonth, 0);

      final withPayment = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [shift],
        payProfile: profile,
        department: Department.polfer,
        rfiBasketPayments: [
          RfiBasketPayment(
            sourceMonth: DateTime(2026, 4),
            paidInMonth: DateTime(2026, 4),
            note: 'Test payment',
          ),
        ],
      );

      expect(withPayment.manualRfiBasketPaidGrossForMonth, greaterThan(0));
      expect(
        withPayment.manualRfiBasketPaidGrossForMonth,
        closeTo(maturedOnly.rfiMaturedGrossForMonth, 0.01),
      );

      // Regola chiave:
      // quando il basket RFI viene pagato, deve aumentare il cedolino stimato
      expect(
        withPayment.estimatedPayslipTotal,
        greaterThan(maturedOnly.estimatedPayslipTotal),
      );
    });

    test('RFI paid in month reduces residual basket', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final shift = CanonicalShiftScenarios.polferWithScaloIntero(
        serviceDate: DateTime(2026, 4, 2),
      );

      final maturedOnly = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [shift],
        payProfile: profile,
        department: Department.polfer,
      );

      final withPayment = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [shift],
        payProfile: profile,
        department: Department.polfer,
        rfiBasketPayments: [
          RfiBasketPayment(
            sourceMonth: DateTime(2026, 4),
            paidInMonth: DateTime(2026, 4),
            note: 'Residual reduction test',
          ),
        ],
      );

      expect(maturedOnly.currentRfiBasketResidualGrossEstimate, greaterThan(0));
      expect(withPayment.currentRfiBasketResidualGrossEstimate, 0);
      expect(withPayment.currentRfiBasketResidualHours, 0);
    });
  });
}
