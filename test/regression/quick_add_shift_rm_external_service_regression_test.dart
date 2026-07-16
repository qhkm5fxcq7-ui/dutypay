import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';
import 'package:dutypay/features/shifts/presentation/quick_add_shift_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Reparto Mobile mostra e salva il toggle Servizio esterno',
    (tester) async {
      Shift? savedShift;

      final profile = UserPayProfile.defaultProfile().copyWith(
        externalServiceRate: 6.00,
      );

      await tester.binding.setSurfaceSize(const Size(1440, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: QuickAddShiftPage(
            onAdd: (shift) {
              savedShift = shift;
            },
            rates: profile,
            activeDepartment: Department.repartoMobile,
            initialDate: DateTime(2026, 7, 16),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final externalServiceText = find.text('Servizio esterno');

      await tester.scrollUntilVisible(
        externalServiceText,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(externalServiceText, findsOneWidget);

      final externalServiceContainer = find
          .ancestor(
            of: externalServiceText,
            matching: find.byType(Container),
          )
          .first;

      final externalServiceSwitch = find.descendant(
        of: externalServiceContainer,
        matching: find.byType(Switch),
      );

      expect(externalServiceSwitch, findsOneWidget);

      await tester.tap(externalServiceSwitch);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Indennità presenza servizi esterni'),
        findsOneWidget,
      );

      final descriptionField = find.widgetWithText(
        TextField,
        'Descrizione lavoro / servizio',
      );

      await tester.enterText(descriptionField, 'Servizio esterno test');
      await tester.pumpAndSettle();

      final saveButton = find.text('Salva turno');

      await tester.scrollUntilVisible(
        saveButton,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedShift, isNotNull);
      expect(savedShift!.externalService, isTrue);
    },
  );
}
