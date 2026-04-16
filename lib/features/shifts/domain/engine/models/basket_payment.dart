class BasketPayment {
  final DateTime paymentMonth;
  final double hoursPaid;
  final String note;

  const BasketPayment({
    required this.paymentMonth,
    required this.hoursPaid,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentMonth': paymentMonth.toIso8601String(),
      'hoursPaid': hoursPaid,
      'note': note,
    };
  }

  factory BasketPayment.fromJson(Map<String, dynamic> json) {
    return BasketPayment(
      paymentMonth: DateTime.parse(json['paymentMonth'] as String),
      hoursPaid: (json['hoursPaid'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String? ?? '',
    );
  }
}