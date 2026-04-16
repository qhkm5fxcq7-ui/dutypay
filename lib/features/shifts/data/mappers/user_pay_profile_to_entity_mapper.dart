import '../../domain/entities/user_pay_profile_entity.dart';
import '../../presentation/models/user_pay_profile.dart';

class UserPayProfileToEntityMapper {
  const UserPayProfileToEntityMapper();

  UserPayProfileEntity map(UserPayProfile profile) {
    return UserPayProfileEntity(
      overtimeDayRate: profile.overtimeDayRate,
      overtimeNightOrHolidayRate: profile.overtimeNightOrHolidayRate,
      overtimeNightAndHolidayRate: profile.overtimeNightAndHolidayRate,
      orderPublicInSede: profile.orderPublicInSede,
      orderPublicFuoriSede: profile.orderPublicFuoriSede,
      orderPublicPernotto: profile.orderPublicPernotto,
      externalServiceRate: profile.externalServiceRate,
      controlloTerritorioSerale: profile.controlloTerritorioSerale,
      controlloTerritorioNotturno: profile.controlloTerritorioNotturno,
      holidayAllowance: profile.holidayAllowance,
      specialHolidayAllowance: profile.specialHolidayAllowance,
      genereDiConfortoRate: profile.genereDiConfortoRate,
      ticketPastoRate: profile.ticketPastoRate,
      straordinarioNetMultiplier: profile.straordinarioNetMultiplier,
      monthlyOvertimePayableHoursLimit:
          profile.monthlyOvertimePayableHoursLimit,
    );
  }
}