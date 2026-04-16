class DailyShiftComputation {
  final double overtimeHours;
  final double totalAmount;
  final double extraAmount;
  final List<Map<String, dynamic>> breakdown;

  const DailyShiftComputation({
    required this.overtimeHours,
    required this.totalAmount,
    required this.extraAmount,
    required this.breakdown,
  });
}