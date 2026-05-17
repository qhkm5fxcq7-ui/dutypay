import '../models/compensative_basket_movement.dart';

class ManageCompensativeBasketAdjustmentsUseCase {
  const ManageCompensativeBasketAdjustmentsUseCase();

  List<CompensativeBasketMovement> addAdjustment({
    required List<CompensativeBasketMovement> movements,
    required double hours,
    required bool isPositive,
    required String note,
    required DateTime movementDate,
  }) {
    final trimmedNote = note.trim();

    if (hours <= 0 || trimmedNote.isEmpty) {
      return movements;
    }

    final signedHours = isPositive ? hours : -hours;

    final adjustment = CompensativeBasketMovement(
      id: 'adjustment_${movementDate.toIso8601String()}_${movements.length}',
      month: DateTime(movementDate.year, movementDate.month),
      type: CompensativeBasketMovementType.adjustment,
      hours: signedHours,
      note: trimmedNote,
      createdAt: movementDate,
    );

    return [
      ...movements,
      adjustment,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<CompensativeBasketMovement> deleteAdjustment({
    required List<CompensativeBasketMovement> movements,
    required String movementId,
  }) {
    return movements.where((movement) {
      if (movement.id != movementId) return true;
      return movement.type != CompensativeBasketMovementType.adjustment;
    }).toList();
  }
}