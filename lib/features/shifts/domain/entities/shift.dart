enum PolferTerritoryControlType {
  none,
  serale,
  notturno,
}

enum PolferScaloMode {
  none,
  ridotta,
  intera,
}

class Shift {
  final String description;
  final DateTime start;
  final DateTime end;
  final DateTime serviceDate;

  final PolferTerritoryControlType polferTerritoryControlType;
  final PolferScaloMode polferScaloMode;
  final bool polferScaloManualOverride;
  final double polferScaloReducedDayHours;
  final double polferScaloReducedNightHours;
  final double polferScaloFullDayHours;
  final double polferScaloFullNightHours;
  final bool ordinaryHoursOverrideEnabled;
  final double ordinaryHoursOverride;
  final String ordinaryHoursOverrideNote;

  const Shift({
    required this.description,
    required this.start,
    required this.end,
    required this.serviceDate,
    this.polferTerritoryControlType = PolferTerritoryControlType.none,
    this.polferScaloMode = PolferScaloMode.none,
    this.polferScaloManualOverride = false,
    this.polferScaloReducedDayHours = 0.0,
    this.polferScaloReducedNightHours = 0.0,
    this.polferScaloFullDayHours = 0.0,
    this.polferScaloFullNightHours = 0.0,
    this.ordinaryHoursOverrideEnabled = false,
    this.ordinaryHoursOverride = 0.0,
    this.ordinaryHoursOverrideNote = '',
  });
}