import 'package:flutter_test/flutter_test.dart';
import 'package:dutypay/features/shifts/presentation/services/payslip_parser_service.dart';

void main() {
  const parser = PayslipParserService();

  const rmMarchRealText = '''
RATA: Marzo 2026 ID CEDOLINO: 194CD9AE
Posizione giuridico-economica
Inquad.: VICE SOVRINTENDENTE E EQUIP. Tipo rapporto: Tempo indeterminato Qualifica: MS04
Tipo Liquidaz.: TFS Parametro: 116,75 Cassa previdenza: INPDAP

DATI RIEPILOGATIVI DELLA RETRIBUZIONE
Descrizione Ritenute Competenze
Competenze fisse Stipendio 1.902,05
Altri assegni 1.002,43
Competenze accessorie Assegni accessori 1.360,61
Ritenute Previdenziali 448,33
Fiscali 919,09
Altre ritenute 10,38
Conguagli fiscali e previdenziali Totale 111,00

Totale netto: 2.776,30
Quinto cedibile: 383,36
Imponibile AC: 9.883,73 IRPEF AC: 2.345,68 Aliquota massima: 33,00
Imponibile AP: 1.486,50 IRPEF AP: 392,73 Aliquota media: 26,42

DATI DI DETTAGLIO DELLA RETRIBUZIONE
Cod. Descrizione Ritenute Competenze
Competenze fisse
STIPENDIO
MS04 STIPENDIO TABELLARE 1.371,13
750/813 IIS CONGLOBATA MS04 530,92
ALTRI ASSEGNI
129/MR3 IND.VACANZA CONTRATTUALE 19,02
200/SR1 IND.PENS.MENS. MS04 - MR03 833,39
257/SR1 ASSEGNO FUNZIONALE 17 ANNI-SOVRINTENDENTE/REVISORE 150,02

Competenze accessorie
Assegni accessori
B003/0002 ORD.PUBBL. F. SEDE INTERA - Qta. 1,00 - Imp. 26,00 - Rif. 01/2026 10,51
B003/0001 ORD.PUBBL. IN SEDE - Qta. 17,00 - Imp. 13,00 - Rif. 01/2026 221,00
B003/0002 ORD.PUBBL. F. SEDE INTERA - Qta. 1,00 - Imp. 26,00 - Rif. 01/2026 15,49
B003/0003 ORD.PUBBL. F. SEDE 1 TURNO - Qta. 5,00 - Imp. 18,20 - Rif. 01/2026 91,00
AA06/E1BL INDENNITA' SERVIZIO NOTTURNO - Qta. 9,00 - Imp. 4,30 - Rif. 01/2026 38,70
AA06/E1BJ INDENNITA' SERVIZIO FESTIVO - Qta. 4,00 - Imp. 14,00 - Rif. 01/2026 56,00
AA06/E1BM INDENNITA' DI COMPENSAZIONE - Qta. 3,00 - Imp. 12,00 - Rif. 01/2026 36,00
AA06/E1BV INDENNITA' PER FESTIVITA' PARTICOLARI - Qta. 1,00 - Imp. 40,00 - Rif. 01/2026 40,00
AA01/ST01 STRAORDINARIO DIURNO - Qta. 5,00 - Imp. 13,35 - Rif. 01/2026 66,75
AA01/ST02 STRAORDINARIO NOTTURNO O FESTIVO - Qta. 2,00 - Imp. 15,10 - Rif. 01/2026 30,20
AA01/ST03 STRAORDINARIO NOTTURNO E FESTIVO - Qta. 1,00 - Imp. 17,42 - Rif. 01/2026 17,42
A01B/0008 STR. NOTT O FEST REP. MOBILI ENTRO LIMITE MAX IND. - Qta. 35,00 - Imp. 15,10 - Rif. 01/2026 528,50
A01B/0009 STR. NOTT FEST REP. MOBILI ENTRO LIMITE MAX IND. - Qta. 12,00 - Imp. 17,42 - Rif. 01/2026 209,04

Ritenute
PREVIDENZIALI Imponibile Aliquota Importo
Totale ritenute previdenziali 448,33
FISCALI Imponibile Aliquota Importo
Totale ritenute fiscali al netto delle detrazioni 919,09
ALTRE RITENUTE
800/S7J RITENUTA SINDACALE 9,78
800/FPS FONDO ASSISTENZA POLIZIA DI STATO 0,60
Conguagli fiscali e previdenziali
800/A03 ADDIZ.REG.IRPEF(COD.FIN.10 LOMBARDIA) scad. 11/2026 74,14
800/CC1 ADDIZIONALE COMUNALE - SALDO scad. 11/2026 25,83
800/CC0 ADDIZIONALE COMUNALE - ACCONTO scad. 11/2026 11,03
''';

  const rmFebruaryRealText = '''
RATA: Febbraio 2026 ID CEDOLINO: 192CCD3D
Posizione giuridico-economica
Inquad.: ASSISTENTE Tipo rapporto: Tempo indeterminato Qualifica: MA03
Tipo Liquidaz.: TFS Parametro: 112,00 Cassa previdenza: INPDAP

DATI RIEPILOGATIVI DELLA RETRIBUZIONE
Descrizione Ritenute Competenze
Competenze fisse
Stipendio 1.824,67
Altri assegni 712,31
Competenze accessorie
Assegni accessori 1.596,39
Ritenute
Previdenziali 435,39
Fiscali 858,06
Altre ritenute 254,26
Conguagli fiscali e previdenziali
Totale 117,74

Totale netto: 2.703,40
Quinto cedibile: 360,76
Imponibile AC: 5.293,01 IRPEF AC: 1.133,30 Aliquota massima: 33,00
Imponibile AP: 593,06 IRPEF AP: 152,65 Aliquota media: 25,74

DATI DI DETTAGLIO DELLA RETRIBUZIONE
Cod. Descrizione Ritenute Competenze
Competenze fisse
STIPENDIO
MA03 STIPENDIO TABELLARE 1.298,18
750/816 IIS CONGLOBATA MA03 526,49
ALTRI ASSEGNI
129/MA3 IND.VACANZA CONTRATTUALE 18,25
200/AB3 IND.PENS.MENS. MA03 - MB02 694,06

Competenze accessorie
Assegni accessori
STS0/ST01 STR ORE SUPERO DIURNO - Qta. 18,00 - Imp. 12,80 - Rif. 02/2024 230,40
STS0/ST01 STR ORE SUPERO DIURNO - Qta. 4,00 - Imp. 12,80 - Rif. 01/2024 51,20
STS0/ST01 STR ORE SUPERO DIURNO - Qta. 13,00 - Imp. 12,80 - Rif. 02/2024 166,40
STS0/ST01 STR ORE SUPERO DIURNO - Qta. 16,00 - Imp. 12,80 - Rif. 03/2024 204,80
B003/0001 ORD.PUBBL. IN SEDE - Qta. 9,00 - Imp. 13,00 - Rif. 12/2025 117,00
B003/0003 ORD.PUBBL. F. SEDE 1 TURNO - Qta. 3,00 - Imp. 18,20 - Rif. 12/2025 54,60
AA06/E1BJ INDENNITA' SERVIZIO FESTIVO - Qta. 4,00 - Imp. 14,00 - Rif. 12/2025 56,00
AA06/E1BL INDENNITA' SERVIZIO NOTTURNO - Qta. 27,00 - Imp. 4,30 - Rif. 12/2025 116,10
AA06/E1BM INDENNITA' DI COMPENSAZIONE - Qta. 3,00 - Imp. 12,00 - Rif. 12/2025 36,00
AA06/E1BW INDENNITA' PRESENZA SERVIZI ESTERNI - Qta. 3,00 - Imp. 6,00 - Rif. 12/2025 18,00
A01B/0007 STR. FERIALE REPARTI MOBILI ENTRO LIMITE MAX IND. - Qta. 9,00 - Imp. 12,80 - Rif. 12/2025 115,20
A01B/0008 STR. NOTT O FEST REP. MOBILI ENTRO LIMITE MAX IND. - Qta. 21,00 - Imp. 14,49 - Rif. 12/2025 304,29
A01B/0009 STR. NOTT FEST REP. MOBILI ENTRO LIMITE MAX IND. - Qta. 1,00 - Imp. 16,71 - Rif. 12/2025 16,71
AA01/ST01 STRAORDINARIO DIURNO - Qta. 5,00 - Imp. 12,80 - Rif. 12/2025 64,00
AA01/ST02 STRAORDINARIO NOTTURNO O FESTIVO - Qta. 2,00 - Imp. 14,49 - Rif. 12/2025 28,98
AA01/ST03 STRAORDINARIO NOTTURNO E FESTIVO - Qta. 1,00 - Imp. 16,71 - Rif. 12/2025 16,71

Ritenute
PREVIDENZIALI Imponibile Aliquota Importo
Totale ritenute previdenziali 435,39
FISCALI Imponibile Aliquota Importo
Totale ritenute fiscali al netto delle detrazioni 858,06
ALTRE RITENUTE
800/IP2 INPS EX INPDAP-PREST.DOPPIO DAL 1/1/2004 scad. 05/2027 236,80
800/S7J RITENUTA SINDACALE 8,63
800/S5J RITENUTA SINDACALE 8,63
800/FPS FONDO ASSISTENZA POLIZIA DI STATO 0,20
Conguagli fiscali e previdenziali
806/008 RIMBORSO CONGUAGLIO FISCALE 117,74
''';

  const polferMarchRealText = '''
RATA: Marzo 2026 ID CEDOLINO: 194F441C
Posizione giuridico-economica
Inquad.: ASSISTENTE Tipo rapporto: Tempo indeterminato Qualifica: MA03
Tipo Liquidaz.: TFS Parametro: 112,00 Cassa previdenza: INPDAP

DATI RIEPILOGATIVI DELLA RETRIBUZIONE
Descrizione Ritenute Competenze
Competenze fisse
Stipendio 1.824,67
Altri assegni 712,31
Competenze accessorie
Assegni accessori 518,40
Ritenute
Previdenziali 341,73
Fiscali 491,31
Altre ritenute 17,86
Conguagli fiscali e previdenziali
Totale 75,18

Totale netto: 2.129,30
Quinto cedibile: 366,32
Imponibile AC: 7.509,52 IRPEF AC: 1.242,56 Aliquota massima: 33,00
Imponibile AP: 0,00 IRPEF AP: 0,00 Aliquota media: 24,65

DATI DI DETTAGLIO DELLA RETRIBUZIONE
Cod. Descrizione Ritenute Competenze
Competenze fisse
STIPENDIO
MA03 STIPENDIO TABELLARE 1.298,18
750/816 IIS CONGLOBATA MA03 526,49
ALTRI ASSEGNI
129/MA3 IND.VACANZA CONTRATTUALE 18,25
200/AB3 IND.PENS.MENS. MA03 - MB02 694,06

Competenze accessorie
Assegni accessori
AA06/E1BW INDENNITA' PRESENZA SERVIZI ESTERNI - Qta. 22,00 - Imp. 6,00 - Rif. 01/2026 132,00
B003/0001 ORD.PUBBL. IN SEDE - Qta. 1,00 - Imp. 13,00 - Rif. 01/2026 13,00
AA06/E1H3 INDENNITA' CONTROLLO DEL TERRITORIO SERALE - Qta. 5,00 - Imp. 5,00 - Rif. 01/2026 25,00
AA06/E1H4 INDENNITA' CONTROLLO DEL TERRITORIO NOTTURNO - Qta. 6,00 - Imp. 10,00 - Rif. 01/2026 60,00
AA06/E1BJ INDENNITA' SERVIZIO FESTIVO - Qta. 3,00 - Imp. 14,00 - Rif. 01/2026 42,00
AA06/E1BL INDENNITA' SERVIZIO NOTTURNO - Qta. 48,00 - Imp. 4,30 - Rif. 01/2026 206,40
AA06/E1BV INDENNITA' PER FESTIVITA' PARTICOLARI - Qta. 1,00 - Imp. 40,00 - Rif. 01/2026 40,00

Ritenute
PREVIDENZIALI Imponibile Aliquota Importo
Totale ritenute previdenziali 341,73
FISCALI Imponibile Aliquota Importo
Totale ritenute fiscali al netto delle detrazioni 491,31
ALTRE RITENUTE
800/S2J RITENUTA SINDACALE 8,63
800/S1J RITENUTA SINDACALE 8,63
800/FPS FONDO ASSISTENZA POLIZIA DI STATO 0,60
Conguagli fiscali e previdenziali
800/A04 ADDIZ.REG.IRPEF(COD.FIN.21 VENETO) scad. 11/2026 46,72
800/CC1 ADDIZIONALE COMUNALE - SALDO scad. 11/2026 20,04
800/CC0 ADDIZIONALE COMUNALE - ACCONTO scad. 11/2026 8,42
''';

  group('PayslipParserService with real fixtures', () {
    test('RM March 2026 fixture extracts summary and accessory rows correctly', () {
      final parsed = parser.parsePayslipText(
        filePath: '/tmp/rm_marzo_2026_fixture.pdf',
        rawText: rmMarchRealText,
      );

      expect(parsed.monthLabel, 'Marzo 2026');
      expect(parsed.year, 2026);
      expect(parsed.summaryFixedPay, closeTo(1902.05, 0.01));
      expect(parsed.summaryOtherAllowances, closeTo(1002.43, 0.01));
      expect(parsed.summaryAccessoryPay, closeTo(1360.61, 0.01));
      expect(parsed.summaryPrevidenziali, closeTo(448.33, 0.01));
      expect(parsed.summaryFiscali, closeTo(919.09, 0.01));
      expect(parsed.summaryOtherDeductions, closeTo(10.38, 0.01));
      expect(parsed.summaryConguagli, closeTo(111.00, 0.01));

      expect(parsed.accessoryEntries.length, 13);
      expect(parsed.operationalAccessoryEntries, isNotEmpty);
      expect(parsed.operationalAccessoryEntries.length, 13);

      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'B003/0001'),
        isTrue,
      );
      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'B003/0003'),
        isTrue,
      );
      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'AA06/E1BL'),
        isTrue,
      );
      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'AA06/E1BJ'),
        isTrue,
      );
      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'AA01/ST01'),
        isTrue,
      );
      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'AA01/ST02'),
        isTrue,
      );
      expect(
        parsed.operationalAccessoryEntries.any((e) => e.code == 'AA01/ST03'),
        isTrue,
      );

      final opInSede = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'B003/0001',
      );
      expect(opInSede.amount, closeTo(221.00, 0.01));
      expect(opInSede.quantity, closeTo(17.0, 0.01));
      expect(opInSede.unitAmount, closeTo(13.00, 0.01));

      final strDay = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA01/ST01',
      );
      expect(strDay.unitAmount, closeTo(13.35, 0.01));

      final strNight = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA01/ST02',
      );
      expect(strNight.unitAmount, closeTo(15.10, 0.01));

      final strNightHoliday = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA01/ST03',
      );
      expect(strNightHoliday.unitAmount, closeTo(17.42, 0.01));
    });

    test('RM February 2026 fixture derives overtime rates coherently', () {
      final parsed = parser.parsePayslipText(
        filePath: '/tmp/rm_febbraio_2026_fixture.pdf',
        rawText: rmFebruaryRealText,
      );

      expect(parsed.accessoryEntries.length, 16);
      expect(parsed.operationalAccessoryEntries, isNotEmpty);

      final profile = parser.buildDynamicProfile([parsed]);

      expect(profile.overtimeDayRate, closeTo(12.80, 0.01));
      expect(profile.overtimeNightOrHolidayRate, closeTo(14.49, 0.01));
      expect(profile.overtimeNightAndHolidayRate, closeTo(16.71, 0.01));

      expect(parsed.summaryAccessoryPay, closeTo(1596.39, 0.01));
      expect(parsed.summaryPrevidenziali, closeTo(435.39, 0.01));
      expect(parsed.summaryFiscali, closeTo(858.06, 0.01));
      expect(parsed.summaryOtherDeductions, closeTo(254.26, 0.01));
    });

    test('RM March 2026 fixture derives overtime rates coherently', () {
      final parsed = parser.parsePayslipText(
        filePath: '/tmp/rm_marzo_2026_fixture.pdf',
        rawText: rmMarchRealText,
      );

      final profile = parser.buildDynamicProfile([parsed]);

      expect(profile.overtimeDayRate, closeTo(13.35, 0.01));
      expect(profile.overtimeNightOrHolidayRate, closeTo(15.10, 0.01));
      expect(profile.overtimeNightAndHolidayRate, closeTo(17.42, 0.01));
    });

    test('Polfer March 2026 fixture extracts operational accessory rows correctly', () {
      final parsed = parser.parsePayslipText(
        filePath: '/tmp/polfer_marzo_2026_fixture.pdf',
        rawText: polferMarchRealText,
      );

      expect(parsed.monthLabel, 'Marzo 2026');
      expect(parsed.summaryAccessoryPay, closeTo(518.40, 0.01));
      expect(parsed.summaryPrevidenziali, closeTo(341.73, 0.01));
      expect(parsed.summaryFiscali, closeTo(491.31, 0.01));
      expect(parsed.summaryOtherDeductions, closeTo(17.86, 0.01));
      expect(parsed.summaryConguagli, closeTo(75.18, 0.01));

      expect(parsed.accessoryEntries.length, 7);
      expect(parsed.operationalAccessoryEntries, isNotEmpty);
      expect(parsed.operationalAccessoryEntries.length, 6);

      final externalService = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA06/E1BW',
      );
      expect(externalService.unitAmount, closeTo(6.00, 0.01));
      expect(externalService.amount, closeTo(132.00, 0.01));

      final controlSerale = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA06/E1H3',
      );
      expect(controlSerale.unitAmount, closeTo(5.00, 0.01));

      final controlNotturno = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA06/E1H4',
      );
      expect(controlNotturno.unitAmount, closeTo(10.00, 0.01));

      final servizioNotturno = parsed.accessoryEntries.firstWhere(
        (e) => e.code == 'AA06/E1BL',
      );
      expect(servizioNotturno.unitAmount, closeTo(4.30, 0.01));
    });
  });
}