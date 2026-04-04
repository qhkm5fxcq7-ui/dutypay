import '../models/shift.dart';
import '../models/user_pay_profile.dart';
import '../../../departments/models/allowance_payroll_impact.dart';

enum PrecisionLevel {
  low,
  medium,
  high,
}

class PrecisionStatus {
  final PrecisionLevel level;
  final double percentage;

  const PrecisionStatus({
    required this.level,
    required this.percentage,
  });
}

class BasketPayment {
  static const String legacyDefaultDepartmentId = 'polizia_mobile';

  final DateTime paymentMonth;
  final double hoursPaid;
  final String note;
  final String departmentId;

  const BasketPayment({
    required this.paymentMonth,
    required this.hoursPaid,
    this.note = '',
    required this.departmentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentMonth': paymentMonth.toIso8601String(),
      'hoursPaid': hoursPaid,
      'note': note,
      'departmentId': departmentId,
    };
  }

  factory BasketPayment.fromJson(Map<String, dynamic> json) {
    final parsedDepartmentId =
        (json['departmentId'] as String?)?.trim().isNotEmpty == true
            ? (json['departmentId'] as String).trim()
            : legacyDefaultDepartmentId;

    return BasketPayment(
      paymentMonth: DateTime.tryParse(
            (json['paymentMonth'] ?? '') as String,
          ) ??
          DateTime.now(),
      hoursPaid: (json['hoursPaid'] as num?)?.toDouble() ?? 0,
      note: (json['note'] ?? '') as String,
      departmentId: parsedDepartmentId,
    );
  }
}

class MonthlyAccessorySummary {
  final DateTime month;
  final int shiftCount;
  final double nonOvertimeGross;
  final double overtimeGross;
  final double overtimeHours;
  final double totalGross;

  const MonthlyAccessorySummary({
    required this.month,
    required this.shiftCount,
    required this.nonOvertimeGross,
    required this.overtimeGross,
    required this.overtimeHours,
    required this.totalGross,
  });
}

class BasketCarryEntry {
  final DateTime sourceMonth;
  final double overtimeGrossRemaining;
  final double overtimeHoursRemaining;

  const BasketCarryEntry({
    required this.sourceMonth,
    required this.overtimeGrossRemaining,
    required this.overtimeHoursRemaining,
  });
}

class PayslipProjectionResult {
  final DateTime payslipMonth;
  final DateTime? accessoryReferenceMonth;
  final int accessoryDelayMonths;
  final DateTime? basketStartMonth;

  final int referenceMonthShiftCount;

  final double fixedBaseGross;
  final double fixedBaseNetEstimated;

  final double nonOvertimeGross;
  final double overtimeGrossFromReferenceMonth;
  final double overtimeHoursFromReferenceMonth;

  final double basketRecoveredGross;
  final double basketRecoveredHours;

  final double liquidatedOvertimeGross;
  final double liquidatedOvertimeHours;

  final double overtimeInBasketGross;
  final double overtimeInBasketHours;

  final double accessoriesGrossLiquidated;
  final double accessoriesGrossUsedForEstimate;
  final double accessoriesNetEstimated;
  final double v2MonthlyAllowancesGross;
  final double v2BasketAllowancesGross;
  final double basketOvertimeResidualGrossEstimate;
  final double basketAllowanceResidualGross;
  final bool isUsingHistoricalAccessories;

  final double estimatedPrevidenziali;
  final double estimatedFiscali;
  final double estimatedOtherDeductions;
  final double estimatedConguagli;
  final double totalEstimatedDeductions;

  final double recurringDeductionsApplied;

  final double manualBasketPaidHoursForMonth;
  final double manualBasketPaidGrossForMonth;

  final double currentBasketResidualHours;
  final double currentBasketResidualGrossEstimate;

  final double estimatedPayslipTotal;

  final double monthlyOvertimePayableHoursLimit;

  final double historicalAverageNet;
  final double historicalAverageGross;
  final double historicalAverageFixedGross;
  final double historicalAverageAccessoryGross;
  final double historicalAveragePrevidenziali;
  final double historicalAverageFiscali;
  final double historicalAverageOtherDeductions;
  final double historicalAverageConguagli;

  final List<BasketCarryEntry> openBasketEntries;

