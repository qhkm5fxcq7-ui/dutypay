import 'basket_carry_entry.dart';
import 'rfi_basket_open_entry.dart';
import 'rfi_basket_paid_entry.dart';

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
  final double rfiBasketGrossFromReferenceMonth;
  final double rfiBasketHoursFromReferenceMonth;

  final double basketRecoveredGross;
  final double basketRecoveredHours;

  final double liquidatedOvertimeGross;
  final double liquidatedOvertimeHours;

  final double overtimeInBasketGross;
  final double overtimeInBasketHours;

  final double accessoriesGrossLiquidated;
  final double accessoriesGrossUsedForEstimate;
  final double accessoriesNetEstimated;
  final bool isUsingHistoricalAccessories;

  final double estimatedPrevidenziali;
  final double estimatedFiscali;
  final double estimatedOtherDeductions;
  final double estimatedConguagli;
  final double totalEstimatedDeductions;

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
  final double rfiMaturedHoursForMonth;
final double rfiMaturedGrossForMonth;

  final List<BasketCarryEntry> openBasketEntries;
  final List<RfiBasketOpenEntry> openRfiBasketEntries;
  final List<RfiBasketPaidEntry> paidRfiBasketEntries;

  final double currentBasketResidualHours;
  final double currentBasketResidualGrossEstimate;
  final double manualBasketPaidHoursForMonth;
  final double manualBasketPaidGrossForMonth;

  final double currentRfiBasketResidualHours;
  final double currentRfiBasketResidualGrossEstimate;
  final double manualRfiBasketPaidHoursForMonth;
  final double manualRfiBasketPaidGrossForMonth;

  final double recurringDeductionsApplied;
  final double differenceFromEstimatedPayslip;

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
    required this.rfiBasketGrossFromReferenceMonth,
    required this.rfiBasketHoursFromReferenceMonth,
    required this.basketRecoveredGross,
    required this.basketRecoveredHours,
    required this.liquidatedOvertimeGross,
    required this.liquidatedOvertimeHours,
    required this.overtimeInBasketGross,
    required this.overtimeInBasketHours,
    required this.accessoriesGrossLiquidated,
    required this.accessoriesGrossUsedForEstimate,
    required this.accessoriesNetEstimated,
    required this.isUsingHistoricalAccessories,
    required this.estimatedPrevidenziali,
    required this.estimatedFiscali,
    required this.estimatedOtherDeductions,
    required this.estimatedConguagli,
    required this.totalEstimatedDeductions,
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
    required this.openRfiBasketEntries,
    required this.paidRfiBasketEntries,
    required this.currentBasketResidualHours,
    required this.currentBasketResidualGrossEstimate,
    required this.manualBasketPaidHoursForMonth,
    required this.manualBasketPaidGrossForMonth,
    required this.currentRfiBasketResidualHours,
    required this.currentRfiBasketResidualGrossEstimate,
    required this.manualRfiBasketPaidHoursForMonth,
    required this.manualRfiBasketPaidGrossForMonth,
    required this.recurringDeductionsApplied,
    required this.differenceFromEstimatedPayslip,
    required this.rfiMaturedHoursForMonth,
required this.rfiMaturedGrossForMonth,
  });

  bool get hasReferenceMonthData => referenceMonthShiftCount > 0;

  bool get hasAnyBasketMovement =>
      basketRecoveredGross > 0 ||
      liquidatedOvertimeGross > 0 ||
      overtimeInBasketGross > 0 ||
      openBasketEntries.isNotEmpty ||
      manualBasketPaidHoursForMonth > 0;

  bool get hasAnyRfiBasketMovement =>
      rfiBasketGrossFromReferenceMonth > 0 ||
      openRfiBasketEntries.isNotEmpty ||
      paidRfiBasketEntries.isNotEmpty ||
      manualRfiBasketPaidGrossForMonth > 0;

  double get extraGross => accessoriesGrossUsedForEstimate;
  double get extraNet => accessoriesNetEstimated;
  double get rfiBasketGross => rfiBasketGrossFromReferenceMonth;

  double get taxes => extraGross - extraNet;
}