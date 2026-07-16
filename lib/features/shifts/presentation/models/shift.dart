import 'user_pay_profile.dart';
import '../../domain/engine/helpers/date_classification_helper.dart';
import '../../domain/engine/helpers/shift_time_helper.dart';
import '../../domain/engine/helpers/time_band_helper.dart';

enum OpServiceType {
  none,
  inSede,
  fuoriSedeOneTurno,
  fuoriSedeIntera,
}

enum PolferTerritoryControlType {
  none,
  serale,
  notturno,
}

enum PolferScaloMode {
  none,
  ridotta,
  intera,
}

enum QuesturaMode {
  uffici,
  volanti,
}

enum QuesturaPreset {
  none,
  mattina,
  pomeriggio,
  sera,
  notte,
  smontante,
  riposo,
  aggiornamento,
}

enum OvertimeDestination {
  payment,
  compensative,
}

enum QuesturaOfficeProfile {
  sixHours,
  settimanaCorta,
  settimanaLunga,
  custom,
}

class _OvertimeSegment {
  final double hours;
  final bool isNight;
  final bool isHoliday;

  const _OvertimeSegment({
    required this.hours,
    required this.isNight,
    required this.isHoliday,
  });
}

class TimeOfDayLike {
  final int hour;
  final int minute;

  const TimeOfDayLike(this.hour, this.minute);
}

class Shift {
  final String description;
  final DateTime start;
  final DateTime end;
  final DateTime serviceDate;

  final String orderPublic;
  final bool externalService;
  final String absence;

  final double manualExtraAmount;
  final String manualExtraLabel;

  final bool hasMission;
  final double missionAmount;

  final bool genereDiConfortoCdg;
  final bool genereDiConforto;
  final bool ticketPasto;

  final double straordinarioDiurnoHours;
  final double straordinarioNotturnoFestivoHours;
  final int notturnoCount;
  final int festivoCount;
  final int servizioEsternoCount;
  final OpServiceType opServiceType;
  final double manualAmount;
  final String note;

  final OvertimeDestination overtimeDestination;

  final String spmnPresetCode;
  final QuesturaMode questuraMode;
  final QuesturaPreset questuraPreset;
  final QuesturaOfficeProfile questuraOfficeProfile;
  final double questuraOfficeOrdinaryHours;

  final double? workedHoursOverride;

  final PolferTerritoryControlType polferTerritoryControlType;
  final PolferScaloMode polferScaloMode;
  final bool polferScaloManualOverride;
  final bool hasCompensazione;
  final bool hasReperibilita;
  final bool hasAutostradaService;

  final double polferScaloReducedDayHours;
  final double polferScaloReducedNightHours;
  final double polferScaloFullDayHours;
  final double polferScaloFullNightHours;

  final double compensativeOvertimeHours;
  final String compensativeOvertimeNote;
  final double compensativeRecoveryHours;

  final bool programmedOvertimeEnabled;
  final DateTime? programmedOvertimeStart;
  final DateTime? programmedOvertimeEnd;
  final String programmedOvertimeNote;

  final bool ordinaryHoursOverrideEnabled;
  final double ordinaryHoursOverride;
  final String ordinaryHoursOverrideNote;

  static const double standardHours = 6.0;

  static const double fallbackOvertimeDayRate = 12.80;
  static const double fallbackOvertimeNightOrHolidayRate = 14.49;
  static const double fallbackOvertimeNightAndHolidayRate = 16.71;

  static const double fallbackNightAllowance = 4.30;
  static const double fallbackHolidayAllowance = 14.00;
  static const double fallbackSpecialHolidayAllowance = 40.00;

  static const double fallbackOrderPublicInSede = 13.00;
  static const double fallbackOrderPublicFuoriSede = 18.20;
  static const double fallbackOrderPublicPernotto = 26.00;

  static const double fallbackExternalServiceRate = 6.00;

  static const double fallbackPolferTerritorySeraleRate = 5.00;
  static const double fallbackPolferTerritoryNotturnoRate = 10.00;

  static const double fallbackOrdinaryNightShiftAmount = 14.53;

  static const double fallbackGenereDiConfortoCdgRate = 0.72;

  static const double polferScaloReducedDayRate = 0.31;
  static const double polferScaloReducedNightRate = 0.77;
  static const double polferScaloFullDayRate = 1.00;
  static const double polferScaloFullNightRate = 2.50;

  factory Shift({
    String description = '',
    DateTime? start,
    DateTime? end,
    DateTime? serviceDate,
    String orderPublic = 'Nessuno',
    bool externalService = false,
    String absence = 'Nessuna',
    double manualExtraAmount = 0.0,
    String manualExtraLabel = '',
    bool hasMission = false,
    double missionAmount = 0.0,
    bool genereDiConfortoCdg = false,
    bool genereDiConforto = false,
    bool ticketPasto = false,
    DateTime? date,
    double? workedHours,
    bool hasCompensazione = false,
    bool hasReperibilita = false,
    bool hasAutostradaService = false,
    double straordinarioDiurnoHours = 0.0,
    double straordinarioNotturnoFestivoHours = 0.0,
    int notturnoCount = 0,
    int festivoCount = 0,
    int servizioEsternoCount = 0,
    OpServiceType opServiceType = OpServiceType.none,
    double manualAmount = 0.0,
    String note = '',
    String spmnPresetCode = '',
    QuesturaMode questuraMode = QuesturaMode.uffici,
    QuesturaPreset questuraPreset = QuesturaPreset.none,
    QuesturaOfficeProfile questuraOfficeProfile =
        QuesturaOfficeProfile.sixHours,
    double questuraOfficeOrdinaryHours = 6.0,
    PolferTerritoryControlType polferTerritoryControlType =
        PolferTerritoryControlType.none,
    PolferScaloMode polferScaloMode = PolferScaloMode.none,
    bool polferScaloManualOverride = false,
    double polferScaloReducedDayHours = 0.0,
    double polferScaloReducedNightHours = 0.0,
    double polferScaloFullDayHours = 0.0,
    double polferScaloFullNightHours = 0.0,
    OvertimeDestination overtimeDestination = OvertimeDestination.payment,
    double compensativeOvertimeHours = 0.0,
    String compensativeOvertimeNote = '',
    double compensativeRecoveryHours = 0.0,
    bool programmedOvertimeEnabled = false,
    DateTime? programmedOvertimeStart,
    DateTime? programmedOvertimeEnd,
    String programmedOvertimeNote = '',
    bool ordinaryHoursOverrideEnabled = false,
    double ordinaryHoursOverride = 0.0,
    String ordinaryHoursOverrideNote = '',
  }) {
    final resolvedStart = start ?? date ?? DateTime.now();
    final resolvedWorkedHours = workedHours ?? standardHours;
    final resolvedEnd = end ??
        resolvedStart.add(
          Duration(minutes: (resolvedWorkedHours * 60).round()),
        );

    final resolvedServiceDate = _normalizeDate(
      serviceDate ??
          _deriveServiceDate(
            resolvedStart,
            resolvedEnd,
            spmnPresetCode: spmnPresetCode,
            questuraPreset: questuraPreset,
          ),
    );

    final resolvedOrderPublic = _normalizeOrderPublic(
      orderPublic: orderPublic,
      opServiceType: opServiceType,
    );

    final resolvedExternalService = externalService || servizioEsternoCount > 0;

    final resolvedManualExtraAmount =
        manualExtraAmount > 0 ? manualExtraAmount : manualAmount;

    final resolvedManualExtraLabel =
        manualExtraLabel.trim().isNotEmpty ? manualExtraLabel : note;

    return Shift._internal(
      description: description,
      start: resolvedStart,
      end: resolvedEnd,
      serviceDate: resolvedServiceDate,
      orderPublic: resolvedOrderPublic,
      externalService: resolvedExternalService,
      absence: absence,
      manualExtraAmount: resolvedManualExtraAmount,
      manualExtraLabel: resolvedManualExtraLabel,
      hasMission: hasMission,
      missionAmount: missionAmount,
      genereDiConfortoCdg: genereDiConfortoCdg,
      genereDiConforto: genereDiConforto,
      ticketPasto: ticketPasto,
      hasCompensazione: hasCompensazione,
      hasReperibilita: hasReperibilita,
      hasAutostradaService: hasAutostradaService,
      straordinarioDiurnoHours: straordinarioDiurnoHours,
      straordinarioNotturnoFestivoHours: straordinarioNotturnoFestivoHours,
      notturnoCount: notturnoCount,
      festivoCount: festivoCount,
      servizioEsternoCount: servizioEsternoCount,
      opServiceType: opServiceType,
      manualAmount: manualAmount,
      note: note,
      spmnPresetCode: spmnPresetCode,
      questuraMode: questuraMode,
      questuraPreset: questuraPreset,
      questuraOfficeProfile: questuraOfficeProfile,
      questuraOfficeOrdinaryHours: questuraOfficeOrdinaryHours,
      workedHoursOverride: workedHours,
      polferTerritoryControlType: polferTerritoryControlType,
      polferScaloMode: polferScaloMode,
      polferScaloManualOverride: polferScaloManualOverride,
      polferScaloReducedDayHours: polferScaloReducedDayHours,
      polferScaloReducedNightHours: polferScaloReducedNightHours,
      polferScaloFullDayHours: polferScaloFullDayHours,
      polferScaloFullNightHours: polferScaloFullNightHours,
      overtimeDestination: overtimeDestination,
      compensativeOvertimeHours: compensativeOvertimeHours,
      compensativeOvertimeNote: compensativeOvertimeNote,
      compensativeRecoveryHours: compensativeRecoveryHours,
      programmedOvertimeEnabled: programmedOvertimeEnabled,
      programmedOvertimeStart: programmedOvertimeStart,
      programmedOvertimeEnd: programmedOvertimeEnd,
      programmedOvertimeNote: programmedOvertimeNote,
      ordinaryHoursOverrideEnabled: ordinaryHoursOverrideEnabled,
      ordinaryHoursOverride: ordinaryHoursOverride,
      ordinaryHoursOverrideNote: ordinaryHoursOverrideNote,
    );
  }