  const PayslipProjectionResult({
    required this.payslipMonth,
    required this.accessoryReferenceMonth,
    required this.accessoryDelayMonths,
    required this.basketStartMonth,
    required this.referenceMonthShiftCount,
    required this.fixedBaseGross,
    required this.fixedBaseNetEstimated,
    required this.nonOvertimeGross,
    required this.overtimeGrossFromReferenceMonth,
    required this.overtimeHoursFromReferenceMonth,
    required this.basketRecoveredGross,
    required this.basketRecoveredHours,
    required this.liquidatedOvertimeGross,
    required this.liquidatedOvertimeHours,
    required this.overtimeInBasketGross,
    required this.overtimeInBasketHours,
    required this.accessoriesGrossLiquidated,
    required this.accessoriesGrossUsedForEstimate,
    required this.accessoriesNetEstimated,
    required this.v2MonthlyAllowancesGross,
    required this.v2BasketAllowancesGross,
    required this.basketOvertimeResidualGrossEstimate,
    required this.basketAllowanceResidualGross,
    required this.isUsingHistoricalAccessories,
    required this.estimatedPrevidenziali,
    required this.estimatedFiscali,
    required this.estimatedOtherDeductions,
    required this.estimatedConguagli,
    required this.totalEstimatedDeductions,
    required this.recurringDeductionsApplied,
    required this.manualBasketPaidHoursForMonth,
    required this.manualBasketPaidGrossForMonth,
    required this.currentBasketResidualHours,
    required this.currentBasketResidualGrossEstimate,
    required this.estimatedPayslipTotal,
    required this.monthlyOvertimePayableHoursLimit,
    required this.historicalAverageNet,
    required this.historicalAverageGross,
    required this.historicalAverageFixedGross,
    required this.historicalAverageAccessoryGross,
    required this.historicalAveragePrevidenziali,
    required this.historicalAverageFiscali,
    required this.historicalAverageOtherDeductions,
    required this.historicalAverageConguagli,
    required this.openBasketEntries,
  });

  bool get hasReferenceMonthData => referenceMonthShiftCount > 0;

  bool get hasAnyBasketMovement =>
      basketRecoveredGross > 0 ||
      liquidatedOvertimeGross > 0 ||
      overtimeInBasketGross > 0 ||
      openBasketEntries.isNotEmpty ||
      manualBasketPaidHoursForMonth > 0 ||
      currentBasketResidualHours > 0;

  double get extraGross => accessoriesGrossUsedForEstimate;
  double get extraNet => accessoriesNetEstimated;

  double get taxes => extraGross - extraNet;
}

class _HistoricalCalibrationSnapshot {
  final double averageNet;
  final double averageGross;
  final double averageFixedGross;
  final double averageAccessoryGross;
  final double averagePrevidenziali;
  final double averageFiscali;
  final double averageOtherDeductions;
  final double averageConguagli;
  final double averageAccessoryTaxRate;
  final double averageFixedNetRatio;

  const _HistoricalCalibrationSnapshot({
    required this.averageNet,
    required this.averageGross,
    required this.averageFixedGross,
    required this.averageAccessoryGross,
    required this.averagePrevidenziali,
    required this.averageFiscali,
    required this.averageOtherDeductions,
    required this.averageConguagli,
    required this.averageAccessoryTaxRate,
    required this.averageFixedNetRatio,
  });
}

class _DeductionShares {
  final double previdShare;
  final double fiscalShare;
  final double otherShare;
  final double conguagliShare;

  const _DeductionShares({
    required this.previdShare,
    required this.fiscalShare,
    required this.otherShare,
    required this.conguagliShare,
  });
}

class PayslipProjectionService {
  const PayslipProjectionService();

  static const int _historicalAccessoriesThreshold = 5;

