enum PrecisionLevel {
  low,
  medium,
  high,
}

class PrecisionStatus {
  final PrecisionLevel level;
  final double percentage;

  const PrecisionStatus({
    required this.level,
    required this.percentage,
  });
}