class PayslipExtractResult {
  final String? rank;

  final double? overtimeDayRate;
  final double? overtimeNightOrHolidayRate;
  final double? overtimeNightAndHolidayRate;

  final double? holidayAllowance;
  final double? specialHolidayAllowance;

  final double? orderPublicInSede;
  final double? orderPublicFuoriSede;
  final double? orderPublicPernotto;

  final double? externalServiceRate;

  const PayslipExtractResult({
    this.rank,
    this.overtimeDayRate,
    this.overtimeNightOrHolidayRate,
    this.overtimeNightAndHolidayRate,
    this.holidayAllowance,
    this.specialHolidayAllowance,
    this.orderPublicInSede,
    this.orderPublicFuoriSede,
    this.orderPublicPernotto,
    this.externalServiceRate,
  });

  bool get hasAnyUsefulData {
    return rank != null ||
        overtimeDayRate != null ||
        overtimeNightOrHolidayRate != null ||
        overtimeNightAndHolidayRate != null ||
        holidayAllowance != null ||
        specialHolidayAllowance != null ||
        orderPublicInSede != null ||
        orderPublicFuoriSede != null ||
        orderPublicPernotto != null ||
        externalServiceRate != null;
  }

  PayslipExtractResult copyWith({
    String? rank,
    double? overtimeDayRate,
    double? overtimeNightOrHolidayRate,
    double? overtimeNightAndHolidayRate,
    double? holidayAllowance,
    double? specialHolidayAllowance,
    double? orderPublicInSede,
    double? orderPublicFuoriSede,
    double? orderPublicPernotto,
    double? externalServiceRate,
  }) {
    return PayslipExtractResult(
      rank: rank ?? this.rank,
      overtimeDayRate: overtimeDayRate ?? this.overtimeDayRate,
      overtimeNightOrHolidayRate:
          overtimeNightOrHolidayRate ?? this.overtimeNightOrHolidayRate,
      overtimeNightAndHolidayRate:
          overtimeNightAndHolidayRate ?? this.overtimeNightAndHolidayRate,
      holidayAllowance: holidayAllowance ?? this.holidayAllowance,
      specialHolidayAllowance:
          specialHolidayAllowance ?? this.specialHolidayAllowance,
      orderPublicInSede: orderPublicInSede ?? this.orderPublicInSede,
      orderPublicFuoriSede:
          orderPublicFuoriSede ?? this.orderPublicFuoriSede,
      orderPublicPernotto: orderPublicPernotto ?? this.orderPublicPernotto,
      externalServiceRate: externalServiceRate ?? this.externalServiceRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'overtimeDayRate': overtimeDayRate,
      'overtimeNightOrHolidayRate': overtimeNightOrHolidayRate,
      'overtimeNightAndHolidayRate': overtimeNightAndHolidayRate,
      'holidayAllowance': holidayAllowance,
      'specialHolidayAllowance': specialHolidayAllowance,
      'orderPublicInSede': orderPublicInSede,
      'orderPublicFuoriSede': orderPublicFuoriSede,
      'orderPublicPernotto': orderPublicPernotto,
      'externalServiceRate': externalServiceRate,
    };
  }

  factory PayslipExtractResult.fromJson(Map<String, dynamic> json) {
    return PayslipExtractResult(
      rank: json['rank'] as String?,
      overtimeDayRate:
          (json['overtimeDayRate'] as num?)?.toDouble(),
      overtimeNightOrHolidayRate:
          (json['overtimeNightOrHolidayRate'] as num?)?.toDouble(),
      overtimeNightAndHolidayRate:
          (json['overtimeNightAndHolidayRate'] as num?)?.toDouble(),
      holidayAllowance:
          (json['holidayAllowance'] as num?)?.toDouble(),
      specialHolidayAllowance:
          (json['specialHolidayAllowance'] as num?)?.toDouble(),
      orderPublicInSede:
          (json['orderPublicInSede'] as num?)?.toDouble(),
      orderPublicFuoriSede:
          (json['orderPublicFuoriSede'] as num?)?.toDouble(),
      orderPublicPernotto:
          (json['orderPublicPernotto'] as num?)?.toDouble(),
      externalServiceRate:
          (json['externalServiceRate'] as num?)?.toDouble(),
    );
  }
}