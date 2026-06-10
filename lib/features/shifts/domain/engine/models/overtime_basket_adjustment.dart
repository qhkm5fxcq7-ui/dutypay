class OvertimeBasketAdjustment {
  final String id;
  final DateTime month;
  final double hours;
  final String note;
  final DateTime createdAt;

  const OvertimeBasketAdjustment({
    required this.id,
    required this.month,
    required this.hours,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month.toIso8601String(),
      'hours': hours,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OvertimeBasketAdjustment.fromJson(Map<String, dynamic> json) {
    return OvertimeBasketAdjustment(
      id: json['id'] as String? ?? '',
      month: DateTime.parse(json['month'] as String),
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}