import '../models/department.dart';
import '../models/shift.dart';
import '../models/user_pay_profile.dart';
import '../../application/usecases/build_monthly_accessory_summary_usecase.dart';
import '../../domain/engine/models/basket_carry_entry.dart';
import '../../domain/engine/models/rfi_basket_open_entry.dart';
import '../../domain/engine/models/rfi_basket_paid_entry.dart';
import '../../domain/engine/models/precision_status.dart';
import '../../domain/engine/models/payslip_projection_result.dart';
import '../../domain/engine/models/basket_payment.dart';
import '../../domain/engine/models/rfi_basket_payment.dart';
import '../../domain/engine/models/overtime_basket_adjustment.dart';
import '../../application/models/monthly_accessory_summary.dart';

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

class _BasketEntryWorking {
  final DateTime sourceMonth;
  double grossRemaining;
  double hoursRemaining;

  _BasketEntryWorking({
    required this.sourceMonth,
    required this.grossRemaining,
    required this.hoursRemaining,
  });
}

class PayslipProjectionService {
  const PayslipProjectionService();

  static const int _historicalAccessoriesThreshold = 5;

  BuildMonthlyAccessorySummaryUseCase get _monthlySummaryUseCase =>
      const BuildMonthlyAccessorySummaryUseCase();

  PayslipProjectionResult projectPayslip({
    required DateTime payslipMonth,
    required List<Shift> allShifts,
    required UserPayProfile payProfile,
    required Department department,
    List<BasketPayment> basketPayments = const [],
List<OvertimeBasketAdjustment> overtimeBasketAdjustments = const [],
List<RfiBasketPayment> rfiBasketPayments = const [],
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

    final basketStartMonth = _findFirstShiftMonth(allShifts);

    final relevantMonths = accessoryReferenceMonth == null
        ? <DateTime>[]
        : basketStartMonth == null
            ? <DateTime>[accessoryReferenceMonth]
            : _buildMonthsUpTo(
                startMonth: basketStartMonth,
                targetMonth: accessoryReferenceMonth,
              );

    final List<MonthlyAccessorySummary> monthlySummaries = relevantMonths
    .map<MonthlyAccessorySummary>(
      (month) => _monthlySummaryUseCase.execute(
        month: month,
        allShifts: allShifts,
        profile: payProfile,
        department: department,
      ),
    )
    .toList();

        final rfiRelevantMonths = basketStartMonth == null
        ? <DateTime>[normalizedPayslipMonth]
        : _buildMonthsUpTo(
            startMonth: basketStartMonth,
            targetMonth: normalizedPayslipMonth,
          );

    final List<MonthlyAccessorySummary> rfiMonthlySummaries = rfiRelevantMonths
        .map<MonthlyAccessorySummary>(
          (month) => _monthlySummaryUseCase.execute(
            month: month,
            allShifts: allShifts,
            profile: payProfile,
            department: department,
          ),
        )
        .toList();

    final MonthlyAccessorySummary referenceSummary =
    accessoryReferenceMonth == null
        ? MonthlyAccessorySummary(
            month: normalizedPayslipMonth,
            shiftCount: 0,
            nonOvertimeGross: 0,
            overtimeGross: 0,
            overtimeHours: 0,
            rfiBasketGross: 0,
            totalGross: 0,
          )
        : monthlySummaries.firstWhere(
            (item) => _isSameMonth(item.month, accessoryReferenceMonth),
            orElse: () => MonthlyAccessorySummary(
              month: accessoryReferenceMonth,
              shiftCount: 0,
              nonOvertimeGross: 0,
              overtimeGross: 0,
              overtimeHours: 0,
              rfiBasketGross: 0,
              totalGross: 0,
            ),
          );

    final List<MonthlyAccessorySummary> previousMonths =
    accessoryReferenceMonth == null
        ? <MonthlyAccessorySummary>[]
        : monthlySummaries
            .where(
              (item) => _isBeforeMonth(item.month, accessoryReferenceMonth),
            )
            .toList();

    double remainingCapacityHours = overtimeHoursLimit;
    double basketRecoveredGross = 0.0;
    double basketRecoveredHours = 0.0;
    final openBasketEntries = <BasketCarryEntry>[];

    for (final monthSummary in previousMonths) {
      if (monthSummary.overtimeHours <= 0 || monthSummary.overtimeGross <= 0) {
        continue;
      }

      if (remainingCapacityHours <= 0) {
        openBasketEntries.add(
          BasketCarryEntry(
            sourceMonth: monthSummary.month,
            overtimeGrossRemaining: _sanitizeMoney(monthSummary.overtimeGross),
            overtimeHoursRemaining: _sanitizeNonNegative(
              monthSummary.overtimeHours,
            ),
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
            overtimeGrossRemaining: _sanitizeMoney(residualGross),
            overtimeHoursRemaining: _sanitizeNonNegative(residualHours),
          ),
        );
      }
    }

    double liquidatedOvertimeHours = 0.0;
    double liquidatedOvertimeGross = 0.0;
    double overtimeInBasketHours = 0.0;
    double overtimeInBasketGross = 0.0;

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
          overtimeGrossRemaining: _sanitizeMoney(overtimeInBasketGross),
          overtimeHoursRemaining: _sanitizeNonNegative(overtimeInBasketHours),
        ),
      );
    }

    final workingBasketEntries = openBasketEntries
        .map(
          (e) => _BasketEntryWorking(
            sourceMonth: e.sourceMonth,
            grossRemaining: e.overtimeGrossRemaining,
            hoursRemaining: e.overtimeHoursRemaining,
          ),
        )
        .toList()
      ..sort((a, b) => a.sourceMonth.compareTo(b.sourceMonth));

    final sortedBasketPayments = [...basketPayments]
      ..sort((a, b) => a.paymentMonth.compareTo(b.paymentMonth));

    double manualBasketPaidHoursForMonth = 0.0;
