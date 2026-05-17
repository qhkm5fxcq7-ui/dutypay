class CompensativeBasketSummary {
  final double earnedHours;
  final double recoveredHours;
  final double adjustmentHours;

  const CompensativeBasketSummary({
    required this.earnedHours,
    required this.recoveredHours,
    this.adjustmentHours = 0.0,
  });

  double get residualHours => earnedHours - recoveredHours + adjustmentHours;
}