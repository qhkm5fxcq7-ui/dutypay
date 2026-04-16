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

  Shift _buildScenarioShift() {
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

  int _countCategory(List<Map<String, dynamic>> breakdown, String category) {
    return breakdown.where((item) => item['category'] == category).length;
  }

  Map<String, dynamic> _singleByCategory(
    List<Map<String, dynamic>> breakdown,
    String category,
  ) {
    final matches = breakdown.where((item) => item['category'] == category).toList();
    expect(matches.length, 1, reason: 'Expected exactly one $category entry');
    return matches.first;
  }

  bool _hasCategory(List<Map<String, dynamic>> breakdown, String category) {
    return breakdown.any((item) => item['category'] == category);
  }

  double _sumAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double _sumBenefitAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['benefitAmount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double _sumNonBenefitAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown
        .where((item) => item['isBenefit'] != true)
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );
  }

  bool _isOvertimeCategory(String? category) {
    return category == 'overtime_day' ||
        category == 'overtime_night' ||
        category == 'overtime_holiday_day' ||
        category == 'overtime_night_holiday';
  }

  double _sumNonOvertimeNonBasketAmounts(List<Map<String, dynamic>> breakdown) {
    return breakdown
        .where((item) {
          final category = item['category'] as String?;
          final isBasket = item['isBasketItem'] == true;
          return !_isOvertimeCategory(category) && !isBasket;
        })
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );
  }

  group('Benefit alignment', () {
    test('RM preview and saved detail keep benefits visible but non-economic', () {
      final shift = _buildScenarioShift();

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
      expect(_hasCategory(preview.breakdown, 'ticket_meal'), isTrue);
      expect(_hasCategory(preview.breakdown, 'comfort'), isTrue);
      expect(_countCategory(preview.breakdown, 'ticket_meal'), 1);
      expect(_countCategory(preview.breakdown, 'comfort'), 1);
      expect(_countCategory(preview.breakdown, 'comfort_cdg'), 0);

      // B. Saved breakdown: same elements + no duplications
      expect(_hasCategory(savedBreakdown, 'ticket_meal'), isTrue);
      expect(_hasCategory(savedBreakdown, 'comfort'), isTrue);
      expect(_countCategory(savedBreakdown, 'ticket_meal'), 1);
      expect(_countCategory(savedBreakdown, 'comfort'), 1);
      expect(_countCategory(savedBreakdown, 'comfort_cdg'), 0);

      // C. Benefit structure
      final previewTicket = _singleByCategory(preview.breakdown, 'ticket_meal');
      final previewComfort = _singleByCategory(preview.breakdown, 'comfort');

      final savedTicket = _singleByCategory(savedBreakdown, 'ticket_meal');
      final savedComfort = _singleByCategory(savedBreakdown, 'comfort');

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
      final previewBenefitTotal = _sumBenefitAmounts(preview.breakdown);
      final savedBenefitTotal = _sumBenefitAmounts(savedBreakdown);

      expect(previewBenefitTotal, greaterThan(0.0));
      expect(savedBenefitTotal, greaterThan(0.0));

      expect(
        preview.totalAmount,
        closeTo(_sumAmounts(preview.breakdown), 0.01),
      );
      expect(
        saved.totalAmount,
        closeTo(_sumAmounts(savedBreakdown), 0.01),
      );

      expect(
        preview.totalAmount,
        closeTo(_sumNonBenefitAmounts(preview.breakdown), 0.01),
      );
      expect(
        saved.totalAmount,
        closeTo(_sumNonBenefitAmounts(savedBreakdown), 0.01),
      );

      final previewOrderPublicAmount =
          ((_singleByCategory(preview.breakdown, 'order_public')['amount'] as num?)
                  ?.toDouble() ??
              0.0);

      final savedOrderPublicAmount =
          ((_singleByCategory(savedBreakdown, 'order_public')['amount'] as num?)
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
        _countCategory(savedBreakdown, 'overtime_night'),
        _countCategory(preview.breakdown, 'overtime_night'),
      );
      expect(
        _countCategory(savedBreakdown, 'ordinary_night'),
        _countCategory(preview.breakdown, 'ordinary_night'),
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
        closeTo(_sumNonOvertimeNonBasketAmounts(preview.breakdown), 0.01),
      );
    });
  });
}