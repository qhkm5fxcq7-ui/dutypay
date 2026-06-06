import '../../presentation/models/department.dart' as presentation_department;
import '../../presentation/models/shift.dart' as presentation_shift;
import '../../presentation/models/user_pay_profile.dart' as presentation_profile;

import '../../domain/entities/department.dart' as domain_department;
import '../../domain/entities/shift.dart' as domain_shift;
import '../../domain/entities/user_pay_profile.dart' as domain_profile;
import '../../domain/engine/models/shift_calculation_result.dart';
import '../../domain/engine/policies/department_policy_factory.dart';

class CalculateShiftUseCase {
  const CalculateShiftUseCase();

  ShiftCalculationResult execute({
    required presentation_shift.Shift shift,
    required presentation_profile.UserPayProfile profile,
    required presentation_department.Department department,
  }) {
    if (shift.absence != 'Nessuna') {
      return ShiftCalculationResult.empty();
    }

    final policy = DepartmentPolicyFactory.create(
      _mapDepartment(department),
    );

    return policy.calculateShift(
      domain_shift.Shift(
        description: shift.description,
        start: shift.start,
        end: shift.end,
        serviceDate: shift.serviceDate,
        questuraMode: _mapQuesturaMode(shift.questuraMode),
questuraPreset: _mapQuesturaPreset(shift.questuraPreset),
questuraOfficeProfile:
    _mapQuesturaOfficeProfile(shift.questuraOfficeProfile),
questuraOfficeOrdinaryHours: shift.questuraOfficeOrdinaryHours,
programmedOvertimeEnabled: shift.programmedOvertimeEnabled,
programmedOvertimeStart: shift.programmedOvertimeStart,
programmedOvertimeEnd: shift.programmedOvertimeEnd,
programmedOvertimeNote: shift.programmedOvertimeNote,
        polferTerritoryControlType: _mapPolferTerritoryControlType(
          shift.polferTerritoryControlType,
        ),
        polferScaloMode: _mapPolferScaloMode(
          shift.polferScaloMode,
        ),
        polferScaloManualOverride: shift.polferScaloManualOverride,
        polferScaloReducedDayHours: shift.polferScaloReducedDayHours,
        polferScaloReducedNightHours: shift.polferScaloReducedNightHours,
        polferScaloFullDayHours: shift.polferScaloFullDayHours,
        polferScaloFullNightHours: shift.polferScaloFullNightHours,
        ordinaryHoursOverrideEnabled:
    shift.ordinaryHoursOverrideEnabled,
ordinaryHoursOverride:
    shift.ordinaryHoursOverride,
ordinaryHoursOverrideNote:
    shift.ordinaryHoursOverrideNote,
      ),
      domain_profile.UserPayProfile(
        overtimeDayRate: profile.overtimeDayRate,
        overtimeNightOrHolidayRate: profile.overtimeNightOrHolidayRate,
        overtimeNightAndHolidayRate: profile.overtimeNightAndHolidayRate,
        overtimeNetMultiplier: profile.straordinarioNetMultiplier,
      ),
    );
  }

  domain_department.Department _mapDepartment(
  presentation_department.Department department,
) {
  switch (department) {
    case presentation_department.Department.repartoMobile:
      return domain_department.Department.repartoMobile;

    case presentation_department.Department.polfer:
      return domain_department.Department.polfer;

    case presentation_department.Department.questura:
      return domain_department.Department.questura;
  }
}

  domain_shift.PolferTerritoryControlType _mapPolferTerritoryControlType(
    presentation_shift.PolferTerritoryControlType value,
  ) {
    switch (value) {
      case presentation_shift.PolferTerritoryControlType.none:
        return domain_shift.PolferTerritoryControlType.none;
      case presentation_shift.PolferTerritoryControlType.serale:
        return domain_shift.PolferTerritoryControlType.serale;
      case presentation_shift.PolferTerritoryControlType.notturno:
        return domain_shift.PolferTerritoryControlType.notturno;
    }
  }

  domain_shift.PolferScaloMode _mapPolferScaloMode(
    presentation_shift.PolferScaloMode value,
  ) {
    switch (value) {
      case presentation_shift.PolferScaloMode.none:
        return domain_shift.PolferScaloMode.none;
      case presentation_shift.PolferScaloMode.ridotta:
        return domain_shift.PolferScaloMode.ridotta;
      case presentation_shift.PolferScaloMode.intera:
        return domain_shift.PolferScaloMode.intera;
    }
  }
  domain_shift.QuesturaMode _mapQuesturaMode(
  presentation_shift.QuesturaMode value,
) {
  switch (value) {
    case presentation_shift.QuesturaMode.uffici:
      return domain_shift.QuesturaMode.uffici;
    case presentation_shift.QuesturaMode.volanti:
      return domain_shift.QuesturaMode.volanti;
  }
}

domain_shift.QuesturaPreset _mapQuesturaPreset(
  presentation_shift.QuesturaPreset value,
) {
  switch (value) {
    case presentation_shift.QuesturaPreset.none:
      return domain_shift.QuesturaPreset.none;
    case presentation_shift.QuesturaPreset.mattina:
      return domain_shift.QuesturaPreset.mattina;
    case presentation_shift.QuesturaPreset.pomeriggio:
      return domain_shift.QuesturaPreset.pomeriggio;
    case presentation_shift.QuesturaPreset.sera:
      return domain_shift.QuesturaPreset.sera;
    case presentation_shift.QuesturaPreset.notte:
      return domain_shift.QuesturaPreset.notte;
    case presentation_shift.QuesturaPreset.smontante:
      return domain_shift.QuesturaPreset.smontante;
    case presentation_shift.QuesturaPreset.riposo:
      return domain_shift.QuesturaPreset.riposo;
    case presentation_shift.QuesturaPreset.aggiornamento:
      return domain_shift.QuesturaPreset.aggiornamento;
  }
}

domain_shift.QuesturaOfficeProfile _mapQuesturaOfficeProfile(
  presentation_shift.QuesturaOfficeProfile value,
) {
  switch (value) {
    case presentation_shift.QuesturaOfficeProfile.sixHours:
      return domain_shift.QuesturaOfficeProfile.sixHours;
    case presentation_shift.QuesturaOfficeProfile.settimanaCorta:
      return domain_shift.QuesturaOfficeProfile.settimanaCorta;
    case presentation_shift.QuesturaOfficeProfile.settimanaLunga:
      return domain_shift.QuesturaOfficeProfile.settimanaLunga;
    case presentation_shift.QuesturaOfficeProfile.custom:
      return domain_shift.QuesturaOfficeProfile.custom;
  }
}
}