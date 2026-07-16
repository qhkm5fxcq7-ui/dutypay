import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';
import 'package:dutypay/features/shifts/presentation/quick_add_shift_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'preview modifica usa tutti i turni della stessa serviceDate',
    (tester) async {
      final serviceDate = DateTime(2026, 7, 2);

      final firstShift = Shift(
        description: 'Primo servizio',
        start: DateTime(2026, 7, 2, 5),
        end: DateTime(2026, 7, 2, 17),
        serviceDate: serviceDate,
        absence: 'Nessuna',
        orderPublic: 'Nessuno',
        externalService: false,
      );

      final secondShift = Shift(
        description: 'Secondo servizio',
        start: DateTime(2026, 7, 2, 19),
        end: DateTime(2026, 7, 2, 23),
        serviceDate: serviceDate,
        absence: 'Nessuna',
        orderPublic: 'Nessuno',
        externalService: false,
      );

      final profile = UserPayProfile.defaultProfile().copyWith(
        overtimeDayRate: 12.00,
        overtimeNightOrHolidayRate: 13.50,
        monthlyOvertimePayableHoursLimit: 55,
      );

      await tester.binding.setSurfaceSize(const Size(1440, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: QuickAddShiftPage(
            onAdd: (_) {},
            rates: profile,
            activeDepartment: Department.repartoMobile,
            initialShift: secondShift,
            existingShifts: <Shift>[
              firstShift,
              secondShift,
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Modifica turno'), findsOneWidget);

      final previewTitle = find.text('Anteprima calcolo');

      await tester.scrollUntilVisible(
        previewTitle,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(previewTitle, findsOneWidget);

      expect(
        find.textContaining('Straordinario notturno (1h'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Straordinario diurno (3h'),
        findsOneWidget,
      );

      expect(find.text('€ 13.50'), findsOneWidget);
      expect(find.text('€ 36.00'), findsOneWidget);
      expect(find.text('€ 49.50'), findsOneWidget);

      expect(
        find.textContaining('Indennità servizio notturno'),
        findsNothing,
      );
    },
  );
}