  PayslipProjectionResult projectPayslip({
  required DateTime payslipMonth,
  required List<Shift> allShifts,
  required UserPayProfile payProfile,
  List<BasketPayment> basketPayments = const [],
  AllowancePayrollImpact? allowancePayrollImpact,
}) {
    final normalizedPayslipMonth =
        DateTime(payslipMonth.year, payslipMonth.month);

    final accessoryDelayMonths =
        _resolveAccessoryDelayMonths(normalizedPayslipMonth);

    final accessoryReferenceMonth = accessoryDelayMonths == 0
        ? null
        : DateTime(
            normalizedPayslipMonth.year,
            normalizedPayslipMonth.month - accessoryDelayMonths,
          );

    final fixedBaseGross = _sanitizeMoney(payProfile.detectedBaseSalary);
    final overtimeHoursLimit =
        _sanitizeNonNegative(payProfile.monthlyOvertimePayableHoursLimit);
        final v2MonthlyAllowancesGross =
    _sanitizeMoney(allowancePayrollImpact?.monthlyAllowanceTotal ?? 0.0);

final v2BasketAllowancesGross =
    _sanitizeMoney(allowancePayrollImpact?.basketAllowanceTotal ?? 0.0);

    final basketStartMonth = _findFirstShiftMonth(allShifts);

    final relevantMonths = accessoryReferenceMonth == null
        ? <DateTime>[]
        : basketStartMonth == null
            ? <DateTime>[accessoryReferenceMonth]
            : _buildMonthsUpTo(
                startMonth: basketStartMonth,
                targetMonth: accessoryReferenceMonth,
              );

    final monthlySummaries = relevantMonths
        .map(
          (month) => _buildMonthlySummary(
            month: month,
            allShifts: allShifts,
            payProfile: payProfile,
          ),
        )
        .toList();

    final referenceSummary = accessoryReferenceMonth == null
        ? MonthlyAccessorySummary(
            month: normalizedPayslipMonth,
            shiftCount: 0,
            nonOvertimeGross: 0,
            overtimeGross: 0,
            overtimeHours: 0,
            totalGross: 0,
          )
        : monthlySummaries
                .where((item) => _isSameMonth(item.month, accessoryReferenceMonth))
                .cast<MonthlyAccessorySummary?>()
                .firstWhere(
                  (item) => item != null,
                  orElse: () => null,
                ) ??
            MonthlyAccessorySummary(
              month: accessoryReferenceMonth,
              shiftCount: 0,
              nonOvertimeGross: 0,
              overtimeGross: 0,
              overtimeHours: 0,
              totalGross: 0,
            );

    final previousMonths = accessoryReferenceMonth == null
        ? <MonthlyAccessorySummary>[]
        : monthlySummaries
            .where((item) => _isBeforeMonth(item.month, accessoryReferenceMonth))
            .toList();

    double remainingCapacityHours = overtimeHoursLimit;
    double basketRecoveredGross = 0;
    double basketRecoveredHours = 0;
    final openBasketEntries = <BasketCarryEntry>[];

    for (final monthSummary in previousMonths) {
      if (monthSummary.overtimeHours <= 0 || monthSummary.overtimeGross <= 0) {
        continue;
      }

      if (remainingCapacityHours <= 0) {
        openBasketEntries.add(
          BasketCarryEntry(
            sourceMonth: monthSummary.month,
            overtimeGrossRemaining: monthSummary.overtimeGross,
            overtimeHoursRemaining: monthSummary.overtimeHours,
          ),
        );
        continue;
      }

      final liquidableHours =
          monthSummary.overtimeHours <= remainingCapacityHours
              ? monthSummary.overtimeHours
              : remainingCapacityHours;

      final grossPerHour = monthSummary.overtimeHours > 0
          ? monthSummary.overtimeGross / monthSummary.overtimeHours
          : 0.0;

      final recoveredGross = liquidableHours * grossPerHour;
      final residualHours = monthSummary.overtimeHours - liquidableHours;
      final residualGross = monthSummary.overtimeGross - recoveredGross;

      basketRecoveredHours += liquidableHours;
      basketRecoveredGross += recoveredGross;
      remainingCapacityHours -= liquidableHours;

      if (residualHours > 0.0001 && residualGross > 0.0001) {
        openBasketEntries.add(
          BasketCarryEntry(
            sourceMonth: monthSummary.month,
            overtimeGrossRemaining: residualGross,
            overtimeHoursRemaining: residualHours,
          ),
        );
      }
    }

    double liquidatedOvertimeHours = 0;
    double liquidatedOvertimeGross = 0;
    double overtimeInBasketHours = 0;
    double overtimeInBasketGross = 0;

    if (referenceSummary.overtimeHours > 0 &&
        referenceSummary.overtimeGross > 0) {
      if (remainingCapacityHours <= 0) {
        overtimeInBasketHours = referenceSummary.overtimeHours;
        overtimeInBasketGross = referenceSummary.overtimeGross;
      } else {
        final liquidableHours =
            referenceSummary.overtimeHours <= remainingCapacityHours
                ? referenceSummary.overtimeHours
                : remainingCapacityHours;

        final grossPerHour = referenceSummary.overtimeHours > 0
            ? referenceSummary.overtimeGross / referenceSummary.overtimeHours
            : 0.0;

        liquidatedOvertimeHours = liquidableHours;
        liquidatedOvertimeGross = liquidableHours * grossPerHour;

        overtimeInBasketHours =
            referenceSummary.overtimeHours - liquidableHours;
        overtimeInBasketGross =
            referenceSummary.overtimeGross - liquidatedOvertimeGross;
      }
    }

    if (overtimeInBasketHours > 0.0001 && overtimeInBasketGross > 0.0001) {
      openBasketEntries.add(
        BasketCarryEntry(
          sourceMonth: referenceSummary.month,
          overtimeGrossRemaining: overtimeInBasketGross,
          overtimeHoursRemaining: overtimeInBasketHours,
        ),
      );
    }

    final rawOpenBasketHours = _sanitizeNonNegative(
      openBasketEntries.fold<double>(
        0.0,
        (sum, item) => sum + item.overtimeHoursRemaining,
      ),
    );

    final rawOpenBasketGross = _sanitizeMoney(
      openBasketEntries.fold<double>(
        0.0,
        (sum, item) => sum + item.overtimeGrossRemaining,
      ),
    );

    final manualBasketPaidHoursForMonth = _sanitizeNonNegative(
      basketPayments
          .where((payment) => _isSameMonth(payment.paymentMonth, normalizedPayslipMonth))
          .fold<double>(0.0, (sum, item) => sum + item.hoursPaid),
    );

    final manualBasketPaidGrossForMonth = _sanitizeMoney(
      basketPayments
          .where((payment) => _isSameMonth(payment.paymentMonth, normalizedPayslipMonth))
          .fold<double>(
            0.0,
            (sum, item) =>
                sum +
                _estimateBasketPaymentGross(
                  hours: item.hoursPaid,
                  allShifts: allShifts,
                  payProfile: payProfile,
                ),
          ),
    );

    final cumulativeManualPaidHours = _sanitizeNonNegative(
      basketPayments
          .where((payment) => !_isAfterMonth(payment.paymentMonth, normalizedPayslipMonth))
          .fold<double>(0.0, (sum, item) => sum + item.hoursPaid),
    );

    final cumulativeManualPaidGross = _sanitizeMoney(
      basketPayments
          .where((payment) => !_isAfterMonth(payment.paymentMonth, normalizedPayslipMonth))
          .fold<double>(
            0.0,
            (sum, item) =>
                sum +
                _estimateBasketPaymentGross(
                  hours: item.hoursPaid,
                  allShifts: allShifts,
                  payProfile: payProfile,
                ),
          ),
    );

    final currentBasketResidualHours = _sanitizeNonNegative(
      rawOpenBasketHours - cumulativeManualPaidHours,
    );
        final basketOvertimeResidualGrossEstimate = _sanitizeMoney(
      rawOpenBasketGross - cumulativeManualPaidGross,
    );

    final basketAllowanceResidualGross = _sanitizeMoney(
      v2BasketAllowancesGross,
    );

        final currentBasketResidualGrossEstimate = _sanitizeMoney(
      basketOvertimeResidualGrossEstimate + basketAllowanceResidualGross,
    );

    final nonOvertimeGross = _sanitizeMoney(referenceSummary.nonOvertimeGross);

    final accessoriesGrossLiquidated = _sanitizeMoney(
      nonOvertimeGross + basketRecoveredGross + liquidatedOvertimeGross,
    );

    final historical = _buildHistoricalCalibrationSnapshot(
      payProfile.sourcePayslips,
    );

    final hasManualHistoricalOverride =
        payProfile.historicalAccessoryAvg != null &&
        payProfile.historicalAccessoryAvg! > 0;

    final isUsingHistoricalAccessories =
        referenceSummary.shiftCount < _historicalAccessoriesThreshold ||
        hasManualHistoricalOverride;

    double historicalGrossFromNet = 0;

    if (hasManualHistoricalOverride) {
      final accessoryTaxRate = _clamp(
        historical.averageAccessoryTaxRate > 0
            ? historical.averageAccessoryTaxRate
            : payProfile.effectiveTaxRate,
        min: 0.20,
        max: 0.35,
      );

      final netValue = payProfile.historicalAccessoryAvg!;
      historicalGrossFromNet = netValue / (1 - accessoryTaxRate);
    }

    final estimatedBaseAccessoriesGross = _sanitizeMoney(
      accessoryReferenceMonth == null
          ? 0
          : hasManualHistoricalOverride &&
                  referenceSummary.shiftCount < _historicalAccessoriesThreshold
              ? historicalGrossFromNet
              : _calculateWeightedAccessoriesGross(
                  shiftsCount: referenceSummary.shiftCount,
                  realAccessoriesGross: accessoriesGrossLiquidated,
                  historicalAverageGross: historical.averageAccessoryGross,
                ),
    );

    final accessoriesGrossUsedForEstimate = _sanitizeMoney(
  estimatedBaseAccessoriesGross +
      manualBasketPaidGrossForMonth +
      v2MonthlyAllowancesGross,
);

    final accessoryTaxRate = _clamp(
      historical.averageAccessoryTaxRate > 0
          ? historical.averageAccessoryTaxRate
          : payProfile.effectiveTaxRate,
      min: 0.20,
      max: 0.35,
    );

    final fixedNetRatio = _clamp(
      historical.averageFixedNetRatio > 0
          ? historical.averageFixedNetRatio
          : 0.78,
      min: 0.55,
      max: 0.90,
    );

    final fixedBaseNetEstimated = _sanitizeMoney(
      fixedBaseGross * fixedNetRatio,
    );

    final accessoriesNetEstimated = _sanitizeMoney(
      accessoriesGrossUsedForEstimate * (1 - accessoryTaxRate),
    );

    final recurringDeductionsApplied = _sanitizeMoney(
      payProfile.recurringDeductionsTotal,
    );

    final estimatedPayslipTotal = _sanitizeMoney(
      fixedBaseNetEstimated +
          accessoriesNetEstimated -
          recurringDeductionsApplied,
    );

    final coreTaxAndContribDeductions = _sanitizeMoney(
      (fixedBaseGross + accessoriesGrossUsedForEstimate) -
          (fixedBaseNetEstimated + accessoriesNetEstimated),
    );

    final totalEstimatedDeductions = _sanitizeMoney(
      coreTaxAndContribDeductions + recurringDeductionsApplied,
    );

    final deductionShares = _deriveDeductionShares(historical);

    final estimatedPrevidenziali = _sanitizeMoney(
      coreTaxAndContribDeductions * deductionShares.previdShare,
    );

    final estimatedFiscali = _sanitizeMoney(
      coreTaxAndContribDeductions * deductionShares.fiscalShare,
    );

    final estimatedOtherDeductions = _sanitizeMoney(
      (coreTaxAndContribDeductions * deductionShares.otherShare) +
          recurringDeductionsApplied,
    );

    final estimatedConguagli = _sanitizeMoney(
      coreTaxAndContribDeductions * deductionShares.conguagliShare,
    );

    return PayslipProjectionResult(
      payslipMonth: normalizedPayslipMonth,
      accessoryReferenceMonth: accessoryReferenceMonth,
      accessoryDelayMonths: accessoryDelayMonths,
      basketStartMonth: basketStartMonth,
      referenceMonthShiftCount: referenceSummary.shiftCount,
      fixedBaseGross: fixedBaseGross,
      fixedBaseNetEstimated: fixedBaseNetEstimated,
      nonOvertimeGross: nonOvertimeGross,
      overtimeGrossFromReferenceMonth:
          _sanitizeMoney(referenceSummary.overtimeGross),
      overtimeHoursFromReferenceMonth:
          _sanitizeNonNegative(referenceSummary.overtimeHours),
      basketRecoveredGross: _sanitizeMoney(basketRecoveredGross),
      basketRecoveredHours: _sanitizeNonNegative(basketRecoveredHours),
      liquidatedOvertimeGross: _sanitizeMoney(liquidatedOvertimeGross),
      liquidatedOvertimeHours: _sanitizeNonNegative(liquidatedOvertimeHours),
      overtimeInBasketGross: _sanitizeMoney(overtimeInBasketGross),
      overtimeInBasketHours: _sanitizeNonNegative(overtimeInBasketHours),
      accessoriesGrossLiquidated: accessoriesGrossLiquidated,
      accessoriesGrossUsedForEstimate: accessoriesGrossUsedForEstimate,
      accessoriesNetEstimated: accessoriesNetEstimated,
      isUsingHistoricalAccessories: isUsingHistoricalAccessories,
      estimatedPrevidenziali: estimatedPrevidenziali,
      estimatedFiscali: estimatedFiscali,
      estimatedOtherDeductions: estimatedOtherDeductions,
      estimatedConguagli: estimatedConguagli,
      totalEstimatedDeductions: totalEstimatedDeductions,
      recurringDeductionsApplied: recurringDeductionsApplied,
      manualBasketPaidHoursForMonth: manualBasketPaidHoursForMonth,
      manualBasketPaidGrossForMonth: manualBasketPaidGrossForMonth,
      currentBasketResidualHours: currentBasketResidualHours,
      currentBasketResidualGrossEstimate: currentBasketResidualGrossEstimate,
      estimatedPayslipTotal: estimatedPayslipTotal,
      monthlyOvertimePayableHoursLimit: overtimeHoursLimit,
      historicalAverageNet: historical.averageNet,
      historicalAverageGross: historical.averageGross,
      historicalAverageFixedGross: historical.averageFixedGross,
      historicalAverageAccessoryGross: historical.averageAccessoryGross,
      historicalAveragePrevidenziali: historical.averagePrevidenziali,
      historicalAverageFiscali: historical.averageFiscali,
      historicalAverageOtherDeductions: historical.averageOtherDeductions,
      historicalAverageConguagli: historical.averageConguagli,
      openBasketEntries: openBasketEntries,
      v2MonthlyAllowancesGross: v2MonthlyAllowancesGross,
      v2BasketAllowancesGross: v2BasketAllowancesGross,
            basketOvertimeResidualGrossEstimate: basketOvertimeResidualGrossEstimate,
      basketAllowanceResidualGross: basketAllowanceResidualGross,
    );
  }

