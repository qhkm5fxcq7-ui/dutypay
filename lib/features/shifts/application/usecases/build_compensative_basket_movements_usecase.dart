import '../models/compensative_basket_movement.dart';
import '../../presentation/models/shift.dart';

class BuildCompensativeBasketMovementsUseCase {
  const BuildCompensativeBasketMovementsUseCase();

  List<CompensativeBasketMovement> execute({
    required List<Shift> shifts,
  }) {
    final movements = <CompensativeBasketMovement>[];

    for (final shift in shifts) {
      final month = DateTime(
        shift.serviceDate.year,
        shift.serviceDate.month,
      );

      final isCompensative =
          shift.overtimeDestination == OvertimeDestination.compensative;

      if (isCompensative) {
        final hours = shift.compensativeOvertimeHours > 0
            ? shift.compensativeOvertimeHours
            : shift.workedHours;

        if (hours > 0) {
          movements.add(
            CompensativeBasketMovement(
              id: 'earned_${shift.serviceDate.toIso8601String()}_${movements.length}',
              month: month,
              type: CompensativeBasketMovementType.earned,
              hours: hours,
              note: shift.compensativeOvertimeNote.isNotEmpty
                  ? shift.compensativeOvertimeNote
                  : 'Ore compensative maturate',
              createdAt: shift.serviceDate,
            ),
          );
        }
      }

      final isRecovery = shift.absence == 'Recupero compensativo';

      if (isRecovery) {
        final recoveredHours = shift.compensativeRecoveryHours > 0
            ? shift.compensativeRecoveryHours
            : shift.workedHours;

        if (recoveredHours > 0) {
          movements.add(
            CompensativeBasketMovement(
              id: 'recovered_${shift.serviceDate.toIso8601String()}_${movements.length}',
              month: month,
              type: CompensativeBasketMovementType.recovered,
              hours: recoveredHours,
              note: shift.note.isNotEmpty
                  ? shift.note
                  : 'Recupero compensativo',
              createdAt: shift.serviceDate,
            ),
          );
        }
      }
    }

    return movements;
  }
}