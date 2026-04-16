import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

class CanonicalShiftScenarios {
  const CanonicalShiftScenarios._();

  static UserPayProfile defaultProfile() {
    return UserPayProfile.defaultProfile();
  }

  // =========================
  // REPARTO MOBILE
  // =========================

  /// RM standard mattina:
  /// 06:00 -> 12:00
  /// Atteso: 6.0h lavorate, 0 straordinario
  static Shift rmStandardMorning({
    DateTime? serviceDate,
    String description = 'RM standard mattina',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 1);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 6, 0),
      end: DateTime(day.year, day.month, day.day, 12, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Nessuno',
      externalService: false,
    );
  }

  /// RM mattina con 30 minuti di straordinario:
  /// 06:00 -> 12:30
  /// Atteso: 6.5h lavorate, 0.5h straordinario diurno
  static Shift rmMorningWithHalfHourOvertime({
    DateTime? serviceDate,
    String description = 'RM mattina con mezzora straordinario',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 1);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 6, 0),
      end: DateTime(day.year, day.month, day.day, 12, 30),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Nessuno',
      externalService: false,
    );
  }

  /// RM lungo con OP fuori sede:
  /// 15:00 -> 02:00
  /// Atteso: 11h lavorate, 5h straordinario
  static Shift rmLongOpFuoriSede({
    DateTime? serviceDate,
    String description = 'RM lungo OP fuori sede',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 10);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 15, 0),
      end: DateTime(day.year, day.month, day.day + 1, 2, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Fuori sede',
      externalService: false,
    );
  }

  /// RM lungo con OP fuori sede e passaggio a domenica/festivo:
  /// 15:00 -> 02:00 del giorno successivo
  static Shift rmLongOpFuoriSedeSundayCrossing({
    DateTime? serviceDate,
    String description = 'RM lungo OP fuori sede verso festivo',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 11);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 15, 0),
      end: DateTime(day.year, day.month, day.day + 1, 2, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Fuori sede',
      externalService: false,
    );
  }

  /// RM turno lungo con mezz'ora iniziale notturna:
  /// 05:30 -> 18:30
  /// Atteso: 13h lavorate, 7h straordinario diurno, 0.5h notturno ordinario
  static Shift rmLongMorningNightEdge({
    DateTime? serviceDate,
    String description = 'RM lungo con bordo notturno',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 2);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 5, 30),
      end: DateTime(day.year, day.month, day.day, 18, 30),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Fuori sede',
      externalService: false,
    );
  }

  /// RM OP in sede con overtime misto:
  /// 15:00 -> 00:00
  /// Atteso: 9h lavorate, 3h straordinario (2 diurno + 1 notturno)
  static Shift rmOpInSedeMixedOvertime({
    DateTime? serviceDate,
    String description = 'RM OP in sede misto',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 15);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 15, 0),
      end: DateTime(day.year, day.month, day.day + 1, 0, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'In sede',
      externalService: false,
    );
  }

  /// RM sera 6h con 1h notturna ordinaria:
  /// 17:00 -> 23:00
  /// Atteso: 6h lavorate, 0 straordinario, 1h notturna ordinaria
  static Shift rmEveningSixHoursWithOrdinaryNight({
    DateTime? serviceDate,
    String description = 'RM 17:00 -> 23:00',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 16);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 17, 0),
      end: DateTime(day.year, day.month, day.day, 23, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Nessuno',
      externalService: false,
    );
  }

  /// RM sera/notte con notturno ordinario + straordinario notturno:
  /// 17:00 -> 01:00
  /// Atteso:
  /// - 8h lavorate
  /// - 2h straordinario
  /// - 1h notturna ordinaria (22:00 -> 23:00)
  /// - 2h notturno straordinario (23:00 -> 01:00)
    static Shift rmEveningWithOrdinaryAndOvertimeNight({
    DateTime? serviceDate,
    String description = 'RM 17:00 -> 01:00',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 10);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 17, 0),
      end: DateTime(day.year, day.month, day.day + 1, 1, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      orderPublic: 'Nessuno',
      externalService: false,
    );
  }

  /// Giorno assenza
  static Shift absence({
    DateTime? serviceDate,
    String description = 'Assenza',
    String absenceCode = 'RIP',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 5);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 7, 0),
      end: DateTime(day.year, day.month, day.day, 13, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: absenceCode,
      orderPublic: 'Nessuno',
      externalService: false,
    );
  }

  // =========================
  // POLFER
  // =========================

  /// Polfer mattina standard:
  /// 06:55 -> 13:08
  /// Atteso: zero straordinario
  static Shift polferStandardMorning({
    DateTime? serviceDate,
    String description = 'Polfer mattina standard',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 1);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 6, 55),
      end: DateTime(day.year, day.month, day.day, 13, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'mattina',
    );
  }

  /// Polfer pomeriggio standard:
  /// 12:55 -> 19:08
  /// Atteso: zero straordinario
  static Shift polferStandardAfternoon({
    DateTime? serviceDate,
    String description = 'Polfer pomeriggio standard',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 1);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 12, 55),
      end: DateTime(day.year, day.month, day.day, 19, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'pomeriggio',
    );
  }

  /// Polfer sera standard:
  /// 18:55 -> 00:08
  /// Atteso: zero straordinario, sola indennità notturna ordinaria
  static Shift polferStandardEvening({
    DateTime? serviceDate,
    String description = 'Polfer sera standard',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 2);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 18, 55),
      end: DateTime(day.year, day.month, day.day + 1, 0, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'sera',
    );
  }

  /// Polfer notte standard:
  /// 23:55 -> 07:08
  /// Atteso: zero straordinario, sola indennità notturna ordinaria
  static Shift polferStandardNight({
    DateTime? serviceDate,
    String description = 'Polfer notte standard',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 2);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 23, 55),
      end: DateTime(day.year, day.month, day.day + 1, 7, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'notte',
    );
  }

  /// Polfer con controllo territorio serale
  static Shift polferWithTerritorySerale({
    DateTime? serviceDate,
    String description = 'Polfer con controllo territorio serale',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 3);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 12, 55),
      end: DateTime(day.year, day.month, day.day, 19, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'pomeriggio',
      polferTerritoryControlType: PolferTerritoryControlType.serale,
    );
  }

  /// Polfer con scalo ridotto
  static Shift polferWithScaloRidotto({
    DateTime? serviceDate,
    String description = 'Polfer con scalo ridotto',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 2);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 18, 55),
      end: DateTime(day.year, day.month, day.day + 1, 0, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'sera',
      polferScaloMode: PolferScaloMode.ridotta,
    );
  }

  /// Polfer con scalo intero
  static Shift polferWithScaloIntero({
    DateTime? serviceDate,
    String description = 'Polfer con scalo intero',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 2);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 18, 55),
      end: DateTime(day.year, day.month, day.day + 1, 0, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'sera',
      polferScaloMode: PolferScaloMode.intera,
    );
  }

  /// Polfer con scalo manuale misto
  static Shift polferWithManualMixedScalo({
    DateTime? serviceDate,
    String description = 'Polfer con scalo misto manuale',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 4);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 18, 55),
      end: DateTime(day.year, day.month, day.day + 1, 0, 8),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      spmnPresetCode: 'sera',
      polferScaloManualOverride: true,
      polferScaloReducedDayHours: 2.0,
      polferScaloReducedNightHours: 1.0,
      polferScaloFullDayHours: 1.0,
      polferScaloFullNightHours: 1.0,
    );
  }

  // =========================
  // MANUAL ACCESSORY TOGGLES
  // =========================

  static Shift shiftWithCompensazione({
    DateTime? serviceDate,
    String description = 'Turno con compensazione',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 6);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 7, 0),
      end: DateTime(day.year, day.month, day.day, 13, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      hasCompensazione: true,
    );
  }

  static Shift shiftWithReperibilita({
    DateTime? serviceDate,
    String description = 'Turno con reperibilita',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 6);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 7, 0),
      end: DateTime(day.year, day.month, day.day, 13, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      hasReperibilita: true,
    );
  }

  static Shift shiftWithBothManualAccessories({
    DateTime? serviceDate,
    String description = 'Turno con compensazione e reperibilita',
  }) {
    final day = serviceDate ?? DateTime(2026, 4, 6);

    return Shift(
      description: description,
      start: DateTime(day.year, day.month, day.day, 7, 0),
      end: DateTime(day.year, day.month, day.day, 13, 0),
      serviceDate: DateTime(day.year, day.month, day.day),
      absence: 'Nessuna',
      hasCompensazione: true,
      hasReperibilita: true,
    );
  }
}