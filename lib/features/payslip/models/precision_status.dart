enum PrecisionLevel {
  low,     // 0-1 mesi
  medium,  // 2 mesi
  high,    // 3+ mesi
}

class PrecisionStatus {
  final PrecisionLevel level;
  final double percentage; // 0 → 100

  const PrecisionStatus({
    required this.level,
    required this.percentage,
  });
}