  PrecisionStatus calculatePrecision({
    required List<Shift> allShifts,
  }) {
    final months = allShifts
    .map((shift) => DateTime(shift.serviceDate.year, shift.serviceDate.month))
    .toSet()
    .length;

    if (months == 0) {
      return const PrecisionStatus(
        level: PrecisionLevel.low,
        percentage: 20,
      );
    }

    if (months == 1) {
      return const PrecisionStatus(
        level: PrecisionLevel.low,
        percentage: 40,
      );
    }

    if (months == 2) {
      return const PrecisionStatus(
        level: PrecisionLevel.medium,
        percentage: 70,
      );
    }

    return const PrecisionStatus(
      level: PrecisionLevel.high,
      percentage: 100,
    );
  }

  int _resolveAccessoryDelayMonths(DateTime payslipMonth) {
    if (payslipMonth.month == 1) {
      return 0;
    }

    if (payslipMonth.month == 12) {
      return 1;
    }

    return 2;
  }

  double _calculateWeightedAccessoriesGross({
    required int shiftsCount,
    required double realAccessoriesGross,
    required double historicalAverageGross,
  }) {
    if (shiftsCount >= _historicalAccessoriesThreshold) {
      return realAccessoriesGross;
    }

    final historicalWeight = switch (shiftsCount) {
      0 => 1.00,
      1 => 0.85,
      2 => 0.70,
      3 => 0.55,
      4 => 0.40,
      _ => 0.0,
    };

    final realWeight = 1 - historicalWeight;

    return (historicalAverageGross * historicalWeight) +
        (realAccessoriesGross * realWeight);
  }