double manualBasketPaidGrossForMonth = 0.0;
double unappliedBasketPaymentHours = 0.0;
double unappliedBasketPaymentHoursForMonth = 0.0;

for (final payment in sortedBasketPayments) {
  if (_isAfterMonth(payment.paymentMonth, normalizedPayslipMonth)) {
    continue;
  }

  double remainingHoursToApply = payment.hoursPaid;
  double grossAppliedForThisPayment = 0.0;

  for (final entry in workingBasketEntries) {
    if (remainingHoursToApply <= 0) break;
    if (entry.hoursRemaining <= 0 || entry.grossRemaining <= 0) continue;

    final grossPerHour = entry.hoursRemaining > 0
        ? entry.grossRemaining / entry.hoursRemaining
        : 0.0;

    if (grossPerHour <= 0) continue;

    final appliedHours = remainingHoursToApply <= entry.hoursRemaining
        ? remainingHoursToApply
        : entry.hoursRemaining;

    final appliedGross = appliedHours * grossPerHour;

    entry.hoursRemaining -= appliedHours;
    entry.grossRemaining -= appliedGross;
    remainingHoursToApply -= appliedHours;
    grossAppliedForThisPayment += appliedGross;
  }

  if (_isSameMonth(payment.paymentMonth, normalizedPayslipMonth)) {
    manualBasketPaidHoursForMonth +=
        payment.hoursPaid - remainingHoursToApply;
    manualBasketPaidGrossForMonth += grossAppliedForThisPayment;
  }

  if (remainingHoursToApply > 0) {
    unappliedBasketPaymentHours += remainingHoursToApply;

    if (_isSameMonth(payment.paymentMonth, normalizedPayslipMonth)) {
      unappliedBasketPaymentHoursForMonth += remainingHoursToApply;
    }
  }
}

final currentBasketResidualHours = workingBasketEntries.fold<double>(
  0.0,
  (sum, item) => sum + _sanitizeNonNegative(item.hoursRemaining),
);

final currentBasketResidualGrossEstimate = workingBasketEntries.fold<double>(
  0.0,
  (sum, item) => sum + _sanitizeMoney(item.grossRemaining),
);

