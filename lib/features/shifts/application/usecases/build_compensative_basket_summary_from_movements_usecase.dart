import '../models/compensative_basket_movement.dart';
import '../models/compensative_basket_summary.dart';

class BuildCompensativeBasketSummaryFromMovementsUseCase {
  const BuildCompensativeBasketSummaryFromMovementsUseCase();

  CompensativeBasketSummary execute({
    required List<CompensativeBasketMovement> movements,
  }) {
    double earnedHours = 0.0;
    double recoveredHours = 0.0;
    double adjustmentHours = 0.0;

    for (final movement in movements) {
      switch (movement.type) {
        case CompensativeBasketMovementType.earned:
          earnedHours += movement.hours;
          break;

        case CompensativeBasketMovementType.recovered:
          recoveredHours += movement.hours;
          break;

        case CompensativeBasketMovementType.adjustment:
          adjustmentHours += movement.hours;
          break;
      }
    }

    return CompensativeBasketSummary(
      earnedHours: earnedHours,
      recoveredHours: recoveredHours,
      adjustmentHours: adjustmentHours,
    );
  }
}