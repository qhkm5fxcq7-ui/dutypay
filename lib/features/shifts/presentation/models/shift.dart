import 'user_pay_profile.dart';

enum OpServiceType {
  none,
  inSede,
  fuoriSedeOneTurno,
  fuoriSedeIntera,
}

class Shift {
  final String description;
  final DateTime start;
  final DateTime end;

  final String orderPublic;
  final bool externalService;
  final String absence;

  final double manualExtraAmount;
  final String manualExtraLabel;

  final double straordinarioDiurnoHours;
  final double straordinarioNotturnoFestivoHours;
  final int notturnoCount;
  final int festivoCount;
  final int servizioEsternoCount;
  final OpServiceType opServiceType;
  final double manualAmount;
  final String note;
  final double? workedHoursOverride;

  static const double standardHours = 6.0;

  // Fallback reali osservati dai cedolini
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

  factory Shift({
    String description = '',
    DateTime? start,
    DateTime? end,
    String orderPublic = 'Nessuno',
    bool externalService = false,
    String absence = 'Nessuna',
    double manualExtraAmount = 0.0,
    String manualExtraLabel = '',
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
  }) {
    final resolvedStart = start ?? date ?? DateTime.now();
    final resolvedWorkedHours = workedHours ?? standardHours;
    final resolvedEnd = end ??
        resolvedStart.add(
          Duration(minutes: (resolvedWorkedHours * 60).round()),
        );

    final resolvedOrderPublic = _normalizeOrderPublic(
      orderPublic: orderPublic,
      opServiceType: opServiceType,
    );

    final resolvedExternalService =
        externalService || servizioEsternoCount > 0;

    final resolvedManualExtraAmount =
        manualExtraAmount > 0 ? manualExtraAmount : manualAmount;

    final resolvedManualExtraLabel =
        manualExtraLabel.trim().isNotEmpty ? manualExtraLabel : note;

    return Shift._internal(
      description: description,
      start: resolvedStart,
      end: resolvedEnd,
      orderPublic: resolvedOrderPublic,
      externalService: resolvedExternalService,
      absence: absence,
      manualExtraAmount: resolvedManualExtraAmount,
      manualExtraLabel: resolvedManualExtraLabel,
      straordinarioDiurnoHours: straordinarioDiurnoHours,
      straordinarioNotturnoFestivoHours: straordinarioNotturnoFestivoHours,
      notturnoCount: notturnoCount,
      festivoCount: festivoCount,
      servizioEsternoCount: servizioEsternoCount,
      opServiceType: opServiceType,
      manualAmount: manualAmount,
      note: note,
      workedHoursOverride: workedHours,
    );
  }

  const Shift._internal({
    required this.description,
    required this.start,
    required this.end,
    required this.orderPublic,
    required this.externalService,
    required this.absence,
    required this.manualExtraAmount,
    required this.manualExtraLabel,
    required this.straordinarioDiurnoHours,
    required this.straordinarioNotturnoFestivoHours,
    required this.notturnoCount,
    required this.festivoCount,
    required this.servizioEsternoCount,
    required this.opServiceType,
    required this.manualAmount,
    required this.note,
    required this.workedHoursOverride,
  });

  Shift copyWith({
    String? description,
    DateTime? start,
    DateTime? end,
    String? orderPublic,
    bool? externalService,
    String? absence,
    double? manualExtraAmount,
    String? manualExtraLabel,
    double? straordinarioDiurnoHours,
    double? straordinarioNotturnoFestivoHours,
    int? notturnoCount,
    int? festivoCount,
    int? servizioEsternoCount,
    OpServiceType? opServiceType,
    double? manualAmount,
    String? note,
    double? workedHoursOverride,
  }) {
    return Shift._internal(
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      orderPublic: orderPublic ?? this.orderPublic,
      externalService: externalService ?? this.externalService,
      absence: absence ?? this.absence,
      manualExtraAmount: manualExtraAmount ?? this.manualExtraAmount,
      manualExtraLabel: manualExtraLabel ?? this.manualExtraLabel,
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
      workedHoursOverride: workedHoursOverride ?? this.workedHoursOverride,
    );
  }

  DateTime get date => start;

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

