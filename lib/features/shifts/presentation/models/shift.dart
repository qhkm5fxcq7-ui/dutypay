import 'user_pay_profile.dart';

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

class Shift {
  final String description;
  final DateTime start;
  final DateTime end;

  /// Giorno operativo/di competenza da usare per calendario, conteggi e filtri.
  final DateTime serviceDate;

  final String orderPublic;
  final bool externalService;
  final String absence;

  final double manualExtraAmount;
  final String manualExtraLabel;

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

  final String spmnPresetCode;

  final double? workedHoursOverride;

  // ===== POLFER =====
  final PolferTerritoryControlType polferTerritoryControlType;

  /// Modalità principale dello scalo:
  /// - none
  /// - ridotta
  /// - intera
  final PolferScaloMode polferScaloMode;

  /// Se false, il sistema calcola automaticamente le ore giorno/notte
  /// in base alle ore effettive del turno e le attribuisce tutte alla
  /// modalità scelta (ridotta o intera).
  ///
  /// Se true, usa i 4 campi manuali sottostanti.
  final bool polferScaloManualOverride;

  final double polferScaloReducedDayHours;
  final double polferScaloReducedNightHours;
  final double polferScaloFullDayHours;
  final double polferScaloFullNightHours;

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
    bool genereDiConforto = false,
    bool ticketPasto = false,
    DateTime? date,
    double? workedHours,
    double straordinarioDiurnoHours = 0.0,
    double straordinarioNotturnoFestivoHours = 0.0,
    int notturnoCount = 0,
    int festivoCount = 0,
    int servizioEsternoCount = 0,
    OpServiceType opServiceType = OpServiceType.none,
    double manualAmount = 0.0,
    String note = '',
    String spmnPresetCode = '',
    PolferTerritoryControlType polferTerritoryControlType =
        PolferTerritoryControlType.none,
    PolferScaloMode polferScaloMode = PolferScaloMode.none,
    bool polferScaloManualOverride = false,
    double polferScaloReducedDayHours = 0.0,
    double polferScaloReducedNightHours = 0.0,
    double polferScaloFullDayHours = 0.0,
    double polferScaloFullNightHours = 0.0,
  }) {
    final resolvedStart = start ?? date ?? DateTime.now();
    final resolvedWorkedHours = workedHours ?? standardHours;
    final resolvedEnd = end ??
        resolvedStart.add(
          Duration(minutes: (resolvedWorkedHours * 60).round()),
        );

    final resolvedServiceDate = _normalizeDate(
      serviceDate ?? _deriveServiceDate(resolvedStart, resolvedEnd),
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
      genereDiConforto: genereDiConforto,
      ticketPasto: ticketPasto,
      straordinarioDiurnoHours: straordinarioDiurnoHours,
      straordinarioNotturnoFestivoHours: straordinarioNotturnoFestivoHours,
      notturnoCount: notturnoCount,
      festivoCount: festivoCount,
      servizioEsternoCount: servizioEsternoCount,
      opServiceType: opServiceType,
      manualAmount: manualAmount,
      note: note,
      spmnPresetCode: spmnPresetCode,
      workedHoursOverride: workedHours,
      polferTerritoryControlType: polferTerritoryControlType,
      polferScaloMode: polferScaloMode,
      polferScaloManualOverride: polferScaloManualOverride,
      polferScaloReducedDayHours: polferScaloReducedDayHours,
      polferScaloReducedNightHours: polferScaloReducedNightHours,
      polferScaloFullDayHours: polferScaloFullDayHours,
      polferScaloFullNightHours: polferScaloFullNightHours,
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
    required this.genereDiConforto,
    required this.ticketPasto,
    required this.straordinarioDiurnoHours,
    required this.straordinarioNotturnoFestivoHours,
    required this.notturnoCount,
    required this.festivoCount,
    required this.servizioEsternoCount,
    required this.opServiceType,
    required this.manualAmount,
    required this.note,
    required this.spmnPresetCode,
    required this.workedHoursOverride,
    required this.polferTerritoryControlType,
    required this.polferScaloMode,
    required this.polferScaloManualOverride,
    required this.polferScaloReducedDayHours,
    required this.polferScaloReducedNightHours,
    required this.polferScaloFullDayHours,
    required this.polferScaloFullNightHours,
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
    bool? genereDiConforto,
    bool? ticketPasto,
    double? straordinarioDiurnoHours,
    double? straordinarioNotturnoFestivoHours,
    int? notturnoCount,
    int? festivoCount,
    int? servizioEsternoCount,
    OpServiceType? opServiceType,
    double? manualAmount,
    String? note,
    String? spmnPresetCode,
    double? workedHoursOverride,
    PolferTerritoryControlType? polferTerritoryControlType,
    PolferScaloMode? polferScaloMode,
    bool? polferScaloManualOverride,
    double? polferScaloReducedDayHours,
    double? polferScaloReducedNightHours,
    double? polferScaloFullDayHours,
    double? polferScaloFullNightHours,
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
      genereDiConforto: genereDiConforto ?? this.genereDiConforto,
      ticketPasto: ticketPasto ?? this.ticketPasto,
      straordinarioDiurnoHours:
          straordinarioDiurnoHours ?? this.straordinarioDiurnoHours,
      straordinarioNotturnoFestivoHours:
          straordinarioNotturnoFestivoHours ??
              this.straordinarioNotturnoFestivoHours,
      notturnoCount: notturnoCount ?? this.notturnoCount,
      festivoCount: festivoCount ?? this.festivoCount,
      servizioEsternoCount:
          servizioEsternoCount ?? this.servizioEsternoCount,
      opServiceType: opServiceType ?? this.opServiceType,
      manualAmount: manualAmount ?? this.manualAmount,
      note: note ?? this.note,
      spmnPresetCode: spmnPresetCode ?? this.spmnPresetCode,
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
    );
  }

  DateTime get date => serviceDate;

  double get hours {
    final diffMinutes = end.difference(start).inMinutes;
    return diffMinutes > 0 ? diffMinutes / 60.0 : 0.0;
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
    return _matchesAnyDate(
      serviceDate,
      _superHolidayDates(serviceDate.year),
    );
  }

  bool get isHoliday => isSunday || isSuperHoliday;

  double get overtimeHours {
    if (hasAbsence) return 0.0;

    final legacyTotal =
        straordinarioDiurnoHours + straordinarioNotturnoFestivoHours;
    if (legacyTotal > 0) return legacyTotal;

    final extra = workedHours - standardHours;
    return extra > 0 ? extra : 0.0;
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

  double _resolvedTerritorySeraleRate(UserPayProfile p) {
    return _sanitizeRate(
      p.controlloTerritorioSerale,
      fallbackPolferTerritorySeraleRate,
    );
  }

  double _resolvedTerritoryNotturnoRate(UserPayProfile p) {
    return _sanitizeRate(
      p.controlloTerritorioNotturno,
      fallbackPolferTerritoryNotturnoRate,
    );
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

  double getOvertimeRate([UserPayProfile? profile]) {
    final p = _effectiveProfile(profile);

    final dayRate = _resolvedOvertimeDayRate(p);
    final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);
    final nightAndHolidayRate = _resolvedOvertimeNightAndHolidayRate(p);

    if (touchesNightBand && isHoliday) {
      return nightAndHolidayRate;
    }
    if (touchesNightBand || isHoliday) {
      return nightOrHolidayRate;
    }
    return dayRate;
  }

  double getOvertimeAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;

    final p = _effectiveProfile(profile);
    final multiplier = _resolvedOvertimeNetMultiplier(p);

    if (isLegacyQuantifiedShift) {
      final dayRate = _resolvedOvertimeDayRate(p);
      final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);

      final diurnoLordo = straordinarioDiurnoHours * dayRate;
      final nottFestLordo =
          straordinarioNotturnoFestivoHours * nightOrHolidayRate;

      return (diurnoLordo + nottFestLordo) * multiplier;
    }

    final overtimeRate = getOvertimeRate(profile);
    final lordo = overtimeHours * overtimeRate;

    return lordo * multiplier;
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

    if (notturnoCount <= 0) return 0.0;
    return notturnoCount * fallbackNightAllowance;
  }

  double getPolferTerritoryControlAmount([UserPayProfile? profile]) {
    if (hasAbsence) return 0.0;
    if (polferTerritoryControlType == PolferTerritoryControlType.none) {
      return 0.0;
    }

    final p = _effectiveProfile(profile);

    switch (polferTerritoryControlType) {
      case PolferTerritoryControlType.none:
        return 0.0;
      case PolferTerritoryControlType.serale:
        return _resolvedTerritorySeraleRate(p);
      case PolferTerritoryControlType.notturno:
        return _resolvedTerritoryNotturnoRate(p);
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
      if (straordinarioNotturnoFestivoHours > 0 &&
          straordinarioDiurnoHours == 0) {
        return 'Straordinario notturno/festivo';
      }
      if (straordinarioNotturnoFestivoHours > 0 &&
          straordinarioDiurnoHours > 0) {
        return 'Straordinario misto';
      }
      return 'Straordinario diurno';
    }

    if (touchesNightBand && isHoliday) {
      return 'Straordinario notturno e festivo';
    }
    if (touchesNightBand || isHoliday) {
      return 'Straordinario notturno o festivo';
    }
    return 'Straordinario diurno';
  }

  String get effectiveManualExtraLabel {
    if (!hasManualExtra) return '';
    if (manualExtraLabel.trim().isNotEmpty) return manualExtraLabel.trim();
    if (note.trim().isNotEmpty) return note.trim();
    return 'Extra manuale';
  }

  // ===== POLFER SCALO / BASKET RFI =====

  bool get hasPolferScalo => polferScaloMode != PolferScaloMode.none;

  double get polferWorkedDayHours {
    if (hasAbsence) return 0.0;
    return _calculateBandHours(start, end, dayBand: true);
  }

  double get polferWorkedNightHours {
    if (hasAbsence) return 0.0;
    return _calculateBandHours(start, end, dayBand: false);
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

  /// Lo scalo RFI/Trenitalia va fuori dalle accessorie T2
  /// e viene gestito come basket separato.
  double get polferScaloBasketAmount => polferScaloAmount;

  String get polferScaloLabel {
    final hasReduced =
        effectivePolferScaloReducedDayHours > 0 ||
            effectivePolferScaloReducedNightHours > 0;
    final hasFull =
        effectivePolferScaloFullDayHours > 0 ||
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
    final overtimeAmount = getOvertimeAmount(profile);
    final orderPublicAmount = getOrderPublicAmount(profile);
    final festiveAmount = getFestiveAmount(profile);
    final specialHolidayAmount = getSpecialHolidayAmount(profile);
    final externalServiceAmount = getExternalServiceAmount(profile);
    final territoryControlAmount = getPolferTerritoryControlAmount(profile);
    final nightAmount = getNightAllowanceAmount(profile);
    final comfortAmount = getGenereDiConfortoAmount(profile);
    final mealAmount = getTicketPastoAmount(profile);
    final manual = getManualExtraAmount();

    if (orderPublicAmount > 0) {
      items.add({
        'label': 'Ordine pubblico $effectiveOrderPublicLabel',
        'amount': orderPublicAmount,
      });
    }

    if (isLegacyQuantifiedShift) {
      final p = _effectiveProfile(profile);
      final multiplier = _resolvedOvertimeNetMultiplier(p);
      final dayRate = _resolvedOvertimeDayRate(p);
      final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);

      if (straordinarioDiurnoHours > 0) {
        final nettoRate = dayRate * multiplier;
        items.add({
          'label':
              'Straordinario diurno (${straordinarioDiurnoHours.toStringAsFixed(1)}h × €${nettoRate.toStringAsFixed(2)})',
          'amount': straordinarioDiurnoHours * nettoRate,
        });
      }

      if (straordinarioNotturnoFestivoHours > 0) {
        final nettoRate = nightOrHolidayRate * multiplier;
        items.add({
          'label':
              'Straordinario notturno/festivo (${straordinarioNotturnoFestivoHours.toStringAsFixed(1)}h × €${nettoRate.toStringAsFixed(2)})',
          'amount': straordinarioNotturnoFestivoHours * nettoRate,
        });
      }

      if (nightAmount > 0) {
        items.add({
          'label': 'Indennità servizio notturno ($notturnoCount)',
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

      if (comfortAmount > 0) {
        items.add({
          'label': 'Genere di conforto',
          'amount': comfortAmount,
        });
      }

      if (mealAmount > 0) {
        items.add({
          'label': 'Ticket pasto',
          'amount': mealAmount,
        });
      }

      if (manual > 0) {
        items.add({
          'label': effectiveManualExtraLabel,
          'amount': manual,
        });
      }

      if (polferScaloAmount > 0) {
        items.add({
          'label': polferScaloLabel,
          'amount': polferScaloAmount,
        });
      }

      return items;
    }

    if (overtimeHours > 0) {
      final p = _effectiveProfile(profile);
      final overtimeRate = getOvertimeRate(profile);
      final nettoRate = overtimeRate * _resolvedOvertimeNetMultiplier(p);

      items.add({
        'label':
            '${getOvertimeLabel(profile)} (${overtimeHours.toStringAsFixed(1)}h × €${nettoRate.toStringAsFixed(2)})',
        'amount': overtimeAmount,
      });
    }

    if (nightAmount > 0) {
      items.add({
        'label': 'Indennità servizio notturno',
        'amount': nightAmount,
      });
    }

    if (festiveAmount > 0) {
      items.add({
        'label': 'Indennità servizio festivo',
        'amount': festiveAmount,
      });
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
        'amount': territoryControlAmount,
      });
    }

    if (comfortAmount > 0) {
      items.add({
        'label': 'Genere di conforto',
        'amount': comfortAmount,
      });
    }

    if (mealAmount > 0) {
      items.add({
        'label': 'Ticket pasto',
        'amount': mealAmount,
      });
    }

    if (manual > 0) {
      items.add({
        'label': effectiveManualExtraLabel,
        'amount': manual,
      });
    }

    if (polferScaloAmount > 0) {
      items.add({
        'label': polferScaloLabel,
        'amount': polferScaloAmount,
      });
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

      if (label == 'genere di conforto') return false;
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
    return getGenereDiConfortoAmount(profile) + getTicketPastoAmount(profile);
  }

  double getTicketAmount([UserPayProfile? profile]) {
    return getTicketPastoAmount(profile);
  }

  double getComfortAmount([UserPayProfile? profile]) {
    return getGenereDiConfortoAmount(profile);
  }

  double get overtimeRate => getOvertimeRate();
  double get overtimeAmount => getOvertimeAmount();
  double get orderPublicAmount => getOrderPublicAmount();
  double get externalServiceAmount => getExternalServiceAmount();
  double get territoryControlAmount => getPolferTerritoryControlAmount();
  double get festiveAmount => getFestiveAmount();
  double get specialHolidayAmount => getSpecialHolidayAmount();
  double get extraManualAmount => getManualExtraAmount();
  List<Map<String, dynamic>> get breakdown => getBreakdown();
  double get totalAmount => getTotalAmount();
  double get turnAmount => totalAmount;

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
      'genereDiConforto': genereDiConforto,
      'ticketPasto': ticketPasto,
      'straordinarioDiurnoHours': straordinarioDiurnoHours,
      'straordinarioNotturnoFestivoHours': straordinarioNotturnoFestivoHours,
      'notturnoCount': notturnoCount,
      'festivoCount': festivoCount,
      'servizioEsternoCount': servizioEsternoCount,
      'opServiceType': opServiceType.name,
      'manualAmount': manualAmount,
      'note': note,
      'spmnPresetCode': spmnPresetCode,
      'workedHours': workedHoursOverride,
      'polferTerritoryControlType': polferTerritoryControlType.name,
      'polferScaloMode': polferScaloMode.name,
      'polferScaloManualOverride': polferScaloManualOverride,
      'polferScaloReducedDayHours': polferScaloReducedDayHours,
      'polferScaloReducedNightHours': polferScaloReducedNightHours,
      'polferScaloFullDayHours': polferScaloFullDayHours,
      'polferScaloFullNightHours': polferScaloFullNightHours,
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
        : _normalizeDate(_deriveServiceDate(parsedStart, parsedEnd));

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
      genereDiConforto: json['genereDiConforto'] as bool? ?? false,
      ticketPasto: json['ticketPasto'] as bool? ?? false,
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
      workedHoursOverride: parsedWorkedHours,
      polferTerritoryControlType: _parsePolferTerritoryControlType(
        json['polferTerritoryControlType']?.toString(),
      ),
      polferScaloMode: _parsePolferScaloMode(
        json['polferScaloMode']?.toString(),
      ),
      polferScaloManualOverride:
          json['polferScaloManualOverride'] as bool? ?? false,
      polferScaloReducedDayHours:
          _toDouble(json['polferScaloReducedDayHours']),
      polferScaloReducedNightHours:
          _toDouble(json['polferScaloReducedNightHours']),
      polferScaloFullDayHours: _toDouble(json['polferScaloFullDayHours']),
      polferScaloFullNightHours:
          _toDouble(json['polferScaloFullNightHours']),
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

  static DateTime _deriveServiceDate(DateTime start, DateTime end) {
    final normalizedStart = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);

    final isNightShift =
        start.hour >= 22 && normalizedEnd.isAfter(normalizedStart);

    if (isNightShift) {
      return normalizedEnd;
    }

    return normalizedStart;
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

  static double _calculateBandHours(
    DateTime rangeStart,
    DateTime rangeEnd, {
    required bool dayBand,
  }) {
    if (!rangeEnd.isAfter(rangeStart)) return 0.0;

    double totalMinutes = 0.0;
    var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final lastDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    while (!cursor.isAfter(lastDay)) {
      final dayStart = DateTime(cursor.year, cursor.month, cursor.day, 6, 0);
      final dayEnd = DateTime(cursor.year, cursor.month, cursor.day, 22, 0);

      if (dayBand) {
        totalMinutes += _overlapMinutes(rangeStart, rangeEnd, dayStart, dayEnd);
      } else {
        final nightPart1Start =
            DateTime(cursor.year, cursor.month, cursor.day, 0, 0);
        final nightPart1End =
            DateTime(cursor.year, cursor.month, cursor.day, 6, 0);

        final nightPart2Start =
            DateTime(cursor.year, cursor.month, cursor.day, 22, 0);
        final nightPart2End = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
        ).add(const Duration(days: 1));

        totalMinutes += _overlapMinutes(
          rangeStart,
          rangeEnd,
          nightPart1Start,
          nightPart1End,
        );
        totalMinutes += _overlapMinutes(
          rangeStart,
          rangeEnd,
          nightPart2Start,
          nightPart2End,
        );
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return totalMinutes / 60.0;
  }

  static double _overlapMinutes(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    if (!end.isAfter(start)) return 0.0;
    return end.difference(start).inMinutes.toDouble();
  }

  static bool _matchesAnyDate(DateTime date, List<DateTime> dates) {
    return dates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  static List<DateTime> _superHolidayDates(int year) {
    final easter = _calculateEasterSunday(year);
    final easterMonday = easter.add(const Duration(days: 1));

    return [
      DateTime(year, 1, 1),
      DateTime(year, 1, 6),
      easter,
      easterMonday,
      DateTime(year, 5, 1),
      DateTime(year, 6, 2),
      DateTime(year, 8, 15),
      DateTime(year, 12, 25),
      DateTime(year, 12, 26),
    ];
  }

  static DateTime _calculateEasterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }
}