  const Shift._internal({
    required this.description,
    required this.start,
    required this.end,
    required this.serviceDate,
    required this.orderPublic,
    required this.externalService,
    required this.absence,
    required this.manualExtraAmount,
    required this.manualExtraLabel,
    this.hasMission = false,
    this.missionAmount = 0.0,
    required this.genereDiConfortoCdg,
    required this.genereDiConforto,
    required this.ticketPasto,
    this.hasCompensazione = false,
    this.hasReperibilita = false,
    this.hasAutostradaService = false,
    required this.straordinarioDiurnoHours,
    required this.straordinarioNotturnoFestivoHours,
    required this.notturnoCount,
    required this.festivoCount,
    required this.servizioEsternoCount,
    required this.opServiceType,
    required this.manualAmount,
    required this.note,
    required this.questuraMode,
    required this.questuraPreset,
    required this.questuraOfficeProfile,
    required this.questuraOfficeOrdinaryHours,
    required this.spmnPresetCode,
    required this.workedHoursOverride,
    required this.polferTerritoryControlType,
    required this.polferScaloMode,
    required this.polferScaloManualOverride,
    required this.polferScaloReducedDayHours,
    required this.polferScaloReducedNightHours,
    required this.polferScaloFullDayHours,
    required this.polferScaloFullNightHours,
    required this.overtimeDestination,
    required this.compensativeOvertimeHours,
    required this.compensativeOvertimeNote,
    required this.compensativeRecoveryHours,
    required this.programmedOvertimeEnabled,
    required this.programmedOvertimeStart,
    required this.programmedOvertimeEnd,
    required this.programmedOvertimeNote,
    required this.ordinaryHoursOverrideEnabled,
    required this.ordinaryHoursOverride,
    required this.ordinaryHoursOverrideNote,
  });

  Shift copyWith({
    String? description,
    DateTime? start,
    DateTime? end,
    DateTime? serviceDate,
    String? orderPublic,
    bool? externalService,
    String? absence,
    double? manualExtraAmount,
    String? manualExtraLabel,
    bool? hasMission,
    double? missionAmount,
    bool? genereDiConfortoCdg,
    bool? genereDiConforto,
    bool? ticketPasto,
    bool? hasCompensazione,
    bool? hasReperibilita,
    bool? hasAutostradaService,
    double? straordinarioDiurnoHours,
    double? straordinarioNotturnoFestivoHours,
    int? notturnoCount,
    int? festivoCount,
    int? servizioEsternoCount,
    OpServiceType? opServiceType,
    double? manualAmount,
    String? note,
    String? spmnPresetCode,
    QuesturaMode? questuraMode,
    QuesturaPreset? questuraPreset,
    QuesturaOfficeProfile? questuraOfficeProfile,
    double? questuraOfficeOrdinaryHours,
    double? workedHoursOverride,
    PolferTerritoryControlType? polferTerritoryControlType,
    PolferScaloMode? polferScaloMode,
    bool? polferScaloManualOverride,
    double? polferScaloReducedDayHours,
    double? polferScaloReducedNightHours,
    double? polferScaloFullDayHours,
    double? polferScaloFullNightHours,
    OvertimeDestination? overtimeDestination,
    double? compensativeOvertimeHours,
    String? compensativeOvertimeNote,
    double? compensativeRecoveryHours,
    bool? programmedOvertimeEnabled,
    DateTime? programmedOvertimeStart,
    DateTime? programmedOvertimeEnd,
    String? programmedOvertimeNote,
    bool? ordinaryHoursOverrideEnabled,
    double? ordinaryHoursOverride,
    String? ordinaryHoursOverrideNote,
  }) {
    final nextStart = start ?? this.start;
    final nextEnd = end ?? this.end;

    return Shift._internal(
      description: description ?? this.description,
      start: nextStart,
      end: nextEnd,
      serviceDate: _normalizeDate(serviceDate ?? this.serviceDate),
      orderPublic: orderPublic ?? this.orderPublic,
      externalService: externalService ?? this.externalService,
      absence: absence ?? this.absence,
      manualExtraAmount: manualExtraAmount ?? this.manualExtraAmount,
      manualExtraLabel: manualExtraLabel ?? this.manualExtraLabel,
      hasMission: hasMission ?? this.hasMission,
      missionAmount: missionAmount ?? this.missionAmount,
      genereDiConfortoCdg: genereDiConfortoCdg ?? this.genereDiConfortoCdg,
      genereDiConforto: genereDiConforto ?? this.genereDiConforto,
      ticketPasto: ticketPasto ?? this.ticketPasto,
      hasCompensazione: hasCompensazione ?? this.hasCompensazione,
      hasReperibilita: hasReperibilita ?? this.hasReperibilita,
      hasAutostradaService: hasAutostradaService ?? this.hasAutostradaService,
      straordinarioDiurnoHours:
          straordinarioDiurnoHours ?? this.straordinarioDiurnoHours,
      straordinarioNotturnoFestivoHours: straordinarioNotturnoFestivoHours ??
          this.straordinarioNotturnoFestivoHours,
      notturnoCount: notturnoCount ?? this.notturnoCount,
      festivoCount: festivoCount ?? this.festivoCount,
      servizioEsternoCount: servizioEsternoCount ?? this.servizioEsternoCount,
      opServiceType: opServiceType ?? this.opServiceType,
      manualAmount: manualAmount ?? this.manualAmount,
      note: note ?? this.note,
      spmnPresetCode: spmnPresetCode ?? this.spmnPresetCode,
      questuraMode: questuraMode ?? this.questuraMode,
      questuraPreset: questuraPreset ?? this.questuraPreset,
      questuraOfficeProfile:
          questuraOfficeProfile ?? this.questuraOfficeProfile,
      questuraOfficeOrdinaryHours:
          questuraOfficeOrdinaryHours ?? this.questuraOfficeOrdinaryHours,
      workedHoursOverride: workedHoursOverride ?? this.workedHoursOverride,
      polferTerritoryControlType:
          polferTerritoryControlType ?? this.polferTerritoryControlType,
      polferScaloMode: polferScaloMode ?? this.polferScaloMode,
      polferScaloManualOverride:
          polferScaloManualOverride ?? this.polferScaloManualOverride,
      polferScaloReducedDayHours:
          polferScaloReducedDayHours ?? this.polferScaloReducedDayHours,
      polferScaloReducedNightHours:
          polferScaloReducedNightHours ?? this.polferScaloReducedNightHours,
      polferScaloFullDayHours:
          polferScaloFullDayHours ?? this.polferScaloFullDayHours,
      polferScaloFullNightHours:
          polferScaloFullNightHours ?? this.polferScaloFullNightHours,
      overtimeDestination: overtimeDestination ?? this.overtimeDestination,
      compensativeOvertimeHours:
          compensativeOvertimeHours ?? this.compensativeOvertimeHours,
      compensativeOvertimeNote:
          compensativeOvertimeNote ?? this.compensativeOvertimeNote,
      compensativeRecoveryHours:
          compensativeRecoveryHours ?? this.compensativeRecoveryHours,
      programmedOvertimeEnabled:
          programmedOvertimeEnabled ?? this.programmedOvertimeEnabled,
      programmedOvertimeStart:
          programmedOvertimeStart ?? this.programmedOvertimeStart,
      programmedOvertimeEnd:
          programmedOvertimeEnd ?? this.programmedOvertimeEnd,
      programmedOvertimeNote:
          programmedOvertimeNote ?? this.programmedOvertimeNote,
      ordinaryHoursOverrideEnabled:
          ordinaryHoursOverrideEnabled ?? this.ordinaryHoursOverrideEnabled,
      ordinaryHoursOverride:
          ordinaryHoursOverride ?? this.ordinaryHoursOverride,
      ordinaryHoursOverrideNote:
          ordinaryHoursOverrideNote ?? this.ordinaryHoursOverrideNote,
    );
  }

