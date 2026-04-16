class ShiftCalculationResult {
  final double workedHours;
  final double ordinaryHours;
  final double overtimeHours;
  final double nightOrdinaryHours;
  final double overtimeDayHours;
  final double overtimeNightHours;
  final double overtimeHolidayDayHours;
  final double overtimeNightHolidayHours;
  final double totalAmount;
  final double extraAmount;
  final List<Map<String, dynamic>> breakdown;

  const ShiftCalculationResult({
    required this.workedHours,
    required this.ordinaryHours,
    required this.overtimeHours,
    required this.nightOrdinaryHours,
    required this.overtimeDayHours,
    required this.overtimeNightHours,
    required this.overtimeHolidayDayHours,
    required this.overtimeNightHolidayHours,
    required this.totalAmount,
    required this.extraAmount,
    required this.breakdown,
  });

  double get totalGross => totalAmount;
  double get totalNet => totalAmount;

  factory ShiftCalculationResult.empty() {
    return const ShiftCalculationResult(
      workedHours: 0.0,
      ordinaryHours: 0.0,
      overtimeHours: 0.0,
      nightOrdinaryHours: 0.0,
      overtimeDayHours: 0.0,
      overtimeNightHours: 0.0,
      overtimeHolidayDayHours: 0.0,
      overtimeNightHolidayHours: 0.0,
      totalAmount: 0.0,
      extraAmount: 0.0,
      breakdown: [],
    );
  }
}