import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';
import 'package:dutypay/features/shifts/application/usecases/build_compensative_basket_summary_from_movements_usecase.dart';
import 'package:dutypay/features/shifts/application/usecases/manage_compensative_basket_adjustments_usecase.dart';

void main() {
  const manageUseCase = ManageCompensativeBasketAdjustmentsUseCase();
  const summaryUseCase = BuildCompensativeBasketSummaryFromMovementsUseCase();

  test('adjustment positivo aumenta il residuo', () {
    final movements = manageUseCase.addAdjustment(
      movements: const [],
      hours: 2.0,
      isPositive: true,
      note: 'Correzione positiva',
      movementDate: DateTime(2026, 5, 10),
    );

    final summary = summaryUseCase.execute(movements: movements);

    expect(summary.adjustmentHours, closeTo(2.0, 0.01));
    expect(summary.residualHours, closeTo(2.0, 0.01));
  });

  test('adjustment negativo diminuisce il residuo', () {
    final movements = manageUseCase.addAdjustment(
      movements: const [],
      hours: 1.5,
      isPositive: false,
      note: 'Correzione negativa',
      movementDate: DateTime(2026, 5, 10),
    );

    final summary = summaryUseCase.execute(movements: movements);

    expect(summary.adjustmentHours, closeTo(-1.5, 0.01));
    expect(summary.residualHours, closeTo(-1.5, 0.01));
  });

  test('nota obbligatoria: non salva adjustment senza nota', () {
    final movements = manageUseCase.addAdjustment(
      movements: const [],
      hours: 2.0,
      isPositive: true,
      note: '   ',
      movementDate: DateTime(2026, 5, 10),
    );

    expect(movements, isEmpty);
  });

  test('delete adjustment: rimuove solo movimento manuale', () {
    final movements = [
      CompensativeBasketMovement(
        id: 'earned_1',
        month: DateTime(2026, 5),
        type: CompensativeBasketMovementType.earned,
        hours: 3.0,
        note: 'Automatic earned',
        createdAt: DateTime(2026, 5, 4),
      ),
      CompensativeBasketMovement(
        id: 'adjustment_1',
        month: DateTime(2026, 5),
        type: CompensativeBasketMovementType.adjustment,
        hours: 1.0,
        note: 'Manual adjustment',
        createdAt: DateTime(2026, 5, 5),
      ),
    ];

    final updated = manageUseCase.deleteAdjustment(
      movements: movements,
      movementId: 'adjustment_1',
    );

    expect(updated.length, 1);
    expect(updated.first.id, 'earned_1');
  });

  test('automatic movements non cancellabili: earned resta intatto', () {
    final movements = [
      CompensativeBasketMovement(
        id: 'earned_1',
        month: DateTime(2026, 5),
        type: CompensativeBasketMovementType.earned,
        hours: 3.0,
        note: 'Automatic earned',
        createdAt: DateTime(2026, 5, 4),
      ),
    ];

    final updated = manageUseCase.deleteAdjustment(
      movements: movements,
      movementId: 'earned_1',
    );

    expect(updated.length, 1);
    expect(updated.first.id, 'earned_1');
  });
}