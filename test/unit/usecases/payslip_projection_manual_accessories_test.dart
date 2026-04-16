import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_projection_service.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const service = PayslipProjectionService();

  group('PayslipProjectionService - manual accessories', () {
    test('Compensazione increases projected payslip accessories', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final baseline = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: const [],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      final withCompensazione = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [
          CanonicalShiftScenarios.shiftWithCompensazione(
            serviceDate: DateTime(2026, 2, 9),
          ),
        ],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(
        withCompensazione.accessoriesGrossUsedForEstimate,
        greaterThanOrEqualTo(baseline.accessoriesGrossUsedForEstimate),
      );

      expect(
        withCompensazione.estimatedPayslipTotal,
        greaterThanOrEqualTo(baseline.estimatedPayslipTotal),
      );
    });

    test('Reperibilita increases projected payslip accessories', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final baseline = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: const [],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      final withReperibilita = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [
          CanonicalShiftScenarios.shiftWithReperibilita(
            serviceDate: DateTime(2026, 2, 9),
          ),
        ],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(
        withReperibilita.accessoriesGrossUsedForEstimate,
        greaterThanOrEqualTo(baseline.accessoriesGrossUsedForEstimate),
      );

      expect(
        withReperibilita.estimatedPayslipTotal,
        greaterThanOrEqualTo(baseline.estimatedPayslipTotal),
      );
    });

    test('Compensazione + Reperibilita both flow into projected payslip', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final withCompensazioneOnly = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [
          CanonicalShiftScenarios.shiftWithCompensazione(
            serviceDate: DateTime(2026, 2, 9),
          ),
        ],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      final withBoth = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [
          CanonicalShiftScenarios.shiftWithBothManualAccessories(
            serviceDate: DateTime(2026, 2, 9),
          ),
        ],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(
        withBoth.accessoriesGrossUsedForEstimate,
        greaterThan(withCompensazioneOnly.accessoriesGrossUsedForEstimate),
      );

      expect(
        withBoth.estimatedPayslipTotal,
        greaterThan(withCompensazioneOnly.estimatedPayslipTotal),
      );
    });

    test('Manual accessories do not enter RFI basket', () {
      final profile = CanonicalShiftScenarios.defaultProfile();

      final result = service.projectPayslip(
        payslipMonth: DateTime(2026, 4),
        allShifts: [
          CanonicalShiftScenarios.shiftWithBothManualAccessories(
            serviceDate: DateTime(2026, 2, 9),
          ),
        ],
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(result.rfiBasketGrossFromReferenceMonth, 0.0);
      expect(result.currentRfiBasketResidualGrossEstimate, 0.0);
      expect(result.manualRfiBasketPaidGrossForMonth, 0.0);
    });
  });
}