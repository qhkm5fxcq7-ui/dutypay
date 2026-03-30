enum PayslipSectionType {
  fixedCompensation,
  accessoryCompensation,
  deduction,
  tax,
  unknown,
}

class PayslipEntry {
  final String code;
  final String description;
  final double amount;
  final double? quantity;
  final double? unitAmount;
  final String? reference;
  final PayslipSectionType sectionType;
  final bool isRecurring;

  const PayslipEntry({
    required this.code,
    required this.description,
    required this.amount,
    required this.sectionType,
    this.quantity,
    this.unitAmount,
    this.reference,
    this.isRecurring = false,
  });

  String get displayTitle {
    if (code.isEmpty) {
      return description;
    }
    return '$code $description';
  }

  String get normalizedDescription => description.toUpperCase().trim();

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'amount': amount,
      'quantity': quantity,
      'unitAmount': unitAmount,
      'reference': reference,
      'sectionType': sectionType.name,
      'isRecurring': isRecurring,
    };
  }

  factory PayslipEntry.fromJson(Map<String, dynamic> json) {
    return PayslipEntry(
      code: (json['code'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitAmount: (json['unitAmount'] as num?)?.toDouble(),
      reference: json['reference'] as String?,
      sectionType: _sectionTypeFromString(json['sectionType'] as String?),
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }

  static PayslipSectionType _sectionTypeFromString(String? value) {
    switch (value) {
      case 'fixedCompensation':
        return PayslipSectionType.fixedCompensation;
      case 'accessoryCompensation':
        return PayslipSectionType.accessoryCompensation;
      case 'deduction':
        return PayslipSectionType.deduction;
      case 'tax':
        return PayslipSectionType.tax;
      default:
        return PayslipSectionType.unknown;
    }
  }
}

class PayslipTaxSnapshot {
  final double imponibileAc;
  final double irpefAc;
  final double aliquotaMassima;
  final double imponibileAp;
  final double irpefAp;
  final double aliquotaMedia;

  const PayslipTaxSnapshot({
    required this.imponibileAc,
    required this.irpefAc,
    required this.aliquotaMassima,
    required this.imponibileAp,
    required this.irpefAp,
    required this.aliquotaMedia,
  });

  double get effectiveRateOnAp {
    if (imponibileAp <= 0) return 0;
    return irpefAp / imponibileAp;
  }

  double get effectiveRateOnAc {
    if (imponibileAc <= 0) return 0;
    return irpefAc / imponibileAc;
  }

  Map<String, dynamic> toJson() {
    return {
      'imponibileAc': imponibileAc,
      'irpefAc': irpefAc,
      'aliquotaMassima': aliquotaMassima,
      'imponibileAp': imponibileAp,
      'irpefAp': irpefAp,
      'aliquotaMedia': aliquotaMedia,
    };
  }

  factory PayslipTaxSnapshot.fromJson(Map<String, dynamic> json) {
    return PayslipTaxSnapshot(
      imponibileAc: (json['imponibileAc'] as num?)?.toDouble() ?? 0,
      irpefAc: (json['irpefAc'] as num?)?.toDouble() ?? 0,
      aliquotaMassima: (json['aliquotaMassima'] as num?)?.toDouble() ?? 0,
      imponibileAp: (json['imponibileAp'] as num?)?.toDouble() ?? 0,
      irpefAp: (json['irpefAp'] as num?)?.toDouble() ?? 0,
      aliquotaMedia: (json['aliquotaMedia'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PayslipParsedData {
  final String filePath;
  final String fileName;
  final String rawText;

  final String monthLabel;
  final int? year;
  final String cedolinoId;

  final String inquadramento;
  final String qualifica;
  final String detectedGradeLabel;
  final double? parametro;

  final double totaleNetto;
  final double? quintoCedibile;

  final double summaryFixedPay;
  final double summaryOtherAllowances;
  final double summaryThirteenth;
  final double summaryAccessoryPay;

  final double summaryPrevidenziali;
  final double summaryFiscali;
  final double summaryOtherDeductions;
  final double summaryConguagli;

  final PayslipTaxSnapshot taxes;

  final List<PayslipEntry> fixedEntries;
  final List<PayslipEntry> accessoryEntries;
  final List<PayslipEntry> deductionEntries;

  const PayslipParsedData({
    required this.filePath,
    required this.fileName,
    required this.rawText,
    required this.monthLabel,
    required this.year,
    required this.cedolinoId,
    required this.inquadramento,
    required this.qualifica,
    required this.detectedGradeLabel,
    required this.parametro,
    required this.totaleNetto,
    required this.quintoCedibile,
    required this.summaryFixedPay,
    required this.summaryOtherAllowances,
    required this.summaryThirteenth,
    required this.summaryAccessoryPay,
    required this.summaryPrevidenziali,
    required this.summaryFiscali,
    required this.summaryOtherDeductions,
    required this.summaryConguagli,
    required this.taxes,
    required this.fixedEntries,
    required this.accessoryEntries,
    required this.deductionEntries,
  });

  bool get isSupplementaryPayslip {
    final value = monthLabel.toLowerCase();
    return value.contains('pagamenti vari');
  }

  double get effectiveTaxRateForEngine {
    if (taxes.effectiveRateOnAp > 0) {
      return taxes.effectiveRateOnAp;
    }
    return taxes.effectiveRateOnAc;
  }

  List<PayslipEntry> get baseSalaryEntries =>
      fixedEntries.where(_isBaseSalaryEntry).toList();

  List<PayslipEntry> get fixedAllowanceEntries =>
      fixedEntries.where(_isFixedAllowanceEntry).toList();

  List<PayslipEntry> get operationalAccessoryEntries =>
      accessoryEntries.where(_isOperationalAccessoryEntry).toList();

  List<PayslipEntry> get otherAccessoryEntries => accessoryEntries
      .where((entry) => !_isOperationalAccessoryEntry(entry))
      .toList();

  List<PayslipEntry> get realRecurringDeductionEntries =>
      deductionEntries.where(_isRealRecurringDeductionEntry).toList();

  List<PayslipEntry> get otherDeductionEntries => deductionEntries
      .where((entry) => !_isRealRecurringDeductionEntry(entry))
      .toList();

  double get detectedBaseSalary {
    final classifiedBase = baseSalaryEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    final classifiedFixedAllowances = fixedAllowanceEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    final total = classifiedBase + classifiedFixedAllowances;

    if (total > 0) {
      return total;
    }

    return summaryFixedPay + summaryOtherAllowances;
  }

  double get detectedOperationalAccessoryTotal {
    final detailedTotal = operationalAccessoryEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    if (summaryAccessoryPay <= 0) {
      return detailedTotal;
    }

    if (detailedTotal <= 0) {
      return summaryAccessoryPay;
    }

    final ratio = detailedTotal / summaryAccessoryPay;

    if (ratio < 0.6) {
      return summaryAccessoryPay;
    }

    return detailedTotal;
  }

  double get detectedRecurringDeductionsTotal {
    final recurring = realRecurringDeductionEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    if (recurring > 0) {
      return recurring;
    }

    return summaryOtherDeductions;
  }

  bool _isBaseSalaryEntry(PayslipEntry entry) {
    final value = entry.normalizedDescription;

    return value.contains('STIPENDIO TABELLARE') ||
        value == 'STIPENDIO' ||
        value.contains('IIS') ||
        value.contains('I.I.S');
  }

  bool _isFixedAllowanceEntry(PayslipEntry entry) {
    final value = entry.normalizedDescription;

    return value.contains('VACANZA CONTRATTUALE') ||
        value.contains('IND. PENS.') ||
        value.contains('IND.PENS.') ||
        value.contains('ASSEGNO') ||
        value.contains('PARAMETRO') ||
        value.contains('RETRIBUZIONE INDIVIDUALE');
  }

  bool _isOperationalAccessoryEntry(PayslipEntry entry) {
    final value = entry.normalizedDescription;

    return value.contains('STRAORD') ||
        value.contains('ORD. PUBBL') ||
        value.contains('ORD.PUBBL') ||
        value.contains('SERVIZIO') ||
        value.contains('TURNO') ||
        value.contains('PRESENZA') ||
        value.contains('COMPENSAZIONE') ||
        value.contains('NOTT') ||
        value.contains('FEST') ||
        value.contains('REPER') ||
        value.contains('MISSIONE');
  }

  bool _isRealRecurringDeductionEntry(PayslipEntry entry) {
    final value = entry.normalizedDescription;

    return value.contains('PREST') ||
        value.contains('SINDACALE') ||
        value.contains('FONDO ASSISTENZA') ||
        value.contains('QUINTO') ||
        value.contains('CESSIONE') ||
        value.contains('MUTUO');
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'rawText': rawText,
      'monthLabel': monthLabel,
      'year': year,
      'cedolinoId': cedolinoId,
      'inquadramento': inquadramento,
      'qualifica': qualifica,
      'detectedGradeLabel': detectedGradeLabel,
      'parametro': parametro,
      'totaleNetto': totaleNetto,
      'quintoCedibile': quintoCedibile,
      'summaryFixedPay': summaryFixedPay,
      'summaryOtherAllowances': summaryOtherAllowances,
      'summaryThirteenth': summaryThirteenth,
      'summaryAccessoryPay': summaryAccessoryPay,
      'summaryPrevidenziali': summaryPrevidenziali,
      'summaryFiscali': summaryFiscali,
      'summaryOtherDeductions': summaryOtherDeductions,
      'summaryConguagli': summaryConguagli,
      'taxes': taxes.toJson(),
      'fixedEntries': fixedEntries.map((e) => e.toJson()).toList(),
      'accessoryEntries': accessoryEntries.map((e) => e.toJson()).toList(),
      'deductionEntries': deductionEntries.map((e) => e.toJson()).toList(),
    };
  }

  factory PayslipParsedData.fromJson(Map<String, dynamic> json) {
    return PayslipParsedData(
      filePath: (json['filePath'] ?? '') as String,
      fileName: (json['fileName'] ?? '') as String,
      rawText: (json['rawText'] ?? '') as String,
      monthLabel: (json['monthLabel'] ?? '') as String,
      year: json['year'] as int?,
      cedolinoId: (json['cedolinoId'] ?? '') as String,
      inquadramento: (json['inquadramento'] ?? '') as String,
      qualifica: (json['qualifica'] ?? '') as String,
      detectedGradeLabel: (json['detectedGradeLabel'] ?? '') as String,
      parametro: (json['parametro'] as num?)?.toDouble(),
      totaleNetto: (json['totaleNetto'] as num?)?.toDouble() ?? 0,
      quintoCedibile: (json['quintoCedibile'] as num?)?.toDouble(),
      summaryFixedPay: (json['summaryFixedPay'] as num?)?.toDouble() ?? 0,
      summaryOtherAllowances:
          (json['summaryOtherAllowances'] as num?)?.toDouble() ?? 0,
      summaryThirteenth: (json['summaryThirteenth'] as num?)?.toDouble() ?? 0,
      summaryAccessoryPay:
          (json['summaryAccessoryPay'] as num?)?.toDouble() ?? 0,
      summaryPrevidenziali:
          (json['summaryPrevidenziali'] as num?)?.toDouble() ?? 0,
      summaryFiscali: (json['summaryFiscali'] as num?)?.toDouble() ?? 0,
      summaryOtherDeductions:
          (json['summaryOtherDeductions'] as num?)?.toDouble() ?? 0,
      summaryConguagli: (json['summaryConguagli'] as num?)?.toDouble() ?? 0,
      taxes: json['taxes'] is Map<String, dynamic>
          ? PayslipTaxSnapshot.fromJson(json['taxes'] as Map<String, dynamic>)
          : const PayslipTaxSnapshot(
              imponibileAc: 0,
              irpefAc: 0,
              aliquotaMassima: 0,
              imponibileAp: 0,
              irpefAp: 0,
              aliquotaMedia: 0,
            ),
      fixedEntries: (json['fixedEntries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PayslipEntry.fromJson)
          .toList(),
      accessoryEntries: (json['accessoryEntries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PayslipEntry.fromJson)
          .toList(),
      deductionEntries: (json['deductionEntries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PayslipEntry.fromJson)
          .toList(),
    );
  }
}

class UserPayProfile {
  final String? rank;

  final double overtimeDayRate;
  final double overtimeNightOrHolidayRate;
  final double overtimeNightAndHolidayRate;

  final double orderPublicInSede;
  final double orderPublicFuoriSede;
  final double orderPublicPernotto;

  final double externalServiceRate;
  final double holidayAllowance;
  final double specialHolidayAllowance;

  final double monthlyOvertimePayableHoursLimit;

  final String profileVersion;
  final DateTime calibratedAt;
  final String sourceWindowLabel;
  final String detectedGradeLabel;
  final double detectedBaseSalary;
  final double averageAccessoryPay;

  final double? historicalAccessoryAvg;
  final double? historicalHoursAvg;
  final int? historicalMonths;

  final double recurringDeductionsTotal;
  final double effectiveTaxRate;
  final List<PayslipParsedData> sourcePayslips;

  final double? annualProductionBonus;

  final double genereDiConfortoRate;
  final double ticketPastoRate;

  const UserPayProfile({
    this.rank,
    required this.overtimeDayRate,
    required this.overtimeNightOrHolidayRate,
    required this.overtimeNightAndHolidayRate,
    required this.orderPublicInSede,
    required this.orderPublicFuoriSede,
    required this.orderPublicPernotto,
    required this.externalServiceRate,
    required this.holidayAllowance,
    required this.specialHolidayAllowance,
    required this.monthlyOvertimePayableHoursLimit,
    required this.profileVersion,
    required this.calibratedAt,
    required this.sourceWindowLabel,
    required this.detectedGradeLabel,
    required this.detectedBaseSalary,
    required this.averageAccessoryPay,
    this.historicalAccessoryAvg,
    this.historicalHoursAvg,
    this.historicalMonths,
    required this.recurringDeductionsTotal,
    required this.effectiveTaxRate,
    required this.sourcePayslips,
    this.annualProductionBonus,
    required this.genereDiConfortoRate,
    required this.ticketPastoRate,
  });

  factory UserPayProfile.defaultProfile() {
    return UserPayProfile(
      rank: null,
      overtimeDayRate: 12.0,
      overtimeNightOrHolidayRate: 13.5,
      overtimeNightAndHolidayRate: 15.0,
      orderPublicInSede: 6.0,
      orderPublicFuoriSede: 10.0,
      orderPublicPernotto: 15.0,
      externalServiceRate: 6.0,
      holidayAllowance: 8.0,
      specialHolidayAllowance: 10.0,
      monthlyOvertimePayableHoursLimit: 55.0,
      profileVersion: 'default',
      calibratedAt: DateTime.now(),
      sourceWindowLabel: '',
      detectedGradeLabel: 'Non rilevato',
      detectedBaseSalary: 0,
      averageAccessoryPay: 0,
      historicalAccessoryAvg: null,
      historicalHoursAvg: null,
      historicalMonths: null,
      recurringDeductionsTotal: 0,
      effectiveTaxRate: 0.27,
      sourcePayslips: const [],
      annualProductionBonus: null,
      genereDiConfortoRate: 1.02,
      ticketPastoRate: 7.00,
    );
  }

  double get baseNetSalary {
    if (detectedBaseSalary <= 0) return 0;
    return detectedBaseSalary * 0.78;
  }

  UserPayProfile copyWith({
    String? rank,
    double? overtimeDayRate,
    double? overtimeNightOrHolidayRate,
    double? overtimeNightAndHolidayRate,
    double? orderPublicInSede,
    double? orderPublicFuoriSede,
    double? orderPublicPernotto,
    double? externalServiceRate,
    double? holidayAllowance,
    double? specialHolidayAllowance,
    double? monthlyOvertimePayableHoursLimit,
    String? profileVersion,
    DateTime? calibratedAt,
    String? sourceWindowLabel,
    double? detectedBaseSalary,
    String? detectedGradeLabel,
    double? averageAccessoryPay,
    double? historicalAccessoryAvg,
    double? historicalHoursAvg,
    int? historicalMonths,
    double? recurringDeductionsTotal,
    double? effectiveTaxRate,
    List<PayslipParsedData>? sourcePayslips,
    double? annualProductionBonus,
    double? genereDiConfortoRate,
    double? ticketPastoRate,
  }) {
    return UserPayProfile(
      rank: rank ?? this.rank,
      overtimeDayRate: overtimeDayRate ?? this.overtimeDayRate,
      overtimeNightOrHolidayRate:
          overtimeNightOrHolidayRate ?? this.overtimeNightOrHolidayRate,
      overtimeNightAndHolidayRate:
          overtimeNightAndHolidayRate ?? this.overtimeNightAndHolidayRate,
      orderPublicInSede: orderPublicInSede ?? this.orderPublicInSede,
      orderPublicFuoriSede: orderPublicFuoriSede ?? this.orderPublicFuoriSede,
      orderPublicPernotto: orderPublicPernotto ?? this.orderPublicPernotto,
      externalServiceRate: externalServiceRate ?? this.externalServiceRate,
      holidayAllowance: holidayAllowance ?? this.holidayAllowance,
      specialHolidayAllowance:
          specialHolidayAllowance ?? this.specialHolidayAllowance,
      monthlyOvertimePayableHoursLimit:
          monthlyOvertimePayableHoursLimit ??
              this.monthlyOvertimePayableHoursLimit,
      profileVersion: profileVersion ?? this.profileVersion,
      calibratedAt: calibratedAt ?? this.calibratedAt,
      sourceWindowLabel: sourceWindowLabel ?? this.sourceWindowLabel,
      detectedGradeLabel: detectedGradeLabel ?? this.detectedGradeLabel,
      detectedBaseSalary: detectedBaseSalary ?? this.detectedBaseSalary,
      averageAccessoryPay: averageAccessoryPay ?? this.averageAccessoryPay,
      historicalAccessoryAvg:
          historicalAccessoryAvg ?? this.historicalAccessoryAvg,
      historicalHoursAvg: historicalHoursAvg ?? this.historicalHoursAvg,
      historicalMonths: historicalMonths ?? this.historicalMonths,
      recurringDeductionsTotal:
          recurringDeductionsTotal ?? this.recurringDeductionsTotal,
      effectiveTaxRate: effectiveTaxRate ?? this.effectiveTaxRate,
      sourcePayslips: sourcePayslips ?? this.sourcePayslips,
      annualProductionBonus:
          annualProductionBonus ?? this.annualProductionBonus,
      genereDiConfortoRate:
          genereDiConfortoRate ?? this.genereDiConfortoRate,
      ticketPastoRate: ticketPastoRate ?? this.ticketPastoRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'overtimeDayRate': overtimeDayRate,
      'overtimeNightOrHolidayRate': overtimeNightOrHolidayRate,
      'overtimeNightAndHolidayRate': overtimeNightAndHolidayRate,
      'orderPublicInSede': orderPublicInSede,
      'orderPublicFuoriSede': orderPublicFuoriSede,
      'orderPublicPernotto': orderPublicPernotto,
      'externalServiceRate': externalServiceRate,
      'holidayAllowance': holidayAllowance,
      'specialHolidayAllowance': specialHolidayAllowance,
      'monthlyOvertimePayableHoursLimit': monthlyOvertimePayableHoursLimit,
      'profileVersion': profileVersion,
      'calibratedAt': calibratedAt.toIso8601String(),
      'sourceWindowLabel': sourceWindowLabel,
      'detectedGradeLabel': detectedGradeLabel,
      'detectedBaseSalary': detectedBaseSalary,
      'averageAccessoryPay': averageAccessoryPay,
      'historicalAccessoryAvg': historicalAccessoryAvg,
      'historicalHoursAvg': historicalHoursAvg,
      'historicalMonths': historicalMonths,
      'recurringDeductionsTotal': recurringDeductionsTotal,
      'effectiveTaxRate': effectiveTaxRate,
      'sourcePayslips': sourcePayslips.map((e) => e.toJson()).toList(),
      'annualProductionBonus': annualProductionBonus,
      'genereDiConfortoRate': genereDiConfortoRate,
      'ticketPastoRate': ticketPastoRate,
    };
  }

  factory UserPayProfile.fromJson(Map<String, dynamic> json) {
    return UserPayProfile(
      rank: json['rank'] as String?,
      overtimeDayRate: (json['overtimeDayRate'] as num?)?.toDouble() ?? 12.0,
      overtimeNightOrHolidayRate:
          (json['overtimeNightOrHolidayRate'] as num?)?.toDouble() ?? 13.5,
      overtimeNightAndHolidayRate:
          (json['overtimeNightAndHolidayRate'] as num?)?.toDouble() ?? 15.0,
      orderPublicInSede:
          (json['orderPublicInSede'] as num?)?.toDouble() ?? 6.0,
      orderPublicFuoriSede:
          (json['orderPublicFuoriSede'] as num?)?.toDouble() ?? 10.0,
      orderPublicPernotto:
          (json['orderPublicPernotto'] as num?)?.toDouble() ?? 15.0,
      externalServiceRate:
          (json['externalServiceRate'] as num?)?.toDouble() ?? 6.0,
      holidayAllowance:
          (json['holidayAllowance'] as num?)?.toDouble() ?? 8.0,
      specialHolidayAllowance:
          (json['specialHolidayAllowance'] as num?)?.toDouble() ?? 10.0,
      monthlyOvertimePayableHoursLimit:
          (json['monthlyOvertimePayableHoursLimit'] as num?)?.toDouble() ??
              55.0,
      profileVersion: (json['profileVersion'] ?? 'default') as String,
      calibratedAt: DateTime.tryParse(
            (json['calibratedAt'] ?? '') as String,
          ) ??
          DateTime.now(),
      sourceWindowLabel: (json['sourceWindowLabel'] ?? '') as String,
      detectedGradeLabel:
          (json['detectedGradeLabel'] ?? 'Non rilevato') as String,
      detectedBaseSalary:
          (json['detectedBaseSalary'] as num?)?.toDouble() ?? 0,
      averageAccessoryPay:
          (json['averageAccessoryPay'] as num?)?.toDouble() ?? 0,
      historicalAccessoryAvg:
          (json['historicalAccessoryAvg'] as num?)?.toDouble(),
      historicalHoursAvg: (json['historicalHoursAvg'] as num?)?.toDouble(),
      historicalMonths: json['historicalMonths'] as int?,
      recurringDeductionsTotal:
          (json['recurringDeductionsTotal'] as num?)?.toDouble() ?? 0,
      effectiveTaxRate:
          (json['effectiveTaxRate'] as num?)?.toDouble() ?? 0.27,
      sourcePayslips: (json['sourcePayslips'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PayslipParsedData.fromJson)
          .toList(),
      annualProductionBonus:
          (json['annualProductionBonus'] as num?)?.toDouble(),
      genereDiConfortoRate:
          (json['genereDiConfortoRate'] as num?)?.toDouble() ?? 1.02,
      ticketPastoRate:
          (json['ticketPastoRate'] as num?)?.toDouble() ?? 7.00,
    );
  }
}