  bool get isSunday => start.weekday == DateTime.sunday;

  bool get isSuperHoliday {
    return _matchesAnyDate(
      start,
      _superHolidayDates(start.year),
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
    final raw = _sanitizeRate(
      p.orderPublicInSede,
      fallbackOrderPublicInSede,
    );
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
    final raw = _sanitizeRate(
      p.externalServiceRate,
      fallbackExternalServiceRate,
    );
    return raw;
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
    final dayRate = _resolvedOvertimeDayRate(p);
    final nightOrHolidayRate = _resolvedOvertimeNightOrHolidayRate(p);

    if (isLegacyQuantifiedShift) {
      final diurno = straordinarioDiurnoHours * dayRate;
      final nottFest =
          straordinarioNotturnoFestivoHours * nightOrHolidayRate;
      return diurno + nottFest;
    }

    return overtimeHours * getOvertimeRate(profile);
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

    final overtimeRate = getOvertimeRate(profile);
    final overtimeAmount = getOvertimeAmount(profile);
    final orderPublicAmount = getOrderPublicAmount(profile);
    final festiveAmount = getFestiveAmount(profile);
    final specialHolidayAmount = getSpecialHolidayAmount(profile);
    final externalServiceAmount = getExternalServiceAmount(profile);
    final nightAmount = getNightAllowanceAmount(profile);
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
              'Straordinario diurno (${straordinarioDiurnoHours.toStringAsFixed(1)}h × €${dayRate.toStringAsFixed(2)})',
          'amount': straordinarioDiurnoHours * dayRate,
        });
      }

      if (straordinarioNotturnoFestivoHours > 0) {
        items.add({
          'label':
              'Straordinario notturno/festivo (${straordinarioNotturnoFestivoHours.toStringAsFixed(1)}h × €${nightOrHolidayRate.toStringAsFixed(2)})',
          'amount': straordinarioNotturnoFestivoHours * nightOrHolidayRate,
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

      if (manual > 0) {
        items.add({
          'label': effectiveManualExtraLabel,
          'amount': manual,
        });
      }

      return items;
    }

    if (overtimeHours > 0) {
      items.add({
        'label':
            '${getOvertimeLabel(profile)} (${overtimeHours.toStringAsFixed(1)}h × €${overtimeRate.toStringAsFixed(2)})',
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

    if (manual > 0) {
      items.add({
        'label': effectiveManualExtraLabel,
        'amount': manual,
      });
    }

    return items;
  }

  double getTotalAmount([UserPayProfile? profile]) {
    return getBreakdown(profile).fold(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get overtimeRate => getOvertimeRate();
  double get overtimeAmount => getOvertimeAmount();
  double get orderPublicAmount => getOrderPublicAmount();
  double get externalServiceAmount => getExternalServiceAmount();
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
      'orderPublic': orderPublic,
      'externalService': externalService,
      'absence': absence,
      'manualExtraAmount': manualExtraAmount,
      'manualExtraLabel': manualExtraLabel,
      'straordinarioDiurnoHours': straordinarioDiurnoHours,
      'straordinarioNotturnoFestivoHours': straordinarioNotturnoFestivoHours,
      'notturnoCount': notturnoCount,
      'festivoCount': festivoCount,
      'servizioEsternoCount': servizioEsternoCount,
      'opServiceType': opServiceType.name,
      'manualAmount': manualAmount,
      'note': note,
      'workedHours': workedHoursOverride,
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

    return Shift._internal(
      description: json['description'] as String? ?? '',
      start: parsedStart,
      end: parsedEnd,
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
      straordinarioDiurnoHours: _toDouble(json['straordinarioDiurnoHours']),
      straordinarioNotturnoFestivoHours:
          _toDouble(json['straordinarioNotturnoFestivoHours']),
      notturnoCount: _toInt(json['notturnoCount']),
      festivoCount: _toInt(json['festivoCount']),
      servizioEsternoCount: _toInt(json['servizioEsternoCount']),
      opServiceType: _parseOpServiceType(json['opServiceType']?.toString()),
      manualAmount: _toDouble(json['manualAmount']),
      note: json['note']?.toString() ?? '',
      workedHoursOverride: parsedWorkedHours,
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