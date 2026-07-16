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

enum QuesturaMode {
  uffici,
  volanti,
}

enum QuesturaPreset {
  none,
  mattina,
  pomeriggio,
  sera,
  notte,
  smontante,
  riposo,
  aggiornamento,
}

enum QuesturaOfficeProfile {
  sixHours,
  settimanaCorta,
  settimanaLunga,
  custom,
}

class Shift {
  final String description;
  final DateTime start;
  final DateTime end;
  final DateTime serviceDate;
  final QuesturaMode questuraMode;
  final QuesturaPreset questuraPreset;
  final QuesturaOfficeProfile questuraOfficeProfile;
  final double questuraOfficeOrdinaryHours;

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
  final bool programmedOvertimeEnabled;
  final DateTime? programmedOvertimeStart;
  final DateTime? programmedOvertimeEnd;
  final String programmedOvertimeNote;

  const Shift({
    required this.description,
    required this.start,
    required this.end,
    required this.serviceDate,
    this.questuraMode = QuesturaMode.uffici,
    this.questuraPreset = QuesturaPreset.none,
    this.questuraOfficeProfile = QuesturaOfficeProfile.sixHours,
    this.questuraOfficeOrdinaryHours = 6.0,
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
    this.programmedOvertimeEnabled = false,
    this.programmedOvertimeStart,
    this.programmedOvertimeEnd,
    this.programmedOvertimeNote = '',
  });
}