  MonthlyAccessorySummary _buildMonthlySummary({
    required DateTime month,
    required List<Shift> allShifts,
    required UserPayProfile payProfile,
  }) {
    double nonOvertimeGross = 0;
    double overtimeGross = 0;
    double overtimeHours = 0;
    int shiftCount = 0;

    final monthShifts = allShifts.where((shift) {
  return shift.serviceDate.year == month.year &&
      shift.serviceDate.month == month.month;
});

    for (final shift in monthShifts) {
      shiftCount++;

            final breakdown = shift.getSalaryBreakdown(payProfile);

      for (final item in breakdown) {
        final label = (item['label'] as String? ?? '').toUpperCase().trim();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

        if (amount <= 0) continue;

        if (_isOvertimeLabel(label)) {
          overtimeGross += amount;
        } else {
          nonOvertimeGross += amount;
        }
      }

      overtimeHours += _extractShiftOvertimeHours(shift);
    }

    final totalGross = nonOvertimeGross + overtimeGross;

    return MonthlyAccessorySummary(
      month: month,
      shiftCount: shiftCount,
      nonOvertimeGross: _sanitizeMoney(nonOvertimeGross),
      overtimeGross: _sanitizeMoney(overtimeGross),
      overtimeHours: _sanitizeNonNegative(overtimeHours),
      totalGross: _sanitizeMoney(totalGross),
    );
  }

