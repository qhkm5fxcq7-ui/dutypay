class MonthlySummary {
  final double totalAmount;
  final double totalOvertimeHours;
  final int workedDays;
  final double averagePerDay;
  final double todayTotal;
  final double weekTotal;
  final int daysInMonth;
  final int remainingDays;
  final double projectedExtraFuture;
  final double rfiBasketAmount;

  const MonthlySummary({
    required this.totalAmount,
    required this.totalOvertimeHours,
    required this.workedDays,
    required this.averagePerDay,
    required this.todayTotal,
    required this.weekTotal,
    required this.daysInMonth,
    required this.remainingDays,
    required this.projectedExtraFuture,
    required this.rfiBasketAmount,
  });
}