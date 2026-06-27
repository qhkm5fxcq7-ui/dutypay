import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/domain/engine/models/basket_payment.dart';
import 'package:dutypay/features/shifts/domain/engine/models/overtime_basket_adjustment.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_projection_service.dart';

void main() {
  test('private Max basket backup keeps 100h payment coherent', () {
    final file = File('test/fixtures/private/max_basket_backup.json');

    if (!file.existsSync()) {
      markTestSkipped('Private Max backup fixture not available.');
      return;
    }

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    final shifts = (json['shifts'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Shift.fromJson)
        .toList();

    final profile = json['profile'] is Map<String, dynamic>
        ? UserPayProfile.fromJson(json['profile'] as Map<String, dynamic>)
        : UserPayProfile.defaultProfile();

    final basketPayments = (json['basketPayments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BasketPayment.fromJson)
        .toList();

    final overtimeBasketAdjustments =
        (json['overtimeBasketAdjustments'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OvertimeBasketAdjustment.fromJson)
            .toList();

    final result = const PayslipProjectionService().projectPayslip(
      payslipMonth: DateTime(2026, 6),
      allShifts: shifts,
      payProfile: profile,
      department: Department.repartoMobile,
      basketPayments: basketPayments,
      overtimeBasketAdjustments: overtimeBasketAdjustments,
    );

    expect(
      basketPayments.any(
        (payment) =>
            payment.paymentMonth.year == 2026 &&
            payment.paymentMonth.month == 5 &&
            payment.hoursPaid == 100,
      ),
      isTrue,
    );

    final adjustmentBalance = overtimeBasketAdjustments.fold<double>(
      0,
      (sum, item) => sum + item.hours,
    );

    expect(adjustmentBalance, closeTo(0, 0.01));
    expect(result.currentBasketResidualHours, greaterThanOrEqualTo(0));
    expect(result.manualBasketPaidHoursForMonth, greaterThanOrEqualTo(0));
  });
}
