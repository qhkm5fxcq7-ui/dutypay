import '../../domain/entities/department_type.dart';
import '../../domain/entities/shift_entity.dart';
import '../../presentation/models/shift.dart';

class ShiftToEntityMapper {
  const ShiftToEntityMapper();

  ShiftEntity map({
    required Shift shift,
    required DepartmentType department,
  }) {
    return ShiftEntity(
      id: _buildId(shift),
      department: department,
      start: shift.start,
      end: shift.end,
      serviceDate: shift.serviceDate,
      description: shift.description,
      absence: shift.absence,
      externalService: shift.externalService,
      orderPublic: shift.orderPublic,
      mealTicket: shift.ticketPasto,
      comfortItem: shift.genereDiConforto,
      comfortItemCdg: shift.genereDiConfortoCdg,
      manualExtraAmount: shift.manualExtraAmount,
      manualExtraLabel: shift.manualExtraLabel,
      note: shift.note,
      spmnPresetCode: shift.spmnPresetCode,
      polferScaloMode: shift.polferScaloMode.name,
      polferTerritoryControlType: shift.polferTerritoryControlType.name,
      polferScaloManualOverride: shift.polferScaloManualOverride,
      polferScaloReducedDayHours: shift.polferScaloReducedDayHours,
      polferScaloReducedNightHours: shift.polferScaloReducedNightHours,
      polferScaloFullDayHours: shift.polferScaloFullDayHours,
      polferScaloFullNightHours: shift.polferScaloFullNightHours,
    );
  }

  String _buildId(Shift shift) {
    return '${shift.start.toIso8601String()}__${shift.end.toIso8601String()}__${shift.serviceDate.toIso8601String()}';
  }
}