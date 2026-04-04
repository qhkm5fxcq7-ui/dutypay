import '../models/allowance_payroll_impact.dart';
import '../models/monthly_allowance_summary.dart';

class AllowancePayrollAdapterService {
  const AllowancePayrollAdapterService();

  AllowancePayrollImpact buildPayrollImpact({
    required MonthlyAllowanceSummary summary,
  }) {
    return AllowancePayrollImpact(
      monthlyAllowanceTotal: summary.totalMonthAmount,
      basketAllowanceTotal: summary.totalBasketAmount,
      totalAllowanceAmount: summary.totalAmount,
    );
  }
}