  _HistoricalCalibrationSnapshot _buildHistoricalCalibrationSnapshot(
    List<PayslipParsedData> payslips,
  ) {
    final valid = payslips
        .where((payslip) => !payslip.isSupplementaryPayslip)
        .toList();

    if (valid.isEmpty) {
      return const _HistoricalCalibrationSnapshot(
        averageNet: 0,
        averageGross: 0,
        averageFixedGross: 0,
        averageAccessoryGross: 0,
        averagePrevidenziali: 0,
        averageFiscali: 0,
        averageOtherDeductions: 0,
        averageConguagli: 0,
        averageAccessoryTaxRate: 0.26,
        averageFixedNetRatio: 0.78,
      );
    }

    double sumNet = 0;
    double sumGross = 0;
    double sumFixedGross = 0;
    double sumAccessoryGross = 0;
    double sumPrevidenziali = 0;
    double sumFiscali = 0;
    double sumOther = 0;
    double sumConguagli = 0;
    double sumAccessoryTaxRate = 0;
    double sumFixedNetRatio = 0;

    for (final payslip in valid) {
      final fixedGross = _sanitizeMoney(
        payslip.summaryFixedPay +
            payslip.summaryOtherAllowances +
            payslip.summaryThirteenth,
      );

      final accessoryGross = _sanitizeMoney(
        payslip.summaryAccessoryPay > 0
            ? payslip.summaryAccessoryPay
            : payslip.detectedOperationalAccessoryTotal,
      );

      final gross = _sanitizeMoney(fixedGross + accessoryGross);

      final accessoryTaxRate = payslip.effectiveTaxRateForEngine > 0
          ? _clamp(
              payslip.effectiveTaxRateForEngine,
              min: 0.20,
              max: 0.35,
            )
          : 0.26;

      final accessoryNetEstimated = _sanitizeMoney(
        accessoryGross * (1 - accessoryTaxRate),
      );

      double fixedNetEstimated = _sanitizeMoney(
        payslip.totaleNetto - accessoryNetEstimated,
      );

      if (fixedNetEstimated < 0) {
        fixedNetEstimated = 0;
      }

      final fixedNetRatio = fixedGross > 0
          ? _clamp(
              fixedNetEstimated / fixedGross,
              min: 0.55,
              max: 0.90,
            )
          : 0.78;

      sumNet += _sanitizeMoney(payslip.totaleNetto);
      sumGross += gross;
      sumFixedGross += fixedGross;
      sumAccessoryGross += accessoryGross;
      sumPrevidenziali += _sanitizeMoney(payslip.summaryPrevidenziali);
      sumFiscali += _sanitizeMoney(payslip.summaryFiscali);
      sumOther += _sanitizeMoney(payslip.summaryOtherDeductions);
      sumConguagli += _sanitizeMoney(payslip.summaryConguagli);
      sumAccessoryTaxRate += accessoryTaxRate;
      sumFixedNetRatio += fixedNetRatio;
    }

    final count = valid.length.toDouble();

    return _HistoricalCalibrationSnapshot(
      averageNet: sumNet / count,
      averageGross: sumGross / count,
      averageFixedGross: sumFixedGross / count,
      averageAccessoryGross: sumAccessoryGross / count,
      averagePrevidenziali: sumPrevidenziali / count,
      averageFiscali: sumFiscali / count,
      averageOtherDeductions: sumOther / count,
      averageConguagli: sumConguagli / count,
      averageAccessoryTaxRate: sumAccessoryTaxRate / count,
      averageFixedNetRatio: sumFixedNetRatio / count,
    );
  }

