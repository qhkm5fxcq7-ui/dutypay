import '../models/shift.dart';
import '../models/user_pay_profile.dart';
import 'shift_rate_calculator.dart';

class ShiftValueCalculator {
  const ShiftValueCalculator._();

  static double getShiftValue(
    Shift shift, {
    ShiftDerivedRates? rates,
  }) {
    final profile = _profileFromRates(rates);
    return _round2(shift.getTotalAmount(profile));
  }

  static double calculateTotal(
    List<Shift> shifts, {
    ShiftDerivedRates? rates,
  }) {
    final profile = _profileFromRates(rates);

    double total = 0.0;
    for (final shift in shifts) {
      total += shift.getTotalAmount(profile);
    }

    return _round2(total);
  }

  static UserPayProfile _profileFromRates(ShiftDerivedRates? rates) {
    final base = UserPayProfile.defaultProfile();

    if (rates == null) {
      return base;
    }

    return base.copyWith(
      overtimeDayRate: rates.straordinarioDiurnoOrario,
      holidayAllowance: rates.indennitaFestivaPerTurno,
      orderPublicInSede: rates.ordinePubblicoInSedePerTurno,
      externalServiceRate: rates.servizioEsternoPerTurno,
    );
  }

  static double _round2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}