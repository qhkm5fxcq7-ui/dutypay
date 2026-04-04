class AllowanceCalculationInput {
  final double workedHours;
  final double dayHours;
  final double nightHours;
  final bool isNightShift;
  final bool sendToBasket;

  const AllowanceCalculationInput({
    required this.workedHours,
    required this.dayHours,
    required this.nightHours,
    required this.isNightShift,
    required this.sendToBasket,
  });
}