  DateTime get date => serviceDate;

  double get hours {
    final diffMinutes = end.difference(start).inMinutes;
    return diffMinutes > 0 ? diffMinutes / 60.0 : 0.0;
  }

  double getOrdinaryNightShiftAmount([UserPayProfile? profile]) {
    return 0.0;
  }

  double get workedHours => workedHoursOverride ?? hours;
  double get totalHours => workedHours;

  bool get hasAbsence => absence != 'Nessuna';
  bool get hasManualExtra => manualExtraAmount > 0 || manualAmount > 0;

  bool get crossesMidnight {
    return end.day != start.day ||
        end.month != start.month ||
        end.year != start.year;
  }

  bool get touchesNightBand {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    const nightStart = 22 * 60;
    const nightEnd = 6 * 60;

    if (crossesMidnight) return true;
    if (startMinutes >= nightStart) return true;
    if (endMinutes <= nightEnd) return true;

    return false;
  }

  bool get isSunday => serviceDate.weekday == DateTime.sunday;

  bool get isSuperHoliday {
    return DateClassificationHelper.matchesAnyDate(
      serviceDate,
      DateClassificationHelper.superHolidayDates(serviceDate.year),
    );
  }

  bool get isHoliday {
    return DateClassificationHelper.isHolidayDate(serviceDate);
  }

  double get overtimeHours {
    if (hasAbsence) return 0.0;

    final legacyTotal =
        straordinarioDiurnoHours + straordinarioNotturnoFestivoHours;
    if (legacyTotal > 0) return legacyTotal;

    final overtimeStart = _getOvertimeStart();
    final normalizedEnd = _normalizedShiftEnd;

    if (!normalizedEnd.isAfter(overtimeStart)) return 0.0;

    final minutes = normalizedEnd.difference(overtimeStart).inMinutes;
    if (minutes <= 0) return 0.0;

    return minutes / 60.0;
  }

  DateTime get _normalizedShiftEnd {
    return ShiftTimeHelper.normalizedEnd(start, end);
  }

  DateTime _getOvertimeStart() {
    final normalizedEnd = _normalizedShiftEnd;
    final polferThreshold = _getPolferOvertimeThreshold();

    if (polferThreshold != null) {
      return normalizedEnd.isAfter(polferThreshold)
          ? polferThreshold
          : normalizedEnd;
    }

    final standardEnd = start.add(
      Duration(minutes: (standardHours * 60).round()),
    );

    return normalizedEnd.isAfter(standardEnd) ? standardEnd : normalizedEnd;
  }

  DateTime? _getPolferOvertimeThreshold() {
    final code = spmnPresetCode.trim().toLowerCase();

    TimeOfDayLike? matchedPreset;

    if (code.contains('notte')) {
      matchedPreset = const TimeOfDayLike(23, 55);
    } else if (code.contains('sera')) {
      matchedPreset = const TimeOfDayLike(18, 55);
    } else if (code.contains('pomeriggio')) {
      matchedPreset = const TimeOfDayLike(12, 55);
    } else if (code.contains('mattina')) {
      matchedPreset = const TimeOfDayLike(6, 55);
    } else {
      final startHour = start.hour;
      final startMinute = start.minute;

      if (startHour == 23 && startMinute == 55) {
        matchedPreset = const TimeOfDayLike(23, 55);
      } else if (startHour == 18 && startMinute == 55) {
        matchedPreset = const TimeOfDayLike(18, 55);
      } else if (startHour == 12 && startMinute == 55) {
        matchedPreset = const TimeOfDayLike(12, 55);
      } else if (startHour == 6 && startMinute == 55) {
        matchedPreset = const TimeOfDayLike(6, 55);
      }
    }

    if (matchedPreset == null) return null;

    if (matchedPreset.hour == 23 && matchedPreset.minute == 55) {
      return DateTime(start.year, start.month, start.day + 1, 7, 8);
    }

    if (matchedPreset.hour == 18 && matchedPreset.minute == 55) {
      return DateTime(start.year, start.month, start.day + 1, 0, 8);
    }

    if (matchedPreset.hour == 12 && matchedPreset.minute == 55) {
      return DateTime(start.year, start.month, start.day, 19, 8);
    }

    if (matchedPreset.hour == 6 && matchedPreset.minute == 55) {
      return DateTime(start.year, start.month, start.day, 13, 8);
    }

    return null;
  }

  bool _isNightMoment(DateTime moment) {
    return TimeBandHelper.isNightMoment(moment);
  }

  bool _isHolidayDate(DateTime date) {
    return DateClassificationHelper.isHolidayDate(date);
  }

  DateTime _nextBoundary(DateTime current, DateTime limit) {
    return TimeBandHelper.nextBoundary(current, limit);
  }

