import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/models/compensative_basket_movement.dart';

void main() {
  test('compensative basket movement serializes correctly', () {
    final movement = CompensativeBasketMovement(
      id: 'movement_1',
      month: DateTime(2026, 5, 1),
      type: CompensativeBasketMovementType.earned,
      hours: 3.0,
      note: 'Straordinario compensativo',
      createdAt: DateTime(2026, 5, 2, 10, 30),
    );

    final json = movement.toJson();

    expect(json['id'], 'movement_1');
    expect(json['type'], 'earned');
    expect(json['hours'], closeTo(3.0, 0.01));
    expect(json['note'], 'Straordinario compensativo');
  });

  test('compensative basket movement deserializes correctly', () {
    final json = {
      'id': 'movement_2',
      'month': DateTime(2026, 5, 1).toIso8601String(),
      'type': 'recovered',
      'hours': 2.0,
      'note': 'Recupero compensativo',
      'createdAt': DateTime(2026, 5, 3, 9, 0).toIso8601String(),
    };

    final movement = CompensativeBasketMovement.fromJson(json);

    expect(movement.id, 'movement_2');
    expect(
      movement.type,
      CompensativeBasketMovementType.recovered,
    );
    expect(movement.hours, closeTo(2.0, 0.01));
    expect(movement.note, 'Recupero compensativo');
  });

  test('unknown movement type falls back safely', () {
    final json = {
      'id': 'movement_3',
      'month': DateTime(2026, 5, 1).toIso8601String(),
      'type': 'invalid_type',
      'hours': 1.0,
      'note': '',
      'createdAt': DateTime(2026, 5, 3).toIso8601String(),
    };

    final movement = CompensativeBasketMovement.fromJson(json);

    expect(
      movement.type,
      CompensativeBasketMovementType.adjustment,
    );
  });
}