  _DeductionShares _deriveDeductionShares(
    _HistoricalCalibrationSnapshot historical,
  ) {
    final totalHistoricalDeductions = _sanitizeMoney(
      historical.averagePrevidenziali +
          historical.averageFiscali +
          historical.averageOtherDeductions +
          historical.averageConguagli,
    );

    if (totalHistoricalDeductions <= 0) {
      return const _DeductionShares(
        previdShare: 0.35,
        fiscalShare: 0.45,
        otherShare: 0.15,
        conguagliShare: 0.05,
      );
    }

    final previd =
        historical.averagePrevidenziali / totalHistoricalDeductions;
    final fiscal = historical.averageFiscali / totalHistoricalDeductions;
    final other =
        historical.averageOtherDeductions / totalHistoricalDeductions;
    final conguagli =
        historical.averageConguagli / totalHistoricalDeductions;

    final sum = previd + fiscal + other + conguagli;

    if (sum <= 0) {
      return const _DeductionShares(
        previdShare: 0.35,
        fiscalShare: 0.45,
        otherShare: 0.15,
        conguagliShare: 0.05,
      );
    }

    return _DeductionShares(
      previdShare: previd / sum,
      fiscalShare: fiscal / sum,
      otherShare: other / sum,
      conguagliShare: conguagli / sum,
    );
  }

