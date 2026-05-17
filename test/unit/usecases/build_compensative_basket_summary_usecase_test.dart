import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/usecases/build_compensative_basket_summary_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';

void main() {
  const useCase = BuildCompensativeBasketSummaryUseCase();

  test('basket compensativo: turno con 3h compensative genera maturato 3h', () {
    final shift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 16),
      overtimeDestination: OvertimeDestination.compensative,
      compensativeOvertimeHours: 3.0,
    );

    final summary = useCase.execute(shifts: [shift]);

    expect(summary.earnedHours, closeTo(3.0, 0.01));
    expect(summary.recoveredHours, closeTo(0.0, 0.01));
    expect(summary.residualHours, closeTo(3.0, 0.01));
  });

  test('basket compensativo: recupero compensativo scala ore dal residuo', () {
    final earnedShift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 16),
      overtimeDestination: OvertimeDestination.compensative,
      compensativeOvertimeHours: 3.0,
    );

    final recoveryShift = Shift(
      start: DateTime(2026, 5, 5, 7),
      end: DateTime(2026, 5, 5, 9),
      absence: 'Recupero compensativo',
      workedHours: 2.0,
    );

    final summary = useCase.execute(
      shifts: [earnedShift, recoveryShift],
    );

    expect(summary.earnedHours, closeTo(3.0, 0.01));
    expect(summary.recoveredHours, closeTo(2.0, 0.01));
    expect(summary.residualHours, closeTo(1.0, 0.01));
  });
}