import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/models/compensative_basket_summary.dart';

void main() {
  test('basket compensativo: maturato 3h, recuperato 2h, residuo 1h', () {
    const summary = CompensativeBasketSummary(
      earnedHours: 3.0,
      recoveredHours: 2.0,
    );

    expect(summary.earnedHours, closeTo(3.0, 0.01));
    expect(summary.recoveredHours, closeTo(2.0, 0.01));
    expect(summary.residualHours, closeTo(1.0, 0.01));
  });

  test('basket compensativo: adjustment positivo aumenta il residuo', () {
    const summary = CompensativeBasketSummary(
      earnedHours: 3.0,
      recoveredHours: 2.0,
      adjustmentHours: 1.5,
    );

    expect(summary.residualHours, closeTo(2.5, 0.01));
  });

  test('basket compensativo: adjustment negativo riduce il residuo', () {
    const summary = CompensativeBasketSummary(
      earnedHours: 3.0,
      recoveredHours: 1.0,
      adjustmentHours: -0.5,
    );

    expect(summary.residualHours, closeTo(1.5, 0.01));
  });
}