final overtimeBasketAdjustmentHours = overtimeBasketAdjustments
    .where((item) => !_isAfterMonth(item.month, normalizedPayslipMonth))
    .fold<double>(
      0.0,
      (sum, item) => sum + item.hours,
    );

final positiveOvertimeBasketAdjustmentHours = overtimeBasketAdjustments
    .where(
      (item) =>
          !_isAfterMonth(item.month, normalizedPayslipMonth) &&
          item.hours > 0,
    )
    .fold<double>(
      0.0,
      (sum, item) => sum + item.hours,
    );

final negativeOvertimeBasketAdjustmentHoursForMonth = overtimeBasketAdjustments
    .where(
      (item) =>
          _isSameMonth(item.month, normalizedPayslipMonth) &&
          item.hours < 0,
    )
    .fold<double>(
      0.0,
      (sum, item) => sum + item.hours.abs(),
    );

final adjustedBasketRecoveredHours = _sanitizeNonNegative(
  basketRecoveredHours + positiveOvertimeBasketAdjustmentHours,
);

final adjustedBasketRecoveredGross = _sanitizeMoney(
  basketRecoveredGross +
      (positiveOvertimeBasketAdjustmentHours * payProfile.overtimeDayRate),
);

final adjustmentHoursConsumedByUnappliedPayments =
    unappliedBasketPaymentHours <= positiveOvertimeBasketAdjustmentHours
        ? unappliedBasketPaymentHours
        : positiveOvertimeBasketAdjustmentHours;

final adjustmentHoursConsumedThisMonth =
    unappliedBasketPaymentHoursForMonth <= positiveOvertimeBasketAdjustmentHours
        ? unappliedBasketPaymentHoursForMonth
        : positiveOvertimeBasketAdjustmentHours;
final adjustmentGrossConsumedThisMonth =
    adjustmentHoursConsumedThisMonth * payProfile.overtimeDayRate;                    

final adjustedCurrentBasketResidualHours = _sanitizeNonNegative(
  currentBasketResidualHours +
      overtimeBasketAdjustmentHours -
      adjustmentHoursConsumedByUnappliedPayments,
);

manualBasketPaidHoursForMonth +=
    adjustmentHoursConsumedThisMonth + negativeOvertimeBasketAdjustmentHoursForMonth;
manualBasketPaidGrossForMonth +=
    adjustmentGrossConsumedThisMonth +
    (negativeOvertimeBasketAdjustmentHoursForMonth * payProfile.overtimeDayRate);

final grossPerResidualHour = currentBasketResidualHours > 0
    ? currentBasketResidualGrossEstimate / currentBasketResidualHours
    : 0.0;

final effectiveBasketGrossPerHour = grossPerResidualHour > 0
    ? grossPerResidualHour
    : payProfile.overtimeDayRate;

final adjustedCurrentBasketResidualGrossEstimate = _sanitizeMoney(
  adjustedCurrentBasketResidualHours * effectiveBasketGrossPerHour,
);

