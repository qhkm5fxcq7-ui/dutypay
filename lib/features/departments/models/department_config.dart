import 'allowance_config.dart';
import 'shift_rules.dart';

class DepartmentConfig {
  final String id;
  final String label;

  final List<AllowanceConfig> allowances;
  final ShiftRules shiftRules;

  const DepartmentConfig({
    required this.id,
    required this.label,
    required this.allowances,
    required this.shiftRules,
  });
}