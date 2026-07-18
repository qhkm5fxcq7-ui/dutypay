import 'package:flutter_test/flutter_test.dart';

import 'package:dutypay/features/shifts/application/usecases/build_monthly_accessory_summary_usecase.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  test(
    'monthly summary preserves daily context overtime for double services',
    () {
      final profile = UserPayProfile.defaultProfile().copyWith(
        monthlyOvertimePayableHoursLimit: 55,
      );

      final firstShift = Shift(
        description: 'Servizio principale',
        start: DateTime(2026, 1, 7, 8),
        end: DateTime(2026, 1, 7, 14),
        serviceDate: DateTime(2026, 1, 7),
        absence: 'Nessuna',
        orderPublic: 'Nessuno',
        externalService: false,
      );

      final secondShift = Shift(
        description: 'Secondo servizio',
        start: DateTime(2026, 1, 7, 14),
        end: DateTime(2026, 1, 7, 20, 30),
        serviceDate: DateTime(2026, 1, 7),
        absence: 'Nessuna',
        orderPublic: 'Nessuno',
        externalService: false,
      );

      const useCase = BuildMonthlyAccessorySummaryUseCase();

      final result = useCase.execute(
        month: DateTime(2026, 1),
        allShifts: [firstShift, secondShift],
        profile: profile,
        department: Department.repartoMobile,
      );

      // Totale lavorato: 12.5h.
      // Quota ordinaria giornaliera: 6h una sola volta.
      // Straordinario corretto: 6.5h.
      expect(
        result.overtimeHours,
        closeTo(6.5, 0.01),
      );
    },
  );
}
