class ShiftTimeHelper {
  const ShiftTimeHelper._();

  static DateTime normalizedEnd(DateTime start, DateTime end) {
    if (end.isAfter(start)) return end;
    return end.add(const Duration(days: 1));
  }

  static double calculateWorkedHours(DateTime start, DateTime end) {
    final normalized = normalizedEnd(start, end);
    final minutes = normalized.difference(start).inMinutes;
    if (minutes <= 0) return 0.0;
    return minutes / 60.0;
  }

  static double overlapMinutes(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    if (!end.isAfter(start)) return 0.0;
    return end.difference(start).inMinutes.toDouble();
  }

  static bool crossesMidnight(DateTime start, DateTime end) {
    final normalized = normalizedEnd(start, end);
    return normalized.day != start.day ||
        normalized.month != start.month ||
        normalized.year != start.year;
  }
}