  List<_OvertimeSegment> _buildOvertimeSegments() {
    if (hasAbsence) return const [];
    if (overtimeHours <= 0) return const [];
    if (isLegacyQuantifiedShift) return const [];

    final overtimeStart = _getOvertimeStart();
    final overtimeEnd = _normalizedShiftEnd;

    if (!overtimeEnd.isAfter(overtimeStart)) return const [];

    final segments = <_OvertimeSegment>[];
    var cursor = overtimeStart;

    while (cursor.isBefore(overtimeEnd)) {
      final next = _nextBoundary(cursor, overtimeEnd);
      final minutes = next.difference(cursor).inMinutes;

      if (minutes > 0) {
        segments.add(
          _OvertimeSegment(
            hours: minutes / 60.0,
            isNight: _isNightMoment(cursor),
            isHoliday: _isHolidayDate(cursor),
          ),
        );
      }

      cursor = next;
    }

    return segments;
  }

  double get segmentedOvertimeDayHours {
    return _buildOvertimeSegments()
        .where((s) => !s.isNight && !s.isHoliday)
        .fold(0.0, (sum, s) => sum + s.hours);
  }

  double get segmentedOvertimeNightHours {
    return _buildOvertimeSegments()
        .where((s) => s.isNight && !s.isHoliday)
        .fold(0.0, (sum, s) => sum + s.hours);
  }

  double get segmentedOvertimeHolidayDayHours {
    return _buildOvertimeSegments()
        .where((s) => !s.isNight && s.isHoliday)
        .fold(0.0, (sum, s) => sum + s.hours);
  }

  double get segmentedOvertimeNightHolidayHours {
    return _buildOvertimeSegments()
        .where((s) => s.isNight && s.isHoliday)
        .fold(0.0, (sum, s) => sum + s.hours);
  }

  double get overtimeNightHours {
    if (hasAbsence) return 0.0;
    if (overtimeHours <= 0) return 0.0;
    if (isLegacyQuantifiedShift) return straordinarioNotturnoFestivoHours;

    return segmentedOvertimeNightHours + segmentedOvertimeNightHolidayHours;
  }

  double get overtimeDayHours {
    if (hasAbsence) return 0.0;
    if (overtimeHours <= 0) return 0.0;
    if (isLegacyQuantifiedShift) return straordinarioDiurnoHours;

    return segmentedOvertimeDayHours + segmentedOvertimeHolidayDayHours;
  }

  bool get usesExternalService => !hasAbsence && externalService;

  UserPayProfile _effectiveProfile(UserPayProfile? profile) {
    return profile ?? UserPayProfile.defaultProfile();
  }

  bool get isLegacyQuantifiedShift {
    return straordinarioDiurnoHours > 0 ||
        straordinarioNotturnoFestivoHours > 0 ||
        notturnoCount > 0 ||
        festivoCount > 0 ||
        servizioEsternoCount > 0 ||
        opServiceType != OpServiceType.none ||
        manualAmount > 0 ||
        note.trim().isNotEmpty;
  }

  bool _isApprox(double a, double b) {
    return (a - b).abs() < 0.001;
  }

  double _sanitizeRate(double value, double fallback) {
    if (value.isNaN || !value.isFinite || value <= 0) {
      return fallback;
    }
    return value;
  }

  double _resolvedOvertimeDayRate(UserPayProfile p) {
    final raw = _sanitizeRate(p.overtimeDayRate, fallbackOvertimeDayRate);
    if (_isApprox(raw, 12.0)) return fallbackOvertimeDayRate;
    return raw;
  }

  double _resolvedOvertimeNightOrHolidayRate(UserPayProfile p) {
    final raw = _sanitizeRate(
      p.overtimeNightOrHolidayRate,
      fallbackOvertimeNightOrHolidayRate,
    );
    if (_isApprox(raw, 13.5)) return fallbackOvertimeNightOrHolidayRate;
    return raw;
  }

  double _resolvedOvertimeNightAndHolidayRate(UserPayProfile p) {
    final raw = _sanitizeRate(
      p.overtimeNightAndHolidayRate,
      fallbackOvertimeNightAndHolidayRate,
    );
    if (_isApprox(raw, 15.0)) return fallbackOvertimeNightAndHolidayRate;
    return raw;
  }

  double _resolvedHolidayAllowance(UserPayProfile p) {
    final raw = _sanitizeRate(p.holidayAllowance, fallbackHolidayAllowance);
    if (_isApprox(raw, 8.0)) return fallbackHolidayAllowance;
    return raw;
  }

  double _resolvedSpecialHolidayAllowance(UserPayProfile p) {
    final raw = _sanitizeRate(
      p.specialHolidayAllowance,
      fallbackSpecialHolidayAllowance,
    );
    if (_isApprox(raw, 10.0)) return fallbackSpecialHolidayAllowance;
    return raw;
  }

  double _resolvedOrderPublicInSede(UserPayProfile p) {
    final raw = _sanitizeRate(p.orderPublicInSede, fallbackOrderPublicInSede);
    if (_isApprox(raw, 6.0)) return fallbackOrderPublicInSede;
    return raw;
  }

  double _resolvedOrderPublicFuoriSede(UserPayProfile p) {
    final raw = _sanitizeRate(
      p.orderPublicFuoriSede,
      fallbackOrderPublicFuoriSede,
    );
    if (_isApprox(raw, 10.0)) return fallbackOrderPublicFuoriSede;
    return raw;
  }

  double _resolvedOrderPublicPernotto(UserPayProfile p) {
    final raw = _sanitizeRate(
      p.orderPublicPernotto,
      fallbackOrderPublicPernotto,
    );
    if (_isApprox(raw, 15.0)) return fallbackOrderPublicPernotto;
    return raw;
  }

  double _resolvedExternalServiceRate(UserPayProfile p) {
    return _sanitizeRate(p.externalServiceRate, fallbackExternalServiceRate);
  }

  double _resolvedGenereDiConfortoCdgRate() {
    return fallbackGenereDiConfortoCdgRate;
  }

  double _resolvedGenereDiConfortoRate(UserPayProfile p) {
    return _sanitizeRate(p.genereDiConfortoRate, 1.02);
  }

  double _resolvedTicketPastoRate(UserPayProfile p) {
    return _sanitizeRate(p.ticketPastoRate, 7.00);
  }

  double _resolvedOvertimeNetMultiplier(UserPayProfile p) {
    final value = p.straordinarioNetMultiplier;
    if (value.isNaN || !value.isFinite || value <= 0 || value > 1) {
      return 0.67;
    }
    return value;
  }

