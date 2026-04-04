class AllowanceCalculationResult {
  final String allowanceId;
  final String allowanceName;
  final double amount;
  final bool goesToBasket;

  const AllowanceCalculationResult({
    required this.allowanceId,
    required this.allowanceName,
    required this.amount,
    required this.goesToBasket,
  });
}