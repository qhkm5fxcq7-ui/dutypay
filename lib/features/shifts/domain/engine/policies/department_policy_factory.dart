import '../../entities/department.dart';
import 'department_policy.dart';
import 'polfer_policy.dart';
import 'reparto_mobile_policy.dart';
import 'questura_policy.dart';

class DepartmentPolicyFactory {
  static DepartmentPolicy create(Department department) {
    switch (department) {
      case Department.repartoMobile:
        return RepartoMobilePolicy();
      case Department.polfer:
        return PolferPolicy();
      case Department.questura:
  return QuesturaPolicy();
    }
  }
}