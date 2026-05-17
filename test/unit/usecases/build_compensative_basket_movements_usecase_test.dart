import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';
import 'package:dutypay/features/shifts/application/usecases/build_compensative_basket_movements_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';

void main() {
  const useCase = BuildCompensativeBasketMovementsUseCase();

  test('crea movimento earned da turno compensativo', () {
    final shift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 16),
      serviceDate: DateTime(2026, 5, 4),
      overtimeDestination: OvertimeDestination.compensative,
      compensativeOvertimeHours: 3.0,
      compensativeOvertimeNote: 'Programmato compensativo',
    );

    final movements = useCase.execute(shifts: [shift]);

    expect(movements.length, 1);
    expect(movements.first.type, CompensativeBasketMovementType.earned);
    expect(movements.first.hours, closeTo(3.0, 0.01));
    expect(movements.first.note, 'Programmato compensativo');
  });

  test('crea movimento recovered da assenza recupero compensativo', () {
    final shift = Shift(
      start: DateTime(2026, 5, 5, 7),
      end: DateTime(2026, 5, 5, 9),
      serviceDate: DateTime(2026, 5, 5),
      absence: 'Recupero compensativo',
      workedHours: 2.0,
      note: 'Scarico ore',
    );

    final movements = useCase.execute(shifts: [shift]);

    expect(movements.length, 1);
    expect(movements.first.type, CompensativeBasketMovementType.recovered);
    expect(movements.first.hours, closeTo(2.0, 0.01));
    expect(movements.first.note, 'Scarico ore');
  });

  test('crea storico earned + recovered nello stesso mese', () {
    final earnedShift = Shift(
      start: DateTime(2026, 5, 4, 7),
      end: DateTime(2026, 5, 4, 16),
      serviceDate: DateTime(2026, 5, 4),
      overtimeDestination: OvertimeDestination.compensative,
      compensativeOvertimeHours: 3.0,
    );

    final recoveryShift = Shift(
      start: DateTime(2026, 5, 5, 7),
      end: DateTime(2026, 5, 5, 9),
      serviceDate: DateTime(2026, 5, 5),
      absence: 'Recupero compensativo',
      workedHours: 2.0,
    );

    final movements = useCase.execute(
      shifts: [earnedShift, recoveryShift],
    );

    expect(movements.length, 2);
    expect(movements[0].type, CompensativeBasketMovementType.earned);
    expect(movements[1].type, CompensativeBasketMovementType.recovered);
  });
}