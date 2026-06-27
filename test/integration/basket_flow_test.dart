import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/domain/engine/models/basket_payment.dart';
import 'package:dutypay/features/shifts/domain/engine/models/overtime_basket_adjustment.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_projection_service.dart';

import '../scenarios/canonical_shift_scenarios.dart';

void main() {
  group('Basket integration flow', () {
    test('matured basket can be paid, adjusted, exported and restored', () {
      const service = PayslipProjectionService();

      final profile = UserPayProfile.defaultProfile().copyWith(
        monthlyOvertimePayableHoursLimit: 5,
      );

      final shifts = [
        CanonicalShiftScenarios.rmLongMorningNightEdge(
          serviceDate: DateTime(2026, 5, 5),
        ),
        CanonicalShiftScenarios.rmLongMorningNightEdge(
          serviceDate: DateTime(2026, 5, 6),
        ),
      ];

      final initial = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(initial.currentBasketResidualHours, greaterThan(0));

      final payment = BasketPayment(
        paymentMonth: DateTime(2026, 7),
        hoursPaid: 3,
        note: 'Pagamento integration test',
      );

      final afterPayment = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
        basketPayments: [payment],
      );

      expect(
        afterPayment.currentBasketResidualHours,
        closeTo(initial.currentBasketResidualHours - 3, 0.01),
      );
      expect(afterPayment.manualBasketPaidHoursForMonth, closeTo(3, 0.01));

      final adjustment = OvertimeBasketAdjustment(
        id: 'integration_adjustment',
        month: DateTime(2026, 7),
        hours: -2,
        note: 'Scarico integration test',
        createdAt: DateTime(2026, 7, 10),
      );

      final afterAdjustment = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
        basketPayments: [payment],
        overtimeBasketAdjustments: [adjustment],
      );

      expect(
        afterAdjustment.currentBasketResidualHours,
        closeTo(afterPayment.currentBasketResidualHours - 2, 0.01),
      );
      expect(afterAdjustment.manualBasketPaidHoursForMonth, closeTo(5, 0.01));

      final payload = <String, dynamic>{
        'version': 3,
        'departmentId': 'reparto_mobile',
        'shifts': shifts.map((item) => item.toJson()).toList(),
        'profile': profile.toJson(),
        'basketPayments': [payment.toJson()],
        'overtimeBasketAdjustments': [adjustment.toJson()],
      };

      final restored =
          jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

      final restoredPayments = (restored['basketPayments'] as List)
          .cast<Map<String, dynamic>>()
          .map(BasketPayment.fromJson)
          .toList();

      final restoredAdjustments =
          (restored['overtimeBasketAdjustments'] as List)
              .cast<Map<String, dynamic>>()
              .map(OvertimeBasketAdjustment.fromJson)
              .toList();

      final restoredProjection = service.projectPayslip(
        payslipMonth: DateTime(2026, 7),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
        basketPayments: restoredPayments,
        overtimeBasketAdjustments: restoredAdjustments,
      );

      expect(
        restoredProjection.currentBasketResidualHours,
        closeTo(afterAdjustment.currentBasketResidualHours, 0.01),
      );
      expect(
        restoredProjection.manualBasketPaidHoursForMonth,
        closeTo(afterAdjustment.manualBasketPaidHoursForMonth, 0.01),
      );
    });
  });
}
