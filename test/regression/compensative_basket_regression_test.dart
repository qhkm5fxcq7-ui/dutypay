import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';
import 'package:dutypay/features/shifts/application/usecases/build_compensative_basket_summary_from_movements_usecase.dart';
import 'package:dutypay/features/shifts/application/usecases/manage_compensative_basket_adjustments_usecase.dart';

void main() {
  const summaryUseCase = BuildCompensativeBasketSummaryFromMovementsUseCase();
  const manageUseCase = ManageCompensativeBasketAdjustmentsUseCase();

  group('Compensative basket regression', () {
    test('earned and recovered movements calculate residual correctly', () {
      final movements = [
        CompensativeBasketMovement(
          id: 'earned_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.earned,
          hours: 10,
          note: 'Compensativo maturato',
          createdAt: DateTime(2026, 5, 1),
        ),
        CompensativeBasketMovement(
          id: 'recovered_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.recovered,
          hours: 4,
          note: 'Recupero compensativo',
          createdAt: DateTime(2026, 5, 10),
        ),
      ];

      final summary = summaryUseCase.execute(movements: movements);

      expect(summary.earnedHours, 10);
      expect(summary.recoveredHours, 4);
      expect(summary.residualHours, 6);
    });

    test('positive adjustment increases residual', () {
      final movements = [
        CompensativeBasketMovement(
          id: 'earned_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.earned,
          hours: 10,
          note: 'Compensativo maturato',
          createdAt: DateTime(2026, 5, 1),
        ),
      ];

      final updated = manageUseCase.addAdjustment(
        movements: movements,
        hours: 3,
        isPositive: true,
        note: 'Correzione positiva',
        movementDate: DateTime(2026, 5, 15),
      );

      final summary = summaryUseCase.execute(movements: updated);

      expect(summary.earnedHours, 10);
      expect(summary.adjustmentHours, 3);
      expect(summary.residualHours, 13);
    });

    test('negative adjustment decreases residual', () {
      final movements = [
        CompensativeBasketMovement(
          id: 'earned_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.earned,
          hours: 10,
          note: 'Compensativo maturato',
          createdAt: DateTime(2026, 5, 1),
        ),
      ];

      final updated = manageUseCase.addAdjustment(
        movements: movements,
        hours: 2,
        isPositive: false,
        note: 'Correzione negativa',
        movementDate: DateTime(2026, 5, 15),
      );

      final summary = summaryUseCase.execute(movements: updated);

      expect(summary.earnedHours, 10);
      expect(summary.adjustmentHours, -2);
      expect(summary.residualHours, 8);
    });

    test('empty note blocks adjustment', () {
      final updated = manageUseCase.addAdjustment(
        movements: const [],
        hours: 5,
        isPositive: true,
        note: '',
        movementDate: DateTime(2026, 5, 15),
      );

      expect(updated, isEmpty);
    });

    test('delete removes only manual adjustment', () {
      final movements = [
        CompensativeBasketMovement(
          id: 'earned_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.earned,
          hours: 10,
          note: 'Automatico',
          createdAt: DateTime(2026, 5, 1),
        ),
        CompensativeBasketMovement(
          id: 'adjustment_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.adjustment,
          hours: 3,
          note: 'Manuale',
          createdAt: DateTime(2026, 5, 2),
        ),
      ];

      final updated = manageUseCase.deleteAdjustment(
        movements: movements,
        movementId: 'adjustment_1',
      );

      expect(updated.length, 1);
      expect(updated.first.id, 'earned_1');
    });

    test('automatic earned movement cannot be deleted', () {
      final movements = [
        CompensativeBasketMovement(
          id: 'earned_1',
          month: DateTime(2026, 5),
          type: CompensativeBasketMovementType.earned,
          hours: 10,
          note: 'Automatico',
          createdAt: DateTime(2026, 5, 1),
        ),
      ];

      final updated = manageUseCase.deleteAdjustment(
        movements: movements,
        movementId: 'earned_1',
      );

      expect(updated.length, 1);
      expect(updated.first.id, 'earned_1');
    });
  });
}