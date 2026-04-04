import '../allowance_config.dart';
import '../department_config.dart';
import '../shift_rules.dart';

class DepartmentCatalog {
  static const DepartmentConfig repartoMobile = DepartmentConfig(
    id: 'polizia_mobile',
    label: 'Reparto Mobile',
    allowances: [
      AllowanceConfig(
        id: 'ordine_pubblico',
        name: 'Ordine Pubblico',
        type: AllowanceType.daily,
        dayRate: 6.00,
        defaultToBasket: false,
      ),
      AllowanceConfig(
        id: 'servizio_esterno',
        name: 'Servizio Esterno',
        type: AllowanceType.daily,
        dayRate: 10.00,
        defaultToBasket: false,
      ),
    ],
    shiftRules: ShiftRules(
      hasNightDifferentiation: true,
      hasHolidayBonus: true,
      hasExternalService: true,
    ),
  );

  static const DepartmentConfig polfer = DepartmentConfig(
    id: 'polizia_polfer',
    label: 'Polfer',
    allowances: [
      AllowanceConfig(
        id: 'scalo_ferroviario',
        name: 'Scalo Ferroviario',
        type: AllowanceType.hourly,
        dayRate: 1.00,
        nightRate: 2.50,
        defaultToBasket: true,
      ),
      AllowanceConfig(
        id: 'servizio_esterno',
        name: 'Servizio Esterno',
        type: AllowanceType.daily,
        dayRate: 10.00,
        defaultToBasket: false,
      ),
    ],
    shiftRules: ShiftRules(
      hasNightDifferentiation: true,
      hasHolidayBonus: true,
      hasExternalService: true,
    ),
  );

  static const List<DepartmentConfig> departments = [
    repartoMobile,
    polfer,
  ];

  static DepartmentConfig? getById(String id) {
    try {
      return departments.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<String> defaultSelectedAllowanceIds(String departmentId) {
    switch (departmentId) {
      case 'polizia_polfer':
        return ['scalo_ferroviario', 'servizio_esterno'];
      case 'polizia_mobile':
      default:
        return ['ordine_pubblico', 'servizio_esterno'];
    }
  }
}