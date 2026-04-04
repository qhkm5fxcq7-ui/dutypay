class MonthlyAllowanceSummary {
  final double totalMonthAmount;
  final double totalBasketAmount;
  final double totalAmount;

  final Map<String, double> totalsByAllowanceId;

  final int totalShifts;
  final double totalWorkedHours;

  const MonthlyAllowanceSummary({
    required this.totalMonthAmount,
    required this.totalBasketAmount,
    required this.totalAmount,
    required this.totalsByAllowanceId,
    required this.totalShifts,
    required this.totalWorkedHours,
  });
}