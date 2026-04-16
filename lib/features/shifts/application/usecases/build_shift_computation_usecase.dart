import '../../presentation/models/department.dart';
import '../../presentation/models/shift.dart';
import '../../presentation/models/user_pay_profile.dart';
import '../../domain/engine/models/shift_calculation_result.dart';
import 'calculate_shift_usecase.dart';

class BuildShiftComputationUseCase {
  const BuildShiftComputationUseCase();

  ShiftComputationViewData execute({
    required Shift shift,
    required UserPayProfile profile,
    required Department department,
  }) {
    if (shift.absence != 'Nessuna') {
      return const ShiftComputationViewData(
        overtimeHours: 0.0,
        totalAmount: 0.0,
        extraAmount: 0.0,
        breakdown: [],
      );
    }

    const calculateShiftUseCase = CalculateShiftUseCase();

    final calculation = calculateShiftUseCase.execute(
      shift: shift,
      profile: profile,
      department: department,
    );

    switch (department) {
      case Department.repartoMobile:
        return _buildRepartoMobileViewData(
          shift: shift,
          profile: profile,
          result: calculation,
        );

      case Department.polfer:
        return _buildPolferViewData(
          shift: shift,
          profile: profile,
          result: calculation,
        );
    }
  }

  // Source of truth:
  // - primary overtime and breakdown logic must come from DepartmentPolicy
  // - Shift legacy helpers may be used only for transitional accessory items
  // - never reintroduce legacy overtime fallback here
  ShiftComputationViewData _buildRepartoMobileViewData({
    required Shift shift,
    required UserPayProfile profile,
    required ShiftCalculationResult result,
  }) {
    final breakdown = _appendTransitionalAccessoryItems(
      breakdown: [...result.breakdown],
      shift: shift,
      profile: profile,
    );

    final totalAmount = _sumBreakdown(breakdown);

    final extraAmount = breakdown
        .where((item) => item['category'] != 'order_public')
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );

    return ShiftComputationViewData(
      overtimeHours: result.overtimeHours,
      totalAmount: totalAmount,
      extraAmount: extraAmount,
      breakdown: breakdown,
    );
  }

  // Source of truth:
  // - primary overtime and breakdown logic must come from DepartmentPolicy
  // - Shift legacy helpers may be used only for transitional accessory items
  // - never reintroduce legacy overtime fallback here
  ShiftComputationViewData _buildPolferViewData({
    required Shift shift,
    required UserPayProfile profile,
    required ShiftCalculationResult result,
  }) {
    final breakdown = _appendTransitionalAccessoryItems(
      breakdown: [...result.breakdown],
      shift: shift,
      profile: profile,
    );

    final totalAmount = _sumBreakdown(breakdown);

    final extraAmount = breakdown
        .where(
          (item) =>
              item['category'] != 'order_public' &&
              item['isBasketItem'] != true,
        )
        .fold<double>(
          0.0,
          (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
        );
        

    return ShiftComputationViewData(
      overtimeHours: result.overtimeHours,
      totalAmount: totalAmount,
      extraAmount: extraAmount,
      breakdown: breakdown,
    );
  }

  List<Map<String, dynamic>> _appendTransitionalAccessoryItems({
    required List<Map<String, dynamic>> breakdown,
    required Shift shift,
    required UserPayProfile profile,
  }) {
    final orderPublicAmount = shift.getOrderPublicAmount(profile);
    final externalServiceAmount = shift.getExternalServiceAmount(profile);
    final festiveAmount = shift.getFestiveAmount(profile);
    final specialHolidayAmount = shift.getSpecialHolidayAmount(profile);
    final comfortCdgAmount = shift.getGenereDiConfortoCdgAmount(profile);
    final comfortAmount = shift.getGenereDiConfortoAmount(profile);
    final mealAmount = shift.getTicketPastoAmount(profile);
    final manualAmount = shift.getManualExtraAmount();

    if (orderPublicAmount > 0) {
      breakdown.add({
        'label': 'Ordine pubblico ${shift.effectiveOrderPublicLabel}',
        'amount': orderPublicAmount,
        'category': 'order_public',
      });
    }

    if (externalServiceAmount > 0) {
      breakdown.add({
        'label': 'Indennità presenza servizi esterni',
        'amount': externalServiceAmount,
        'category': 'external_service',
      });
    }

    if (festiveAmount > 0) {
      breakdown.add({
        'label': 'Indennità servizio festivo',
        'amount': festiveAmount,
        'category': 'festive_service',
      });
    }

    if (specialHolidayAmount > 0) {
      breakdown.add({
        'label': 'Indennità festività particolare',
        'amount': specialHolidayAmount,
        'category': 'special_holiday',
      });
    }

            if (comfortCdgAmount > 0) {
      breakdown.add({
        'label': 'Genere di conforto CDG',
        'amount': 0.0,
        'benefitAmount': comfortCdgAmount,
        'category': 'comfort_cdg',
        'isBenefit': true,
      });
    }

    if (comfortAmount > 0) {
      breakdown.add({
        'label': 'Genere di conforto',
        'amount': 0.0,
        'benefitAmount': comfortAmount,
        'category': 'comfort',
        'isBenefit': true,
      });
    }

    if (mealAmount > 0) {
      breakdown.add({
        'label': 'Ticket pasto',
        'amount': 0.0,
        'benefitAmount': mealAmount,
        'category': 'ticket_meal',
        'isBenefit': true,
      });
    }

    if (manualAmount > 0) {
      breakdown.add({
        'label': shift.effectiveManualExtraLabel,
        'amount': manualAmount,
        'category': 'manual_extra',
      });
    }

    if (shift.hasCompensazione) {
  breakdown.add({
    'label': 'Compensazione',
    'amount': 12.0,
    'category': 'compensazione',
  });
}

if (shift.hasReperibilita) {
  breakdown.add({
    'label': 'Reperibilità',
    'amount': 17.5,
    'category': 'reperibilita',
  });
}

    return breakdown;
  }

  double _sumBreakdown(List<Map<String, dynamic>> breakdown) {
    return breakdown.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }
}

class ShiftComputationViewData {
  final double overtimeHours;
  final double totalAmount;
  final double extraAmount;
  final List<Map<String, dynamic>> breakdown;

  const ShiftComputationViewData({
    required this.overtimeHours,
    required this.totalAmount,
    required this.extraAmount,
    required this.breakdown,
  });

  factory ShiftComputationViewData.fromEngine(
    ShiftCalculationResult result,
  ) {
    return ShiftComputationViewData(
      overtimeHours: result.overtimeHours,
      totalAmount: result.totalGross,
      extraAmount: result.totalGross,
      breakdown: result.breakdown,
    );
  }
}