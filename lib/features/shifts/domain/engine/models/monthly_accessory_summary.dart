class MonthlyAccessorySummary {
  final DateTime month;
  final int shiftCount;
  final double nonOvertimeGross;
  final double overtimeGross;
  final double overtimeHours;
  final double rfiBasketGross;
  final double totalGross;

  const MonthlyAccessorySummary({
    required this.month,
    required this.shiftCount,
    required this.nonOvertimeGross,
    required this.overtimeGross,
    required this.overtimeHours,
    required this.rfiBasketGross,
    required this.totalGross,
  });
}