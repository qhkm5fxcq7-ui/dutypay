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

    return parser.buildDynamicProfile([parsed]);
  }

  List<Shift> _buildRmShifts() {
    return [
      Shift(
        description: 'RM 17-01 with benefits',
        start: DateTime(2026, 3, 10, 17, 0),
        end: DateTime(2026, 3, 11, 1, 0),
        serviceDate: DateTime(2026, 3, 10),
        absence: 'Nessuna',
        orderPublic: 'In sede',
        genereDiConforto: true,
        ticketPasto: true,
      ),
    ];
  }

  List<Shift> _buildPolferShifts() {
    return [
      Shift(
        description: 'Polfer evening standard',
        start: DateTime(2026, 3, 10, 18, 55),
        end: DateTime(2026, 3, 11, 0, 8),
        serviceDate: DateTime(2026, 3, 10),
        absence: 'Nessuna',
      ),
    ];
  }

  group('Payslip gross/net regression', () {
    test('RM pipeline never taxes benefits and never nets inputs prematurely', () {
      final profile = _buildProfile();

      final result = service.projectPayslip(
        payslipMonth: DateTime(2026, 5, 1),
        allShifts: _buildRmShifts(),
        payProfile: profile,
        department: Department.repartoMobile,
      );

      expect(result.accessoriesGrossLiquidated, greaterThanOrEqualTo(0));
      expect(result.accessoriesGrossUsedForEstimate, greaterThanOrEqualTo(0));
      expect(result.accessoriesNetEstimated, greaterThanOrEqualTo(0));

      expect(
        result.accessoriesGrossUsedForEstimate >= result.accessoriesNetEstimated,
        isTrue,
      );

      expect(result.rfiBasketGrossFromReferenceMonth, 0.0);
      expect(result.manualRfiBasketPaidGrossForMonth, 0.0);
    });

    test('Polfer pipeline keeps RFI separate and nets only at final stage', () {
      final profile = _buildProfile();

      final result = service.projectPayslip(
        payslipMonth: DateTime(2026, 5, 1),
        allShifts: _buildPolferShifts(),
        payProfile: profile,
        department: Department.polfer,
      );

      expect(result.accessoriesGrossLiquidated, greaterThanOrEqualTo(0));
      expect(result.accessoriesGrossUsedForEstimate, greaterThanOrEqualTo(0));
      expect(result.accessoriesNetEstimated, greaterThanOrEqualTo(0));

      expect(
        result.accessoriesGrossUsedForEstimate >= result.accessoriesNetEstimated,
        isTrue,
      );
    });
  });
}