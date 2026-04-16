class RfiBasketPaidEntry {
  final DateTime sourceMonth;
  final DateTime paidInMonth;
  final double grossAmount;
  final String note;

  const RfiBasketPaidEntry({
    required this.sourceMonth,
    required this.paidInMonth,
    required this.grossAmount,
    required this.note,
  });
}