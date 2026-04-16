class DateClassificationHelper {
  const DateClassificationHelper._();

  static bool isHolidayDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final isSunday = normalized.weekday == DateTime.sunday;
    final isSuperHoliday = matchesAnyDate(
      normalized,
      superHolidayDates(normalized.year),
    );
    return isSunday || isSuperHoliday;
  }

  static bool matchesAnyDate(DateTime date, List<DateTime> dates) {
    return dates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  static List<DateTime> superHolidayDates(int year) {
    final easter = calculateEasterSunday(year);
    final easterMonday = easter.add(const Duration(days: 1));

    return [
      DateTime(year, 1, 1),
      DateTime(year, 1, 6),
      easter,
      easterMonday,
      DateTime(year, 5, 1),
      DateTime(year, 6, 2),
      DateTime(year, 8, 15),
      DateTime(year, 12, 25),
      DateTime(year, 12, 26),
    ];
  }

  static DateTime calculateEasterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }
}