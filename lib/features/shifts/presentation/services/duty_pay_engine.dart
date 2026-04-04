import '../models/payslip_extract_result.dart';
import '../models/user_pay_profile.dart';
import '../../../departments/models/allowance_payroll_impact.dart';

class DutyPayEngine {
  const DutyPayEngine();

  DutyPayEngineSnapshot buildSnapshot(
  UserPayProfile profile, {
  AllowancePayrollImpact? allowancePayrollImpact,
}) {
    final baseGrossMonthly = profile.detectedBaseSalary;
final legacyOperationalAccessoriesGross = profile.averageAccessoryPay;
final v2MonthlyAllowancesGross =
    allowancePayrollImpact?.monthlyAllowanceTotal ?? 0.0;
final averageOperationalAccessoriesGross =
    legacyOperationalAccessoriesGross + v2MonthlyAllowancesGross;
final recurringRealDeductions = profile.recurringDeductionsTotal;

final grossTotal = baseGrossMonthly + averageOperationalAccessoriesGross;

    final estimatedTaxAmount = grossTotal * profile.effectiveTaxRate;
    final estimatedNetBeforeRealDeductions = grossTotal - estimatedTaxAmount;
    final estimatedNetAfterRealDeductions =
        estimatedNetBeforeRealDeductions - recurringRealDeductions;

    final observedNets = profile.sourcePayslips
        .map((p) => p.totaleNetto)
        .where((v) => v > 0)
        .toList();

    final averageObservedNet = observedNets.isEmpty
        ? estimatedNetAfterRealDeductions
        : observedNets.reduce((a, b) => a + b) / observedNets.length;

    final averageDeltaFromObservedNet =
        estimatedNetAfterRealDeductions - averageObservedNet;

    final topOperationalComponents = _buildTopOperationalComponents(
      profile.sourcePayslips,
    );

    return DutyPayEngineSnapshot(
      baseGrossMonthly: baseGrossMonthly,
      averageOperationalAccessoriesGross: averageOperationalAccessoriesGross,
      v2MonthlyAllowancesGross: v2MonthlyAllowancesGross,
      recurringRealDeductions: recurringRealDeductions,
      estimatedTaxAmount: estimatedTaxAmount,
      estimatedNetBeforeRealDeductions: estimatedNetBeforeRealDeductions,
      estimatedNetAfterRealDeductions: estimatedNetAfterRealDeductions,
      averageObservedNet: averageObservedNet,
      averageDeltaFromObservedNet: averageDeltaFromObservedNet,
      topOperationalComponents: topOperationalComponents,
    );
  }

  List<DutyPayEngineComponent> _buildTopOperationalComponents(
    List<PayslipParsedData> payslips,
  ) {
    if (payslips.isEmpty) return const [];

    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final payslip in payslips) {
      for (final entry in payslip.operationalAccessoryEntries) {
        final label = _normalizeOperationalLabel(entry);

        if (label == null || label.isEmpty) {
          continue;
        }

        totals[label] = (totals[label] ?? 0) + entry.amount;
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }

    final components = <DutyPayEngineComponent>[];

    for (final item in totals.entries) {
      final count = counts[item.key] ?? 1;
      components.add(
        DutyPayEngineComponent(
          label: item.key,
          grossAmount: item.value / count,
        ),
      );
    }

    components.sort((a, b) => b.grossAmount.compareTo(a.grossAmount));
    return components.take(8).toList();
  }

  String? _normalizeOperationalLabel(PayslipEntry entry) {
    final code = entry.code.trim().toUpperCase();
    final raw = entry.description.trim();

    if (raw.isEmpty) return null;
    if (_looksLikeGarbage(raw)) return null;

    if (code == 'AA01/ST01' || code == 'A01B/0007' || code == 'STS0/ST01') {
      return 'Straordinario diurno';
    }

    if (code == 'AA01/ST02' || code == 'A01B/0008') {
      return 'Straordinario notturno o festivo';
    }

    if (code == 'AA01/ST03' || code == 'A01B/0009') {
      return 'Straordinario notturno e festivo';
    }

    if (code == 'B003/0001') {
      return 'Ordine pubblico in sede';
    }

    if (code == 'B003/0003') {
      return 'Ordine pubblico fuori sede 1 turno';
    }

    if (code == 'AA06/E1BJ') {
      return 'Indennita servizio festivo';
    }

    if (code == 'AA06/E1BL') {
      return 'Indennita servizio notturno';
    }

    if (code == 'AA06/E1BM') {
      return 'Indennita di compensazione';
    }

    if (code == 'AA06/E1BV') {
      return 'Indennita festivita particolari';
    }

    if (code == 'AA06/E1BW') {
      return 'Indennita presenza servizi esterni';
    }

    final cleaned = _cleanDescription(raw);
    if (cleaned.isEmpty || _looksLikeGarbage(cleaned)) {
      return null;
    }

    return cleaned;
  }

  bool _looksLikeGarbage(String value) {
    final upper = value.toUpperCase();

    const forbiddenFragments = [
      'CREDITO EMILIANO',
      'CORSO SEMPIONE',
      'VALUTA/ESIGIBILITA',
      'DATI RIEPILOGATIVI',
      'ANAGRAFICA',
      'CODICE FISCALE',
      'UFFICIO SERVIZIO',
      'ENTE DI APPARTENENZA',
      'RATA:',
      'ID CEDOLINO',
      'DETRAZIONI',
      'COGNOME:',
      'NOME:',
      'TOTALE NETTO',
      'IMPORTI PROGRESSIVI',
      'IRPEF',
      'IMPIBILE',
      'IMONIBILE',
      'PAG.',
    ];

    for (final fragment in forbiddenFragments) {
      if (upper.contains(fragment)) return true;
    }

    if (value.length > 80) return true;

    return false;
  }

  String _cleanDescription(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll("'", '')
        .trim();
  }
}

class DutyPayEngineSnapshot {
  final double baseGrossMonthly;
  final double averageOperationalAccessoriesGross;
  final double recurringRealDeductions;
  final double estimatedTaxAmount;
  final double estimatedNetBeforeRealDeductions;
  final double estimatedNetAfterRealDeductions;
  final double averageObservedNet;
  final double averageDeltaFromObservedNet;
  final double v2MonthlyAllowancesGross;
  final List<DutyPayEngineComponent> topOperationalComponents;

  const DutyPayEngineSnapshot({
    required this.baseGrossMonthly,
    required this.averageOperationalAccessoriesGross,
    required this.recurringRealDeductions,
    required this.estimatedTaxAmount,
    required this.estimatedNetBeforeRealDeductions,
    required this.estimatedNetAfterRealDeductions,
    required this.averageObservedNet,
    required this.averageDeltaFromObservedNet,
    required this.topOperationalComponents,
    required this.v2MonthlyAllowancesGross,
  });
}

class DutyPayEngineComponent {
  final String label;
  final double grossAmount;

  const DutyPayEngineComponent({
    required this.label,
    required this.grossAmount,
  });
}