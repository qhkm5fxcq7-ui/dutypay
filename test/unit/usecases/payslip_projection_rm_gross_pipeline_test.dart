import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_projection_service.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_parser_service.dart';
import 'package:dutypay/features/shifts/presentation/models/department.dart';
import 'package:dutypay/features/shifts/presentation/models/shift.dart';
import 'package:dutypay/features/shifts/presentation/models/user_pay_profile.dart';

void main() {
  const service = PayslipProjectionService();
  const parser = PayslipParserService();

  UserPayProfile _buildProfile() {
    const rawText = '''
RATA: Febbraio 2026
ID CEDOLINO: ABC12345
Inquad.: ASSISTENTE CAPO Tipo rapporto
Qualifica: Q1
Totale netto: 1.850,00
Imponibile AC: 400,00
IRPEF AC: 104,00
Aliquota massima: 26,00
Imponibile AP: 1.900,00
IRPEF AP: 410,00
Aliquota media: 21,58

Competenze fisse
Stipendio 1.500,00
Altri assegni 120,00
Tredicesima 0,00

Assegniaccessori
A01B/1234STRAORDINARIO DIURNO-Qta.2,00-Imp.13,50-Rif.02/202627,00
A01B/1235STRAORDINARIO NOTTURNO O FESTIVO-Qta.2,00-Imp.18,00-Rif.02/202636,00
A01B/1236STRAORDINARIO NOTTURNO E FESTIVO-Qta.2,00-Imp.20,00-Rif.02/202640,00

Ritenute
Previdenziali 150,00
Fiscali 220,00
Altre ritenute 35,00

Conguagli fiscali e previdenziali
Totale 0,00
''';

    final parsed = parser.parsePayslipText(
      filePath: '/tmp/cedolino_febbraio_2026.pdf',
      rawText: rawText,
    );

    final profile = parser.buildDynamicProfile([parsed]);

    return UserPayProfile(
      monthlyOvertimePayableHoursLimit: profile.monthlyOvertimePayableHoursLimit,
      rank: profile.rank,
      overtimeDayRate: 13.50,
      overtimeNightOrHolidayRate: 18.00,
      overtimeNightAndHolidayRate: 20.00,
      orderPublicInSede: 13.00,
      orderPublicFuoriSede: profile.orderPublicFuoriSede,
      orderPublicPernotto: profile.orderPublicPernotto,
      externalServiceRate: profile.externalServiceRate,
      controlloTerritorioSerale: profile.controlloTerritorioSerale,
      controlloTerritorioNotturno: profile.controlloTerritorioNotturno,
      holidayAllowance: profile.holidayAllowance,
      specialHolidayAllowance: profile.specialHolidayAllowance,
      profileVersion: profile.profileVersion,
      calibratedAt: profile.calibratedAt,
      sourceWindowLabel: profile.sourceWindowLabel,
      detectedGradeLabel: profile.detectedGradeLabel,
      detectedBaseSalary: 1620.0,
      averageAccessoryPay: profile.averageAccessoryPay,
      historicalAccessoryAvg: null,
      historicalHoursAvg: null,
      historicalMonths: profile.historicalMonths,
      recurringDeductionsTotal: 0.0,
      effectiveTaxRate: 0.26,
      sourcePayslips: profile.sourcePayslips,
      annualProductionBonus: profile.annualProductionBonus,
      genereDiConfortoRate: profile.genereDiConfortoRate,
      ticketPastoRate: profile.ticketPastoRate,
    );
  }

  List<Shift> _buildShifts() {
    return [
      Shift(
        description: 'RM overtime + OP + benefits',
        start: DateTime(2026, 3, 10, 17, 0),
        end: DateTime(2026, 3, 11, 1, 0),
        serviceDate: DateTime(2026, 3, 10),
        absence: 'Nessuna',
        orderPublic: 'In sede',
        externalService: false,
        genereDiConforto: true,
        ticketPasto: true,
      ),
      Shift(
        description: 'RM only OP',
        start: DateTime(2026, 3, 15, 6, 0),
        end: DateTime(2026, 3, 15, 12, 0),
        serviceDate: DateTime(2026, 3, 15),
        absence: 'Nessuna',
        orderPublic: 'In sede',
        externalService: false,
      ),
    ];
  }

  group('Payslip RM gross pipeline', () {
    test('accessories enter as gross and are netted only at final projection stage', () {
      final profile = _buildProfile();
      final shifts = _buildShifts();

      final result = service.projectPayslip(
        payslipMonth: DateTime(2026, 5, 1),
        allShifts: shifts,
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(result.nonOvertimeGross, greaterThanOrEqualTo(0));
      expect(result.overtimeGrossFromReferenceMonth, greaterThanOrEqualTo(0));
      expect(result.accessoriesGrossLiquidated, greaterThanOrEqualTo(0));
      expect(result.accessoriesGrossUsedForEstimate, greaterThanOrEqualTo(0));
      expect(result.accessoriesNetEstimated, greaterThanOrEqualTo(0));

      expect(
        result.accessoriesGrossUsedForEstimate >= result.accessoriesNetEstimated,
        isTrue,
      );

      expect(
        result.accessoriesGrossLiquidated,
        closeTo(
          result.nonOvertimeGross +
              result.basketRecoveredGross +
              result.liquidatedOvertimeGross,
          0.01,
        ),
      );

      expect(result.rfiBasketGrossFromReferenceMonth, 0.0);
      expect(result.manualRfiBasketPaidGrossForMonth, 0.0);
    });
  });
}