import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';
import 'package:dutypay/features/shifts/application/usecases/build_compensative_basket_summary_from_movements_usecase.dart';

void main() {
  group('Compensative basket integration flow', () {
    test('earned, recovered, adjustments and restore keep same summary', () {
      const summaryUseCase = BuildCompensativeBasketSummaryFromMovementsUseCase();

      final movements = [
        CompensativeBasketMovement(
          id: 'earned_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.earned,
          hours: 12,
          note: 'Ore compensative maturate',
          createdAt: DateTime(2026, 5, 1),
        ),
        CompensativeBasketMovement(
          id: 'recovered_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.recovered,
          hours: 5,
          note: 'Recupero compensativo',
          createdAt: DateTime(2026, 5, 10),
        ),
        CompensativeBasketMovement(
          id: 'adjustment_positive',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.adjustment,
          hours: 3,
          note: 'Correzione positiva',
          createdAt: DateTime(2026, 5, 15),
        ),
        CompensativeBasketMovement(
          id: 'adjustment_negative',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.adjustment,
          hours: -2,
          note: 'Correzione negativa',
          createdAt: DateTime(2026, 5, 20),
        ),
      ];

      final summary = summaryUseCase.execute(movements: movements);

      expect(summary.earnedHours, 12);
      expect(summary.recoveredHours, 5);
      expect(summary.adjustmentHours, 1);
      expect(summary.residualHours, 8);

      final payload = <String, dynamic>{
        'compensativeBasketMovements':
            movements.map((item) => item.toJson()).toList(),
      };

      final restored =
          jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;

      final restoredMovements =
          (restored['compensativeBasketMovements'] as List)
              .cast<Map<String, dynamic>>()
              .map(CompensativeBasketMovement.fromJson)
              .toList();

      final restoredSummary = summaryUseCase.execute(
        movements: restoredMovements,
      );

      expect(restoredSummary.earnedHours, summary.earnedHours);
      expect(restoredSummary.recoveredHours, summary.recoveredHours);
      expect(restoredSummary.adjustmentHours, summary.adjustmentHours);
      expect(restoredSummary.residualHours, summary.residualHours);
    });
  });
}
