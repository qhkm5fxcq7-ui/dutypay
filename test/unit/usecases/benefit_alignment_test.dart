import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'package:dutypay/features/shifts/application/usecases/build_shift_computation_usecase.dart';
import 'package:dutypay/features/shifts/application/usecases/build_shift_money_components_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';

import '../../scenarios/canonical_shift_scenarios.dart';

void main() {
  const previewUseCase = BuildShiftComputationUseCase();
  const dailyUseCase = BuildDailyShiftResultUseCase();
  const moneyUseCase = BuildShiftMoneyComponentsUseCase();

  final profile = CanonicalShiftScenarios.defaultProfile();

  Shift buildScenarioShift() {
    return Shift(
      description: 'RM benefit alignment',
      start: DateTime(2026, 4, 10, 17, 0),
      end: DateTime(2026, 4, 11, 1, 0),
      serviceDate: DateTime(2026, 4, 10),
      absence: 'Nessuna',
      orderPublic: 'In sede',
      externalService: false,
      genereDiConforto: true,
      ticketPasto: true,
    );
  }

  int countCategory(List<Map<String, dynamic>> breakdown, String category) {
    return breakdown.where((item) => item['category'] == category).length;
  }

  Map<String, dynamic> singleByCategory(
    List<Map<String, dynamic>> breakdown,
    String category,
  ) {
    final matches = breakdown.where((item) => item['category'] == category).toList();
    expect(matches.length, 1, reason: 'Expected exactly one $category entry');
    return matches.first;
  }

  bool hasCategory(List<Map<String, dynamic>> breakdown, String category) {
    return breakdown.any((item) => item['category'] == category);
  }

  double sumAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double sumBenefitAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['benefitAmount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double sumNonBenefitAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown
        .where((item) => item['isBenefit'] != true)
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );
  }

  bool isOvertimeCategory(String? category) {
    return category == 'overtime_day' ||
        category == 'overtime_night' ||
        category == 'overtime_holiday_day' ||
        category == 'overtime_night_holiday';
  }

  double sumNonOvertimeNonBasketAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown
        .where((item) {
          final category = item['category'] as String?;
          final isBasket = item['isBasketItem'] == true;
          return !isOvertimeCategory(category) && !isBasket;
        })
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );
  }

  group('Benefit alignment', () {
    test('RM preview and saved detail keep benefits visible but non-economic', () {
      final shift = buildScenarioShift();

      final preview = previewUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      final daily = dailyUseCase.execute(
        shifts: [shift],
        profile: profile,
        department: Department.repartoMobile,
      );

      final saved = daily.computations[shift];
      expect(saved, isNotNull);

      final savedBreakdown = saved!.breakdown;

      // A. Preview breakdown: presence + no duplications
      expect(hasCategory(preview.breakdown, 'ticket_meal'), isTrue);
      expect(hasCategory(preview.breakdown, 'comfort'), isTrue);
      expect(countCategory(preview.breakdown, 'ticket_meal'), 1);
      expect(countCategory(preview.breakdown, 'comfort'), 1);
      expect(countCategory(preview.breakdown, 'comfort_cdg'), 0);

      // B. Saved breakdown: same elements + no duplications
      expect(hasCategory(savedBreakdown, 'ticket_meal'), isTrue);
      expect(hasCategory(savedBreakdown, 'comfort'), isTrue);
      expect(countCategory(savedBreakdown, 'ticket_meal'), 1);
      expect(countCategory(savedBreakdown, 'comfort'), 1);
      expect(countCategory(savedBreakdown, 'comfort_cdg'), 0);

      // C. Benefit structure
      final previewTicket = singleByCategory(preview.breakdown, 'ticket_meal');
      final previewComfort = singleByCategory(preview.breakdown, 'comfort');

      final savedTicket = singleByCategory(savedBreakdown, 'ticket_meal');
      final savedComfort = singleByCategory(savedBreakdown, 'comfort');

      expect((previewTicket['amount'] as num?)?.toDouble() ?? -1, 0.0);
      expect((previewComfort['amount'] as num?)?.toDouble() ?? -1, 0.0);
      expect((savedTicket['amount'] as num?)?.toDouble() ?? -1, 0.0);
      expect((savedComfort['amount'] as num?)?.toDouble() ?? -1, 0.0);

      expect(
        ((previewTicket['benefitAmount'] as num?)?.toDouble() ?? 0.0) > 0,
        isTrue,
      );
      expect(
        ((previewComfort['benefitAmount'] as num?)?.toDouble() ?? 0.0) > 0,
        isTrue,
      );
      expect(
        ((savedTicket['benefitAmount'] as num?)?.toDouble() ?? 0.0) > 0,
        isTrue,
      );
      expect(
        ((savedComfort['benefitAmount'] as num?)?.toDouble() ?? 0.0) > 0,
        isTrue,
      );

      expect(previewTicket['isBenefit'], isTrue);
      expect(previewComfort['isBenefit'], isTrue);
      expect(savedTicket['isBenefit'], isTrue);
      expect(savedComfort['isBenefit'], isTrue);

      // D. Totals: benefits excluded
      final previewBenefitTotal = sumBenefitAmounts(preview.breakdown);
      final savedBenefitTotal = sumBenefitAmounts(savedBreakdown);

      expect(previewBenefitTotal, greaterThan(0.0));
      expect(savedBenefitTotal, greaterThan(0.0));

      expect(
        preview.totalAmount,
        closeTo(sumAmounts(preview.breakdown), 0.01),
      );
      expect(
        saved.totalAmount,
        closeTo(sumAmounts(savedBreakdown), 0.01),
      );

      expect(
        preview.totalAmount,
        closeTo(sumNonBenefitAmounts(preview.breakdown), 0.01),
      );
      expect(
        saved.totalAmount,
        closeTo(sumNonBenefitAmounts(savedBreakdown), 0.01),
      );

      final previewOrderPublicAmount =
          ((singleByCategory(preview.breakdown, 'order_public')['amount'] as num?)
                  ?.toDouble() ??
              0.0);

      final savedOrderPublicAmount =
          ((singleByCategory(savedBreakdown, 'order_public')['amount'] as num?)
                  ?.toDouble() ??
              0.0);

      expect(
        preview.extraAmount,
        closeTo(preview.totalAmount - previewOrderPublicAmount, 0.01),
      );
      expect(
        saved.extraAmount,
        closeTo(saved.totalAmount - savedOrderPublicAmount, 0.01),
      );

      // E. Preview and saved aligned
      expect(saved.totalAmount, closeTo(preview.totalAmount, 0.01));
      expect(saved.extraAmount, closeTo(preview.extraAmount, 0.01));
      expect(saved.overtimeHours, closeTo(preview.overtimeHours, 0.01));

      expect(
        countCategory(savedBreakdown, 'overtime_night'),
        countCategory(preview.breakdown, 'overtime_night'),
      );
      expect(
        countCategory(savedBreakdown, 'ordinary_night'),
        countCategory(preview.breakdown, 'ordinary_night'),
      );

      // ShiftMoneyComponents must also exclude benefits economically
      final money = moneyUseCase.execute(
        shift: shift,
        profile: profile,
        department: Department.repartoMobile,
      );

      expect(
        money.overtimeGross + money.nonOvertimeGross + money.rfiBasketGross,
        closeTo(preview.totalAmount, 0.01),
      );

      expect(
        money.nonOvertimeGross,
        closeTo(sumNonOvertimeNonBasketAmounts(preview.breakdown), 0.01),
      );
    });
  });
}