  double getEstimatedNetAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);
    final netMultiplier = _resolvedOvertimeNetMultiplier(p);

    final taxableGross = getSalaryBreakdown(profile).fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    return taxableGross * netMultiplier;
  }

  double getOvertimeRate([UserPayProfile? profile]) {
    final p = _effectiveProfile(profile);

    final dayRate = _resolvedOvertimeDayRate(p);
    final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);
    final nightAndHolidayRate = _resolvedOvertimeNightAndHolidayRate(p);

    if (isLegacyQuantifiedShift) {
      if (touchesNightBand && isHoliday) {
        return nightAndHolidayRate;
      }
      if (touchesNightBand || isHoliday) {
        return nightOrHolidayRate;
      }
      return dayRate;
    }

    final segments = _buildOvertimeSegments();
    if (segments.isEmpty) return dayRate;

    final totalHours = segments.fold(0.0, (sum, s) => sum + s.hours);
    if (totalHours <= 0) return dayRate;

    double weightedAmount = 0.0;

    for (final segment in segments) {
      final rate = segment.isNight && segment.isHoliday
          ? nightAndHolidayRate
          : (segment.isNight || segment.isHoliday)
              ? nightOrHolidayRate
              : dayRate;

      weightedAmount += segment.hours * rate;
    }

    return weightedAmount / totalHours;
  }

  double getOvertimeAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);

    if (isLegacyQuantifiedShift) {
      final dayRate = _resolvedOvertimeDayRate(p);
      final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);

      final diurnoLordo = straordinarioDiurnoHours * dayRate;
      final nottFestLordo =
          straordinarioNotturnoFestivoHours * nightOrHolidayRate;

      return diurnoLordo + nottFestLordo;
    }

    final dayRate = _resolvedOvertimeDayRate(p);
    final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);
    final nightAndHolidayRate = _resolvedOvertimeNightAndHolidayRate(p);

    double lordo = 0.0;

    for (final segment in _buildOvertimeSegments()) {
      final rate = segment.isNight && segment.isHoliday
          ? nightAndHolidayRate
          : (segment.isNight || segment.isHoliday)
              ? nightOrHolidayRate
              : dayRate;

      lordo += segment.hours * rate;
    }

    return lordo;
  }

  double getOrderPublicAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);

    final inSedeRate = _resolvedOrderPublicInSede(p);
    final fuoriSedeRate = _resolvedOrderPublicFuoriSede(p);
    final pernottoRate = _resolvedOrderPublicPernotto(p);

    if (isLegacyQuantifiedShift) {
      switch (opServiceType) {
        case OpServiceType.none:
          return 0.0;
        case OpServiceType.inSede:
          return inSedeRate;
        case OpServiceType.fuoriSedeOneTurno:
          return fuoriSedeRate;
        case OpServiceType.fuoriSedeIntera:
          return pernottoRate;
      }
    }

    if (usesExternalService) return 0.0;

    switch (orderPublic) {
      case 'In sede':
        return inSedeRate;
      case 'Fuori sede':
        return fuoriSedeRate;
      case 'Pernotto':
        return pernottoRate;
      default:
        return 0.0;
    }
  }

  double getExternalServiceAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);
    final rate = _resolvedExternalServiceRate(p);

    if (isLegacyQuantifiedShift) {
      return servizioEsternoCount * rate;
    }

    return usesExternalService ? rate : 0.0;
  }

  double getFestiveAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);
    final rate = _resolvedHolidayAllowance(p);

    if (isLegacyQuantifiedShift) {
      return festivoCount * rate;
    }

    if (isSuperHoliday) return 0.0;
    return isSunday ? rate : 0.0;
  }

  double getSpecialHolidayAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);
    final rate = _resolvedSpecialHolidayAllowance(p);

    if (isLegacyQuantifiedShift) {
      return 0.0;
    }

    return isSuperHoliday ? rate : 0.0;
  }

  double getNightAllowanceAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    if (isLegacyQuantifiedShift) {
      if (notturnoCount <= 0) return 0.0;
      return notturnoCount * fallbackNightAllowance;
    }

    final totalNightHours = TimeBandHelper.calculateNightOnlyHours(
      start,
      _normalizedShiftEnd,
    );

    if (totalNightHours <= 0) return 0.0;

    return totalNightHours * fallbackNightAllowance;
  }

  double getPolferTerritoryControlAmount([UserPayProfile? profile]) {
    if (polferTerritoryControlType == PolferTerritoryControlType.none) {
      return 0.0;
    }

    if (questuraMode == QuesturaMode.volanti) {
      switch (polferTerritoryControlType) {
        case PolferTerritoryControlType.serale:
          return 5.0;
        case PolferTerritoryControlType.notturno:
          return 10.0;
        case PolferTerritoryControlType.none:
          return 0.0;
      }
    }

    switch (polferTerritoryControlType) {
      case PolferTerritoryControlType.serale:
        return 5.00;
      case PolferTerritoryControlType.notturno:
        return 10.00;
      case PolferTerritoryControlType.none:
        return 0.0;
    }
  }

  String get polferTerritoryControlLabel {
    switch (polferTerritoryControlType) {
      case PolferTerritoryControlType.none:
        return 'Nessuno';
      case PolferTerritoryControlType.serale:
        return 'Controllo del territorio serale';
      case PolferTerritoryControlType.notturno:
        return 'Controllo del territorio notturno';
    }
  }

  double getGenereDiConfortoCdgAmount([UserPayProfile? profile]) {
    if (hasAbsence || !genereDiConfortoCdg) return 0.0;
    return _resolvedGenereDiConfortoCdgRate();
  }

  double getGenereDiConfortoAmount([UserPayProfile? profile]) {
    if (hasAbsence || !genereDiConforto) return 0.0;
    final p = _effectiveProfile(profile);
    return _resolvedGenereDiConfortoRate(p);
  }

  double getTicketPastoAmount([UserPayProfile? profile]) {
    if (hasAbsence || !ticketPasto) return 0.0;
    final p = _effectiveProfile(profile);
    return _resolvedTicketPastoRate(p);
  }

  double getMissionAmount() {
    if (hasAbsence || !hasMission) return 0.0;
    if (missionAmount.isNaN || !missionAmount.isFinite || missionAmount <= 0) {
      return 0.0;
    }
    return missionAmount;
  }

  double getManualExtraAmount() {
    if (hasAbsence) return 0.0;

    if (manualExtraAmount > 0) return manualExtraAmount;
    if (manualAmount > 0) return manualAmount;
    return 0.0;
  }

  String get effectiveOrderPublicLabel {
    if (hasAbsence) return 'Nessuno';

    if (isLegacyQuantifiedShift) {
      switch (opServiceType) {
        case OpServiceType.none:
          return 'Nessuno';
        case OpServiceType.inSede:
          return 'In sede';
        case OpServiceType.fuoriSedeOneTurno:
          return 'Fuori sede';
        case OpServiceType.fuoriSedeIntera:
          return 'Pernotto';
      }
    }

    if (usesExternalService) return 'Non applicato';
    return orderPublic;
  }

  String getOvertimeLabel([UserPayProfile? profile]) {
    if (overtimeHours <= 0) return 'Nessuno';

    if (isLegacyQuantifiedShift) {
      final hasNight =
          straordinarioNotturnoFestivoHours > 0 && notturnoCount > 0;
      final hasHoliday =
          straordinarioNotturnoFestivoHours > 0 && festivoCount > 0;

      if (hasNight && hasHoliday) return 'Straordinario notturno festivo';
      if (hasNight) return 'Straordinario notturno';
      if (hasHoliday) return 'Straordinario festivo';
      if (straordinarioDiurnoHours > 0) return 'Straordinario diurno';

      return 'Straordinario';
    }

    final hasDay = segmentedOvertimeDayHours > 0;
    final hasNight = segmentedOvertimeNightHours > 0;
    final hasHolidayDay = segmentedOvertimeHolidayDayHours > 0;
    final hasNightHoliday = segmentedOvertimeNightHolidayHours > 0;

    final categories = [
      if (hasDay) 'diurno',
      if (hasNight) 'notturno',
      if (hasHolidayDay) 'festivo',
      if (hasNightHoliday) 'notturno festivo',
    ];

    if (categories.isEmpty) return 'Straordinario';
    if (categories.length == 1) return 'Straordinario ${categories.first}';
    return 'Straordinario misto';
  }

  String get effectiveManualExtraLabel {
    if (!hasManualExtra) return '';
    if (manualExtraLabel.trim().isNotEmpty) return manualExtraLabel.trim();
    if (note.trim().isNotEmpty) return note.trim();
    return 'Extra manuale';
  }

  bool get hasPolferScalo => polferScaloMode != PolferScaloMode.none;

  double get polferWorkedDayHours {
    if (hasAbsence) return 0.0;
    return TimeBandHelper.calculateBandHours(
      start,
      _normalizedShiftEnd,
      dayBand: true,
    );
  }

  double get polferWorkedNightHours {
    if (hasAbsence) return 0.0;
    return TimeBandHelper.calculateBandHours(
      start,
      _normalizedShiftEnd,
      dayBand: false,
    );
  }

  double get effectivePolferScaloReducedDayHours {
    if (!hasPolferScalo) return 0.0;
    if (polferScaloManualOverride) return polferScaloReducedDayHours;
    return polferScaloMode == PolferScaloMode.ridotta
        ? polferWorkedDayHours
        : 0.0;
  }

  double get effectivePolferScaloReducedNightHours {
    if (!hasPolferScalo) return 0.0;
    if (polferScaloManualOverride) return polferScaloReducedNightHours;
    return polferScaloMode == PolferScaloMode.ridotta
        ? polferWorkedNightHours
        : 0.0;
  }

  double get effectivePolferScaloFullDayHours {
    if (!hasPolferScalo) return 0.0;
    if (polferScaloManualOverride) return polferScaloFullDayHours;
    return polferScaloMode == PolferScaloMode.intera
        ? polferWorkedDayHours
        : 0.0;
  }

  double get effectivePolferScaloFullNightHours {
    if (!hasPolferScalo) return 0.0;
    if (polferScaloManualOverride) return polferScaloFullNightHours;
    return polferScaloMode == PolferScaloMode.intera
        ? polferWorkedNightHours
        : 0.0;
  }

  double get polferScaloAmount {
    if (hasAbsence || !hasPolferScalo) return 0.0;

    return (effectivePolferScaloReducedDayHours * polferScaloReducedDayRate) +
        (effectivePolferScaloReducedNightHours * polferScaloReducedNightRate) +
        (effectivePolferScaloFullDayHours * polferScaloFullDayRate) +
        (effectivePolferScaloFullNightHours * polferScaloFullNightRate);
  }

  double get polferScaloBasketAmount => polferScaloAmount;

  String get polferScaloLabel {
    final hasReduced = effectivePolferScaloReducedDayHours > 0 ||
        effectivePolferScaloReducedNightHours > 0;
    final hasFull = effectivePolferScaloFullDayHours > 0 ||
        effectivePolferScaloFullNightHours > 0;

    if (polferScaloManualOverride && hasReduced && hasFull) {
      return 'Scalo ferroviario misto (basket RFI)';
    }

    if (hasReduced && !hasFull) {
      return polferScaloManualOverride
          ? 'Scalo ferroviario ridotto (manuale • basket RFI)'
          : 'Scalo ferroviario ridotto (basket RFI)';
    }

    if (hasFull && !hasReduced) {
      return polferScaloManualOverride
          ? 'Scalo ferroviario intero (manuale • basket RFI)'
          : 'Scalo ferroviario intero (basket RFI)';
    }

    return 'Scalo ferroviario (basket RFI)';
  }

  List<Map<String, dynamic>> getBreakdown([UserPayProfile? profile]) {
    if (hasAbsence) {
      return [
        {
          'label': 'Assenza dal servizio',
          'amount': 0.0,
        }
      ];
    }

    final items = <Map<String, dynamic>>[];
    final orderPublicAmount = getOrderPublicAmount(profile);
    final festiveAmount = getFestiveAmount(profile);
    final specialHolidayAmount = getSpecialHolidayAmount(profile);
    final externalServiceAmount = getExternalServiceAmount(profile);
    final territoryControlAmount = getPolferTerritoryControlAmount(profile);
    final nightAmount = getNightAllowanceAmount(profile);
    final ordinaryNightShiftAmount = getOrdinaryNightShiftAmount(profile);
    final comfortCdgAmount = getGenereDiConfortoCdgAmount(profile);
    final comfortAmount = getGenereDiConfortoAmount(profile);
    final mealAmount = getTicketPastoAmount(profile);
    final mission = getMissionAmount();
    final manual = getManualExtraAmount();

    if (orderPublicAmount > 0) {
      items.add({
        'label': 'Ordine pubblico $effectiveOrderPublicLabel',
        'amount': orderPublicAmount,
      });
    }

    if (isLegacyQuantifiedShift) {
      final p = _effectiveProfile(profile);
      final dayRate = _resolvedOvertimeDayRate(p);
      final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);

      if (straordinarioDiurnoHours > 0) {
        items.add({
          'label':
              'Straordinario diurno (${straordinarioDiurnoHours.toStringAsFixed(1)}h × €${dayRate.toStringAsFixed(2)} lordi)',
          'amount': straordinarioDiurnoHours * dayRate,
        });
      }

      if (straordinarioNotturnoFestivoHours > 0) {
        items.add({
          'label':
              'Straordinario notturno/festivo (${straordinarioNotturnoFestivoHours.toStringAsFixed(1)}h × €${nightOrHolidayRate.toStringAsFixed(2)} lordi)',
          'amount': straordinarioNotturnoFestivoHours * nightOrHolidayRate,
        });
      }

      if (nightAmount > 0) {
        final totalNightHours = TimeBandHelper.calculateNightOnlyHours(
          start,
          _normalizedShiftEnd,
        );
        final payableNightHours = totalNightHours - overtimeHours;

        items.add({
          'label':
              'Indennità servizio notturno (${payableNightHours.toStringAsFixed(1)}h × €${fallbackNightAllowance.toStringAsFixed(2)} lordi)',
          'amount': nightAmount,
        });
      }

      if (festiveAmount > 0) {
        items.add({
          'label': 'Indennità servizio festivo ($festivoCount)',
          'amount': festiveAmount,
        });
      }

      if (externalServiceAmount > 0) {
        items.add({
          'label': 'Indennità presenza servizi esterni ($servizioEsternoCount)',
          'amount': externalServiceAmount,
        });
      }

      if (territoryControlAmount > 0) {
        items.add({
          'label': polferTerritoryControlLabel,
          'amount': territoryControlAmount,
        });
      }

      if (comfortCdgAmount > 0) {
        items.add(
            {'label': 'Genere di conforto CDG', 'amount': comfortCdgAmount});
      }

      if (comfortAmount > 0) {
        items.add({'label': 'Genere di conforto', 'amount': comfortAmount});
      }

      if (mealAmount > 0) {
        items.add({'label': 'Ticket pasto', 'amount': mealAmount});
      }

      if (mission > 0) {
        items.add({'label': 'Missione', 'amount': mission});
      }

      if (manual > 0) {
        items.add({'label': effectiveManualExtraLabel, 'amount': manual});
      }

      if (polferScaloAmount > 0) {
        items.add({'label': polferScaloLabel, 'amount': polferScaloAmount});
      }

      return items;
    }

    if (overtimeHours > 0) {
      final p = _effectiveProfile(profile);

      final dayHours = segmentedOvertimeDayHours;
      final nightHours = segmentedOvertimeNightHours;
      final holidayDayHours = segmentedOvertimeHolidayDayHours;
      final nightHolidayHours = segmentedOvertimeNightHolidayHours;

      if (nightHolidayHours > 0) {
        final rate = _resolvedOvertimeNightAndHolidayRate(p);
        items.add({
          'label':
              'Straordinario notturno festivo (${nightHolidayHours.toStringAsFixed(1)}h × €${rate.toStringAsFixed(2)} lordi)',
          'amount': nightHolidayHours * rate,
        });
      }

      if (nightHours > 0) {
        final rate = _resolvedOvertimeNightOrHolidayRate(p);
        items.add({
          'label':
              'Straordinario notturno (${nightHours.toStringAsFixed(1)}h × €${rate.toStringAsFixed(2)} lordi)',
          'amount': nightHours * rate,
        });
      }

      if (holidayDayHours > 0) {
        final rate = _resolvedOvertimeNightOrHolidayRate(p);
        items.add({
          'label':
              'Straordinario festivo (${holidayDayHours.toStringAsFixed(1)}h × €${rate.toStringAsFixed(2)} lordi)',
          'amount': holidayDayHours * rate,
        });
      }

      if (dayHours > 0) {
        final rate = _resolvedOvertimeDayRate(p);
        items.add({
          'label':
              'Straordinario diurno (${dayHours.toStringAsFixed(1)}h × €${rate.toStringAsFixed(2)} lordi)',
          'amount': dayHours * rate,
        });
      }
    }

    if (nightAmount > 0) {
      final totalNightHours = TimeBandHelper.calculateNightOnlyHours(
        start,
        _normalizedShiftEnd,
      );
      final payableNightHours = totalNightHours - overtimeHours;

      items.add({
        'label':
            'Indennità servizio notturno (${payableNightHours.toStringAsFixed(1)}h × €${fallbackNightAllowance.toStringAsFixed(2)} lordi)',
        'amount': nightAmount,
      });
    }

    if (festiveAmount > 0) {
      items.add(
          {'label': 'Indennità servizio festivo', 'amount': festiveAmount});
    }

    if (specialHolidayAmount > 0) {
      items.add({
        'label': 'Indennità festività particolare',
        'amount': specialHolidayAmount,
      });
    }

    if (externalServiceAmount > 0) {
      items.add({
        'label': 'Indennità presenza servizi esterni',
        'amount': externalServiceAmount,
      });
    }

    if (territoryControlAmount > 0) {
      items.add({
        'label': polferTerritoryControlLabel,
        'amount': territoryControlAmount
      });
    }

    if (ordinaryNightShiftAmount > 0) {
      items.add({
        'label': 'Indennità turno notturno ordinario',
        'amount': ordinaryNightShiftAmount,
      });
    }

    if (comfortCdgAmount > 0) {
      items
          .add({'label': 'Genere di conforto CDG', 'amount': comfortCdgAmount});
    }

    if (comfortAmount > 0) {
      items.add({'label': 'Genere di conforto', 'amount': comfortAmount});
    }

    if (mealAmount > 0) {
      items.add({'label': 'Ticket pasto', 'amount': mealAmount});
    }

    if (mission > 0) {
      items.add({'label': 'Missione', 'amount': mission});
    }

    if (manual > 0) {
      items.add({'label': effectiveManualExtraLabel, 'amount': manual});
    }

    if (polferScaloAmount > 0) {
      items.add({'label': polferScaloLabel, 'amount': polferScaloAmount});
    }

    return items;
  }

  double getTotalAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    return getBreakdown(profile).fold(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  List<Map<String, dynamic>> getSalaryBreakdown([UserPayProfile? profile]) {
    final fullBreakdown = getBreakdown(profile);

    return fullBreakdown.where((item) {
      final label = (item['label'] as String? ?? '').trim().toLowerCase();

      if (label == 'ticket pasto') return false;
      if (label.contains('basket rfi')) return false;

      return true;
    }).toList();
  }

  double getRfiBasketAmount([UserPayProfile? profile]) {
    return polferScaloBasketAmount;
  }

  List<Map<String, dynamic>> getRfiBasketBreakdown([UserPayProfile? profile]) {
    if (hasAbsence || polferScaloBasketAmount <= 0) return const [];
    return [
      {
        'label': polferScaloLabel,
        'amount': polferScaloBasketAmount,
      }
    ];
  }

  double getWelfareAmount([UserPayProfile? profile]) {
    return getGenereDiConfortoCdgAmount(profile) +
        getGenereDiConfortoAmount(profile) +
        getTicketPastoAmount(profile);
  }

  double getTicketAmount([UserPayProfile? profile]) {
    return getTicketPastoAmount(profile);
  }

  double getComfortCdgAmount([UserPayProfile? profile]) {
    return getGenereDiConfortoCdgAmount(profile);
  }

  double getComfortAmount([UserPayProfile? profile]) {
    return getGenereDiConfortoAmount(profile);
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'serviceDate': serviceDate.toIso8601String(),
      'orderPublic': orderPublic,
      'externalService': externalService,
      'absence': absence,
      'manualExtraAmount': manualExtraAmount,
      'manualExtraLabel': manualExtraLabel,
      'hasMission': hasMission,
      'missionAmount': missionAmount,
      'genereDiConfortoCdg': genereDiConfortoCdg,
      'genereDiConforto': genereDiConforto,
      'ticketPasto': ticketPasto,
      'hasCompensazione': hasCompensazione,
      'hasReperibilita': hasReperibilita,
      'hasAutostradaService': hasAutostradaService,
      'straordinarioDiurnoHours': straordinarioDiurnoHours,
      'straordinarioNotturnoFestivoHours': straordinarioNotturnoFestivoHours,
      'notturnoCount': notturnoCount,
      'festivoCount': festivoCount,
      'servizioEsternoCount': servizioEsternoCount,
      'opServiceType': opServiceType.name,
      'manualAmount': manualAmount,
      'note': note,
      'spmnPresetCode': spmnPresetCode,
      'questuraMode': questuraMode.name,
      'questuraPreset': questuraPreset.name,
      'questuraOfficeProfile': questuraOfficeProfile.name,
      'questuraOfficeOrdinaryHours': questuraOfficeOrdinaryHours,
      'workedHours': workedHoursOverride,
      'polferTerritoryControlType': polferTerritoryControlType.name,
      'polferScaloMode': polferScaloMode.name,
      'polferScaloManualOverride': polferScaloManualOverride,
      'polferScaloReducedDayHours': polferScaloReducedDayHours,
      'polferScaloReducedNightHours': polferScaloReducedNightHours,
      'polferScaloFullDayHours': polferScaloFullDayHours,
      'polferScaloFullNightHours': polferScaloFullNightHours,
      'overtimeDestination': overtimeDestination.name,
      'compensativeOvertimeHours': compensativeOvertimeHours,
      'compensativeOvertimeNote': compensativeOvertimeNote,
      'compensativeRecoveryHours': compensativeRecoveryHours,
      'programmedOvertimeEnabled': programmedOvertimeEnabled,
      'programmedOvertimeStart': programmedOvertimeStart?.toIso8601String(),
      'programmedOvertimeEnd': programmedOvertimeEnd?.toIso8601String(),
      'programmedOvertimeNote': programmedOvertimeNote,
      'ordinaryHoursOverrideEnabled': ordinaryHoursOverrideEnabled,
      'ordinaryHoursOverride': ordinaryHoursOverride,
      'ordinaryHoursOverrideNote': ordinaryHoursOverrideNote,
    };
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    final parsedStart = json['start'] != null
        ? DateTime.parse(json['start'] as String)
        : (json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now());

    final parsedWorkedHours = _toDoubleNullable(json['workedHours']);
    final parsedEnd = json['end'] != null
        ? DateTime.parse(json['end'] as String)
        : parsedStart.add(
            Duration(
              minutes: (((parsedWorkedHours ?? standardHours)) * 60).round(),
            ),
          );

    final parsedServiceDate = json['serviceDate'] != null
        ? _normalizeDate(DateTime.parse(json['serviceDate'] as String))
        : _normalizeDate(
            _deriveServiceDate(
              parsedStart,
              parsedEnd,
              spmnPresetCode: json['spmnPresetCode'] as String? ?? '',
              questuraPreset: _parseQuesturaPreset(
                json['questuraPreset']?.toString(),
              ),
            ),
          );

    return Shift._internal(
      description: json['description'] as String? ?? '',
      start: parsedStart,
      end: parsedEnd,
      serviceDate: parsedServiceDate,
      orderPublic: json['orderPublic'] as String? ??
          _normalizeOrderPublic(
            orderPublic: null,
            opServiceType: _parseOpServiceType(
              json['opServiceType']?.toString(),
            ),
          ),
      externalService: json['externalService'] as bool? ??
          (_toInt(json['servizioEsternoCount']) > 0),
      absence: json['absence'] as String? ?? 'Nessuna',
      manualExtraAmount: _toDouble(json['manualExtraAmount']),
      manualExtraLabel: json['manualExtraLabel'] as String? ?? '',
      hasMission: json['hasMission'] as bool? ?? false,
      missionAmount: _toDouble(json['missionAmount']),
      genereDiConfortoCdg: json['genereDiConfortoCdg'] as bool? ?? false,
      genereDiConforto: json['genereDiConforto'] as bool? ?? false,
      ticketPasto: json['ticketPasto'] as bool? ?? false,
      hasCompensazione: json['hasCompensazione'] as bool? ?? false,
      hasReperibilita: json['hasReperibilita'] as bool? ?? false,
      hasAutostradaService: json['hasAutostradaService'] as bool? ?? false,
      straordinarioDiurnoHours: _toDouble(json['straordinarioDiurnoHours']),
      straordinarioNotturnoFestivoHours:
          _toDouble(json['straordinarioNotturnoFestivoHours']),
      notturnoCount: _toInt(json['notturnoCount']),
      festivoCount: _toInt(json['festivoCount']),
      servizioEsternoCount: _toInt(json['servizioEsternoCount']),
      opServiceType: _parseOpServiceType(json['opServiceType']?.toString()),
      manualAmount: _toDouble(json['manualAmount']),
      note: json['note']?.toString() ?? '',
      spmnPresetCode: json['spmnPresetCode'] as String? ?? '',
      questuraMode: _parseQuesturaMode(json['questuraMode']?.toString()),
      questuraPreset: _parseQuesturaPreset(json['questuraPreset']?.toString()),
      questuraOfficeProfile: _parseQuesturaOfficeProfile(
        json['questuraOfficeProfile']?.toString(),
      ),
      questuraOfficeOrdinaryHours:
          _toDoubleNullable(json['questuraOfficeOrdinaryHours']) ?? 6.0,
      workedHoursOverride: parsedWorkedHours,
      polferTerritoryControlType: _parsePolferTerritoryControlType(
        json['polferTerritoryControlType']?.toString(),
      ),
      polferScaloMode: _parsePolferScaloMode(
        json['polferScaloMode']?.toString(),
      ),
      polferScaloManualOverride:
          json['polferScaloManualOverride'] as bool? ?? false,
      polferScaloReducedDayHours: _toDouble(json['polferScaloReducedDayHours']),
      polferScaloReducedNightHours:
          _toDouble(json['polferScaloReducedNightHours']),
      polferScaloFullDayHours: _toDouble(json['polferScaloFullDayHours']),
      polferScaloFullNightHours: _toDouble(json['polferScaloFullNightHours']),
      overtimeDestination: _parseOvertimeDestination(
        json['overtimeDestination']?.toString(),
      ),
      compensativeOvertimeHours: _toDouble(json['compensativeOvertimeHours']),
      compensativeOvertimeNote:
          json['compensativeOvertimeNote']?.toString() ?? '',
      compensativeRecoveryHours: _toDouble(json['compensativeRecoveryHours']),
      programmedOvertimeEnabled:
          json['programmedOvertimeEnabled'] as bool? ?? false,
      programmedOvertimeStart: json['programmedOvertimeStart'] != null
          ? DateTime.parse(json['programmedOvertimeStart'] as String)
          : null,
      programmedOvertimeEnd: json['programmedOvertimeEnd'] != null
          ? DateTime.parse(json['programmedOvertimeEnd'] as String)
          : null,
      programmedOvertimeNote: json['programmedOvertimeNote']?.toString() ?? '',
      ordinaryHoursOverrideEnabled:
          json['ordinaryHoursOverrideEnabled'] as bool? ?? false,
      ordinaryHoursOverride: _toDouble(json['ordinaryHoursOverride']),
      ordinaryHoursOverrideNote:
          json['ordinaryHoursOverrideNote']?.toString() ?? '',
    );
  }

  static String _normalizeOrderPublic({
    required String? orderPublic,
    required OpServiceType opServiceType,
  }) {
    if (orderPublic != null && orderPublic.trim().isNotEmpty) {
      return orderPublic;
    }

    switch (opServiceType) {
      case OpServiceType.none:
        return 'Nessuno';
      case OpServiceType.inSede:
        return 'In sede';
      case OpServiceType.fuoriSedeOneTurno:
        return 'Fuori sede';
      case OpServiceType.fuoriSedeIntera:
        return 'Pernotto';
    }
  }

  static DateTime _deriveServiceDate(
    DateTime start,
    DateTime end, {
    String spmnPresetCode = '',
    QuesturaPreset questuraPreset = QuesturaPreset.none,
  }) {
    final normalizedStart = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);

    final normalizedPreset = spmnPresetCode.trim().toLowerCase();
    final isNightPreset =
        normalizedPreset == 'notte' || questuraPreset == QuesturaPreset.notte;

    if (isNightPreset && normalizedEnd.isAfter(normalizedStart)) {
      return normalizedEnd;
    }

    final isNightShift =
        start.hour >= 22 && normalizedEnd.isAfter(normalizedStart);

    if (isNightShift) {
      return normalizedEnd;
    }

    return normalizedStart;
  }

  static OvertimeDestination _parseOvertimeDestination(String? value) {
    switch (value) {
      case 'compensative':
        return OvertimeDestination.compensative;
      case 'payment':
      default:
        return OvertimeDestination.payment;
    }
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static OpServiceType _parseOpServiceType(String? value) {
    switch (value) {
      case 'inSede':
        return OpServiceType.inSede;
      case 'fuoriSedeOneTurno':
        return OpServiceType.fuoriSedeOneTurno;
      case 'fuoriSedeIntera':
        return OpServiceType.fuoriSedeIntera;
      default:
        return OpServiceType.none;
    }
  }

  static QuesturaMode _parseQuesturaMode(String? value) {
    return QuesturaMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuesturaMode.uffici,
    );
  }

  static QuesturaPreset _parseQuesturaPreset(String? value) {
    return QuesturaPreset.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuesturaPreset.none,
    );
  }

  static QuesturaOfficeProfile _parseQuesturaOfficeProfile(String? value) {
    return QuesturaOfficeProfile.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuesturaOfficeProfile.sixHours,
    );
  }

  static PolferTerritoryControlType _parsePolferTerritoryControlType(
    String? value,
  ) {
    switch (value) {
      case 'serale':
        return PolferTerritoryControlType.serale;
      case 'notturno':
        return PolferTerritoryControlType.notturno;
      default:
        return PolferTerritoryControlType.none;
    }
  }

  static PolferScaloMode _parsePolferScaloMode(String? value) {
    switch (value) {
      case 'ridotta':
        return PolferScaloMode.ridotta;
      case 'intera':
        return PolferScaloMode.intera;
      default:
        return PolferScaloMode.none;
    }
  }
}