final nonOvertimeGross = _sanitizeMoney(referenceSummary.nonOvertimeGross);

    final currentMonthRfiSummary = rfiMonthlySummaries.firstWhere(
      (item) => _isSameMonth(item.month, normalizedPayslipMonth),
      orElse: () => MonthlyAccessorySummary(
        month: normalizedPayslipMonth,
        shiftCount: 0,
        nonOvertimeGross: 0,
        overtimeGross: 0,
        overtimeHours: 0,
        rfiBasketGross: 0,
        totalGross: 0,
      ),
    );

    final rfiBasketGrossFromReferenceMonth = _sanitizeMoney(
      currentMonthRfiSummary.rfiBasketGross,
    );

    final rfiBasketHoursFromReferenceMonth =
        rfiBasketGrossFromReferenceMonth > 0 ? 1.0 : 0.0;

    final rfiMaturedHoursForMonth = rfiBasketHoursFromReferenceMonth;
    final rfiMaturedGrossForMonth = rfiBasketGrossFromReferenceMonth;

    final openRfiBasketEntries = <RfiBasketOpenEntry>[];
    final paidRfiBasketEntries = <RfiBasketPaidEntry>[];

    for (final monthSummary in rfiMonthlySummaries) {
      if (monthSummary.rfiBasketGross <= 0) continue;
      if (_isAfterMonth(monthSummary.month, normalizedPayslipMonth)) continue;

      final matchingPayment =
          rfiBasketPayments.cast<RfiBasketPayment?>().firstWhere(
        (item) =>
            item != null &&
            _isSameMonth(item.sourceMonth, monthSummary.month) &&
            !_isAfterMonth(item.paidInMonth, normalizedPayslipMonth),
        orElse: () => null,
      );

      if (matchingPayment == null) {
        openRfiBasketEntries.add(
          RfiBasketOpenEntry(
            sourceMonth: DateTime(
              monthSummary.month.year,
              monthSummary.month.month,
            ),
            grossAmount: _sanitizeMoney(monthSummary.rfiBasketGross),
          ),
        );
      } else {
        paidRfiBasketEntries.add(
          RfiBasketPaidEntry(
            sourceMonth: DateTime(
              monthSummary.month.year,
              monthSummary.month.month,
            ),
            paidInMonth: DateTime(
              matchingPayment.paidInMonth.year,
              matchingPayment.paidInMonth.month,
            ),
            grossAmount: _sanitizeMoney(monthSummary.rfiBasketGross),
            note: matchingPayment.note,
          ),
        );
      }
    }

    final currentRfiBasketResidualHours =
        openRfiBasketEntries.length.toDouble();

    final currentRfiBasketResidualGrossEstimate =
        openRfiBasketEntries.fold<double>(
      0.0,
      (sum, item) => sum + item.grossAmount,
    );

    final manualRfiBasketPaidHoursForMonth = paidRfiBasketEntries
        .where((e) => _isSameMonth(e.paidInMonth, normalizedPayslipMonth))
        .length
        .toDouble();

    final manualRfiBasketPaidGrossForMonth = paidRfiBasketEntries
        .where((e) => _isSameMonth(e.paidInMonth, normalizedPayslipMonth))
        .fold<double>(0.0, (sum, item) => sum + item.grossAmount);

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

    double historicalGrossFromNet = 0.0;

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

    final accessoriesGrossUsedForEstimate = _sanitizeMoney(
      accessoryReferenceMonth == null
          ? 0.0
          : hasManualHistoricalOverride &&
                  referenceSummary.shiftCount < _historicalAccessoriesThreshold
              ? historicalGrossFromNet
              : _calculateWeightedAccessoriesGross(
                  shiftsCount: referenceSummary.shiftCount,
                  realAccessoriesGross: accessoriesGrossLiquidated,
                  historicalAverageGross: historical.averageAccessoryGross,
                ),
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

    final recurringDeductionsApplied =
        _sanitizeMoney(payProfile.recurringDeductionsTotal);

    final estimatedPayslipTotal = _sanitizeMoney(
      fixedBaseNetEstimated +
          accessoriesNetEstimated -
          recurringDeductionsApplied,
    );

    final rfiPaidThisMonthGross = manualRfiBasketPaidGrossForMonth;

final accessoryNetRatio = 1 - accessoryTaxRate;

final rfiNet = _sanitizeMoney(
  rfiPaidThisMonthGross * accessoryNetRatio,
);

final totalNetWithRfi = _sanitizeMoney(
  estimatedPayslipTotal + rfiNet,
);

    final totalGrossProjected = _sanitizeMoney(
      fixedBaseGross + accessoriesGrossUsedForEstimate,
    );

    final totalEstimatedDeductions = _sanitizeMoney(
      totalGrossProjected - (fixedBaseNetEstimated + accessoriesNetEstimated),
    );

    final deductionShares = _deriveDeductionShares(historical);

    final estimatedPrevidenziali = _sanitizeMoney(
      totalEstimatedDeductions * deductionShares.previdShare,
    );

    final estimatedFiscali = _sanitizeMoney(
      totalEstimatedDeductions * deductionShares.fiscalShare,
    );

    final estimatedOtherDeductions = _sanitizeMoney(
      totalEstimatedDeductions * deductionShares.otherShare,
    );

    final estimatedConguagli = _sanitizeMoney(
      totalEstimatedDeductions * deductionShares.conguagliShare,
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
      rfiBasketGrossFromReferenceMonth: rfiBasketGrossFromReferenceMonth,
      rfiBasketHoursFromReferenceMonth: rfiBasketHoursFromReferenceMonth,
      basketRecoveredGross: adjustedBasketRecoveredGross,
basketRecoveredHours: adjustedBasketRecoveredHours,
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
      estimatedPayslipTotal: totalNetWithRfi,
      monthlyOvertimePayableHoursLimit: overtimeHoursLimit,
      historicalAverageNet: historical.averageNet,
      historicalAverageGross: historical.averageGross,
      historicalAverageFixedGross: historical.averageFixedGross,
      historicalAverageAccessoryGross: historical.averageAccessoryGross,
      historicalAveragePrevidenziali: historical.averagePrevidenziali,
      historicalAverageFiscali: historical.averageFiscali,
      historicalAverageOtherDeductions: historical.averageOtherDeductions,
      historicalAverageConguagli: historical.averageConguagli,
      rfiMaturedHoursForMonth: rfiMaturedHoursForMonth,
      rfiMaturedGrossForMonth: rfiMaturedGrossForMonth,
      openBasketEntries: workingBasketEntries
          .where((e) => e.hoursRemaining > 0.0001 && e.grossRemaining > 0.0001)
          .map(
            (e) => BasketCarryEntry(
              sourceMonth: e.sourceMonth,
              overtimeGrossRemaining: _sanitizeMoney(e.grossRemaining),
              overtimeHoursRemaining: _sanitizeNonNegative(e.hoursRemaining),
            ),
          )
          .toList(),
      openRfiBasketEntries: openRfiBasketEntries,
      paidRfiBasketEntries: paidRfiBasketEntries,
      currentBasketResidualHours:
    _sanitizeNonNegative(adjustedCurrentBasketResidualHours),
currentBasketResidualGrossEstimate:
    _sanitizeMoney(adjustedCurrentBasketResidualGrossEstimate),
      manualBasketPaidHoursForMonth:
          _sanitizeNonNegative(manualBasketPaidHoursForMonth),
      manualBasketPaidGrossForMonth:
          _sanitizeMoney(manualBasketPaidGrossForMonth),
      currentRfiBasketResidualHours:
          _sanitizeNonNegative(currentRfiBasketResidualHours),
      currentRfiBasketResidualGrossEstimate:
          _sanitizeMoney(currentRfiBasketResidualGrossEstimate),
      manualRfiBasketPaidHoursForMonth:
          _sanitizeNonNegative(manualRfiBasketPaidHoursForMonth),
      manualRfiBasketPaidGrossForMonth:
          _sanitizeMoney(manualRfiBasketPaidGrossForMonth),
      recurringDeductionsApplied: recurringDeductionsApplied,
      differenceFromEstimatedPayslip: 0.0,
    );
  }

  PrecisionStatus calculatePrecision({
    required List<Shift> allShifts,
  }) {
    final months = allShifts
        .map((shift) => DateTime(shift.start.year, shift.start.month))
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

    double sumNet = 0.0;
    double sumGross = 0.0;
    double sumFixedGross = 0.0;
    double sumAccessoryGross = 0.0;
    double sumPrevidenziali = 0.0;
    double sumFiscali = 0.0;
    double sumOther = 0.0;
    double sumConguagli = 0.0;
    double sumAccessoryTaxRate = 0.0;
    double sumFixedNetRatio = 0.0;

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

  DateTime? _findFirstShiftMonth(List<Shift> allShifts) {
    if (allShifts.isEmpty) return null;

    final sorted = [...allShifts]..sort((a, b) => a.start.compareTo(b.start));
    final first = sorted.first.start;
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
    if (value.isNaN || !value.isFinite) return 0.0;
    return value;
  }

  double _sanitizeNonNegative(double value) {
    if (value.isNaN || !value.isFinite) return 0.0;
    if (value < 0) return 0.0;
    return value;
  }
}