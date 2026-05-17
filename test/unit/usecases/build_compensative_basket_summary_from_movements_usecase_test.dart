import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';
import 'package:dutypay/features/shifts/application/usecases/build_compensative_basket_summary_from_movements_usecase.dart';

void main() {
  const useCase = BuildCompensativeBasketSummaryFromMovementsUseCase();

  test('summary da movimenti: earned - recovered + adjustment', () {
    final movements = [
      CompensativeBasketMovement(
        id: 'earned_1',
        month: DateTime(2026, 5),
        type: CompensativeBasketMovementType.earned,
        hours: 3.0,
        note: '',
        createdAt: DateTime(2026, 5, 4),
      ),
      CompensativeBasketMovement(
        id: 'recovered_1',
        month: DateTime(2026, 5),
        type: CompensativeBasketMovementType.recovered,
        hours: 2.0,
        note: '',
        createdAt: DateTime(2026, 5, 5),
      ),
      CompensativeBasketMovement(
        id: 'adjustment_1',
        month: DateTime(2026, 5),
        type: CompensativeBasketMovementType.adjustment,
        hours: 0.5,
        note: 'Correzione manuale',
        createdAt: DateTime(2026, 5, 6),
      ),
    ];

    final summary = useCase.execute(movements: movements);

    expect(summary.earnedHours, closeTo(3.0, 0.01));
    expect(summary.recoveredHours, closeTo(2.0, 0.01));
    expect(summary.adjustmentHours, closeTo(0.5, 0.01));
    expect(summary.residualHours, closeTo(1.5, 0.01));
  });
}