class RfiBasketPayment {
  final DateTime sourceMonth;
  final DateTime paidInMonth;
  final String note;

  const RfiBasketPayment({
    required this.sourceMonth,
    required this.paidInMonth,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceMonth': sourceMonth.toIso8601String(),
      'paidInMonth': paidInMonth.toIso8601String(),
      'note': note,
    };
  }

  factory RfiBasketPayment.fromJson(Map<String, dynamic> json) {
    return RfiBasketPayment(
      sourceMonth: DateTime.parse(json['sourceMonth'] as String),
      paidInMonth: DateTime.parse(json['paidInMonth'] as String),
      note: json['note'] as String? ?? '',
    );
  }
}