  bool _isOvertimeLabel(String label) {
    return label.contains('STRAORD') ||
        label.contains('STRAORDINARIO') ||
        label.contains('STR.') ||
        label.contains('ST01') ||
        label.contains('ST02') ||
        label.contains('ST03') ||
        label.contains('A01B/');
  }

  double _extractShiftOvertimeHours(Shift shift) {
    final raw = shift.overtimeHours;
    if (raw.isNaN || !raw.isFinite || raw < 0) return 0;
    return raw;
  }

  double _estimateBasketPaymentGross({
    required double hours,
    required List<Shift> allShifts,
    required UserPayProfile payProfile,
  }) {
    if (hours <= 0) return 0;

    double totalOvertimeGross = 0;
    double totalOvertimeHours = 0;

    for (final shift in allShifts) {
      final breakdown = shift.getBreakdown(payProfile);

      for (final item in breakdown) {
        final label = (item['label'] as String? ?? '').toUpperCase().trim();
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

        if (amount <= 0) continue;
        if (_isOvertimeLabel(label)) {
          totalOvertimeGross += amount;
        }
      }

      totalOvertimeHours += _extractShiftOvertimeHours(shift);
    }

    if (totalOvertimeHours > 0 && totalOvertimeGross > 0) {
      return hours * (totalOvertimeGross / totalOvertimeHours);
    }

    final fallbackRate = payProfile.overtimeNightOrHolidayRate > 0
        ? payProfile.overtimeNightOrHolidayRate
        : 14.49;

    return hours * fallbackRate;
  }

    DateTime? _findFirstShiftMonth(List<Shift> allShifts) {
    if (allShifts.isEmpty) return null;

    final sorted = [...allShifts]
      ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));

    final first = sorted.first.serviceDate;
    return DateTime(first.year, first.month);
  }

  List<DateTime> _buildMonthsUpTo({
    required DateTime startMonth,
    required DateTime targetMonth,
  }) {
    if (_isAfterMonth(startMonth, targetMonth)) {
      return [targetMonth];
    }

    final result = <DateTime>[];
    var current = DateTime(startMonth.year, startMonth.month);

    while (!_isAfterMonth(current, targetMonth)) {
      result.add(current);
      current = DateTime(current.year, current.month + 1);
    }

    return result;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isBeforeMonth(DateTime a, DateTime b) {
    if (a.year < b.year) return true;
    if (a.year > b.year) return false;
    return a.month < b.month;
  }

  bool _isAfterMonth(DateTime a, DateTime b) {
    if (a.year > b.year) return true;
    if (a.year < b.year) return false;
    return a.month > b.month;
  }

  double _clamp(
    double value, {
    required double min,
    required double max,
  }) {
    if (value.isNaN || !value.isFinite) return min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  double _sanitizeMoney(double value) {
    if (value.isNaN || !value.isFinite) return 0;
    return value;
  }

  double _sanitizeNonNegative(double value) {
    if (value.isNaN || !value.isFinite) return 0;
    if (value < 0) return 0;
    return value;
  }
}