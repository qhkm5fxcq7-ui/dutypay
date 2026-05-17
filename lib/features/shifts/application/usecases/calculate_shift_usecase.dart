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
      case presentation_department.Department.questura:
        return domain_department.Department.repartoMobile;
      case presentation_department.Department.polfer:
        return domain_department.Department.polfer;
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
}