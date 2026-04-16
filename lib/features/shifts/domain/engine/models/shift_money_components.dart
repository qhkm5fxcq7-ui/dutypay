class ShiftMoneyComponents {
  final double overtimeGross;
  final double overtimeHours;
  final double nonOvertimeGross;
  final double rfiBasketGross;

  const ShiftMoneyComponents({
    required this.overtimeGross,
    required this.overtimeHours,
    required this.nonOvertimeGross,
    required this.rfiBasketGross,
  });

  double get totalGross => nonOvertimeGross + overtimeGross + rfiBasketGross;
}