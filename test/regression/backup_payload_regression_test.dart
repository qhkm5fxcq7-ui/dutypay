import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';
import 'package:dutypay/features/shifts/domain/engine/models/basket_payment.dart';
import 'package:dutypay/features/shifts/domain/engine/models/overtime_basket_adjustment.dart';
import 'package:dutypay/features/shifts/domain/engine/models/rfi_basket_payment.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

import '../scenarios/canonical_shift_scenarios.dart';

void main() {
  group('Backup payload regression', () {
    test('backup json preserves all basket related collections', () {
      final shift = CanonicalShiftScenarios.rmLongMorningNightEdge(
        serviceDate: DateTime(2026, 5, 5),
      );

      final profile = UserPayProfile.defaultProfile().copyWith(
        monthlyOvertimePayableHoursLimit: 55,
      );

      final basketPayment = BasketPayment(
        paymentMonth: DateTime(2026, 5),
        hoursPaid: 100,
        note: 'Pagamento basket maggio',
      );

      final rfiPayment = RfiBasketPayment(
        sourceMonth: DateTime(2026, 4),
        paidInMonth: DateTime(2026, 6),
        note: 'Pagamento RFI test',
      );

      final overtimeAdjustment = OvertimeBasketAdjustment(
        id: 'overtime_adjustment_test',
        month: DateTime(2026, 6),
        hours: -10,
        note: 'Scarico manuale basket',
        createdAt: DateTime(2026, 6, 15),
      );

      final compensativeMovement = CompensativeBasketMovement(
        id: 'compensative_adjustment_test',
        month: DateTime(2026, 6),
        hours: 3,
        note: 'Correzione compensativo',
        createdAt: DateTime(2026, 6, 16),
        type: CompensativeBasketMovementType.adjustment,
      );

      final payload = <String, dynamic>{
        'version': 3,
        'departmentId': 'reparto_mobile',
        'shifts': [shift.toJson()],
        'profile': profile.toJson(),
        'basketPayments': [basketPayment.toJson()],
        'rfiBasketPayments': [rfiPayment.toJson()],
        'overtimeBasketAdjustments': [overtimeAdjustment.toJson()],
        'compensativeBasketMovements': [compensativeMovement.toJson()],
      };

      final restored =
          jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

      final restoredShift = Shift.fromJson(
        (restored['shifts'] as List).first as Map<String, dynamic>,
      );
      final restoredProfile = UserPayProfile.fromJson(
        restored['profile'] as Map<String, dynamic>,
      );
      final restoredBasketPayment = BasketPayment.fromJson(
        (restored['basketPayments'] as List).first as Map<String, dynamic>,
      );
      final restoredRfiPayment = RfiBasketPayment.fromJson(
        (restored['rfiBasketPayments'] as List).first
            as Map<String, dynamic>,
      );
      final restoredOvertimeAdjustment =
          OvertimeBasketAdjustment.fromJson(
        (restored['overtimeBasketAdjustments'] as List).first
            as Map<String, dynamic>,
      );
      final restoredCompensativeMovement =
          CompensativeBasketMovement.fromJson(
        (restored['compensativeBasketMovements'] as List).first
            as Map<String, dynamic>,
      );

      expect(restoredShift.description, shift.description);
      expect(restoredProfile.monthlyOvertimePayableHoursLimit, 55);

      expect(restoredBasketPayment.paymentMonth.year, 2026);
      expect(restoredBasketPayment.paymentMonth.month, 5);
      expect(restoredBasketPayment.hoursPaid, 100);
      expect(restoredBasketPayment.note, 'Pagamento basket maggio');

      expect(restoredRfiPayment.sourceMonth.month, 4);
      expect(restoredRfiPayment.paidInMonth.month, 6);
      expect(restoredRfiPayment.note, 'Pagamento RFI test');

      expect(restoredOvertimeAdjustment.id, 'overtime_adjustment_test');
      expect(restoredOvertimeAdjustment.month.month, 6);
      expect(restoredOvertimeAdjustment.hours, -10);
      expect(restoredOvertimeAdjustment.note, 'Scarico manuale basket');

      expect(restoredCompensativeMovement.id, 'compensative_adjustment_test');
      expect(restoredCompensativeMovement.month.month, 6);
      expect(restoredCompensativeMovement.hours, 3);
      expect(restoredCompensativeMovement.note, 'Correzione compensativo');
      expect(
        restoredCompensativeMovement.type,
        CompensativeBasketMovementType.adjustment,
      );
    });
  });
}
