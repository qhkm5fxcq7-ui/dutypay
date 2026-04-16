import 'shift_time_helper.dart';

class TimeBandHelper {
  const TimeBandHelper._();

  static bool isNightMoment(DateTime moment) {
    final minutes = moment.hour * 60 + moment.minute;
    return minutes >= 22 * 60 || minutes < 6 * 60;
  }

  static DateTime nextBoundary(DateTime current, DateTime limit) {
    final midnightNext = DateTime(
      current.year,
      current.month,
      current.day,
    ).add(const Duration(days: 1));

    final sixAm = DateTime(current.year, current.month, current.day, 6, 0);
    final tenPm = DateTime(current.year, current.month, current.day, 22, 0);

    final candidates = <DateTime>[
      limit,
      midnightNext,
      sixAm,
      tenPm,
    ].where((d) => d.isAfter(current)).toList()
      ..sort();

    return candidates.first;
  }

  static double calculateBandHours(
    DateTime rangeStart,
    DateTime rangeEnd, {
    required bool dayBand,
  }) {
    if (!rangeEnd.isAfter(rangeStart)) return 0.0;

    double totalMinutes = 0.0;
    var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final lastDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

    while (!cursor.isAfter(lastDay)) {
      final dayStart = DateTime(cursor.year, cursor.month, cursor.day, 6, 0);
      final dayEnd = DateTime(cursor.year, cursor.month, cursor.day, 22, 0);

      if (dayBand) {
        totalMinutes += ShiftTimeHelper.overlapMinutes(
          rangeStart,
          rangeEnd,
          dayStart,
          dayEnd,
        );
      } else {
        final nightPart1Start =
            DateTime(cursor.year, cursor.month, cursor.day, 0, 0);
        final nightPart1End =
            DateTime(cursor.year, cursor.month, cursor.day, 6, 0);

        final nightPart2Start =
            DateTime(cursor.year, cursor.month, cursor.day, 22, 0);
        final nightPart2End = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
        ).add(const Duration(days: 1));

        totalMinutes += ShiftTimeHelper.overlapMinutes(
          rangeStart,
          rangeEnd,
          nightPart1Start,
          nightPart1End,
        );
        totalMinutes += ShiftTimeHelper.overlapMinutes(
          rangeStart,
          rangeEnd,
          nightPart2Start,
          nightPart2End,
        );
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return totalMinutes / 60.0;
  }

  static double calculateNightOnlyHours(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return calculateBandHours(
      rangeStart,
      rangeEnd,
      dayBand: false,
    );
  }
}