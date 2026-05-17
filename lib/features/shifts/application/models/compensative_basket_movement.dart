enum CompensativeBasketMovementType {
  earned,
  recovered,
  adjustment,
}

class CompensativeBasketMovement {
  final String id;

  final DateTime month;

  final CompensativeBasketMovementType type;

  final double hours;

  final String note;

  final DateTime createdAt;

  const CompensativeBasketMovement({
    required this.id,
    required this.month,
    required this.type,
    required this.hours,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'month': month.toIso8601String(),
    'type': type.name,
    'hours': hours,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };
}

factory CompensativeBasketMovement.fromJson(
  Map<String, dynamic> json,
) {
  return CompensativeBasketMovement(
    id: json['id'] as String? ?? '',
    month: DateTime.parse(json['month'] as String),
    type: CompensativeBasketMovementType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => CompensativeBasketMovementType.adjustment,
    ),
    hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
    note: json['note'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
}