class UserPayProfile {
  final double overtimeDayRate;
  final double overtimeNightOrHolidayRate;
  final double overtimeNightAndHolidayRate;
  final double overtimeNetMultiplier;

  const UserPayProfile({
    required this.overtimeDayRate,
    required this.overtimeNightOrHolidayRate,
    required this.overtimeNightAndHolidayRate,
    required this.overtimeNetMultiplier,
  });
}