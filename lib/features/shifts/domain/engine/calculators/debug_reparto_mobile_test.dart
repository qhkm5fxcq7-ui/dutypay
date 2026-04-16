import '../../entities/shift.dart';
import '../../entities/user_pay_profile.dart';
import '../policies/reparto_mobile_policy.dart';

void debugRepartoMobilePolicy() {
  final policy = RepartoMobilePolicy();
  final profile = UserPayProfile.defaultProfile();

  final cases = [
    Shift(
      description: '18:00-01:30',
      start: DateTime(2026, 4, 10, 18, 0),
      end: DateTime(2026, 4, 11, 1, 30),
      serviceDate: DateTime(2026, 4, 10),
    ),
    Shift(
      description: '12:00-20:00',
      start: DateTime(2026, 4, 10, 12, 0),
      end: DateTime(2026, 4, 10, 20, 0),
      serviceDate: DateTime(2026, 4, 10),
    ),
    Shift(
      description: '23:00-07:00',
      start: DateTime(2026, 4, 10, 23, 0),
      end: DateTime(2026, 4, 11, 7, 0),
      serviceDate: DateTime(2026, 4, 10),
    ),
  ];

  for (final shift in cases) {
    final result = policy.calculateShift(shift, profile);

    print('--- ${shift.description} ---');
    print('workedHours: ${result.workedHours}');
    print('ordinaryHours: ${result.ordinaryHours}');
    print('overtimeHours: ${result.overtimeHours}');
    print('nightHours: ${result.nightHours}');
    print('holidayHours: ${result.holidayHours}');
    print('totalGross: ${result.totalGross}');
  }
}