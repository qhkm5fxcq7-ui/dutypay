class AllowanceSummary {
  final double totalMonthAmount;
  final double totalBasketAmount;
  final double totalAmount;
  final Map<String, double> totalsByAllowanceId;

  const AllowanceSummary({
    required this.totalMonthAmount,
    required this.totalBasketAmount,
    required this.totalAmount,
    required this.totalsByAllowanceId,
  });
}