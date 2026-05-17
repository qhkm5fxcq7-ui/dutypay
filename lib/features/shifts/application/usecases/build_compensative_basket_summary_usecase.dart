import '../models/compensative_basket_summary.dart';
import '../../presentation/models/shift.dart';

class BuildCompensativeBasketSummaryUseCase {
  const BuildCompensativeBasketSummaryUseCase();

  CompensativeBasketSummary execute({
    required List<Shift> shifts,
  }) {
    double earnedHours = 0.0;
    double recoveredHours = 0.0;

    for (final shift in shifts) {
      final isCompensative =
          shift.overtimeDestination ==
          OvertimeDestination.compensative;

      if (isCompensative) {
        final compensativeHours =
            shift.compensativeOvertimeHours > 0
                ? shift.compensativeOvertimeHours
                : shift.workedHours;

        earnedHours += compensativeHours;
      }

      final isRecovery =
          shift.absence == 'Recupero compensativo';

      if (isRecovery) {
        recoveredHours += shift.workedHours;
      }
    }

    return CompensativeBasketSummary(
      earnedHours: earnedHours,
      recoveredHours: recoveredHours,
    );
  }
}