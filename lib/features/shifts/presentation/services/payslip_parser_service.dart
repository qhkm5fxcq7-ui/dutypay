import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/user_pay_profile.dart';

class PayslipParserService {
  const PayslipParserService();

  Future<String> extractTextFromPdf(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('PDF non trovato: $filePath');
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('Il file PDF è vuoto.');
    }

    final document = PdfDocument(inputBytes: bytes);

    try {
      final rawText = PdfTextExtractor(document).extractText(
        layoutText: true,
      );

      final cleanedText = _normalizeExtractedText(rawText);

      if (cleanedText.trim().isEmpty) {
        throw Exception(
          'Il PDF è stato letto ma non contiene testo estraibile. '
          'Potrebbe essere una scansione o un PDF immagine.',
        );
      }

      return cleanedText;
    } finally {
      document.dispose();
    }
  }

  Future<PayslipParsedData> extractAndParsePdf(String filePath) async {
    final text = await extractTextFromPdf(filePath);

    print('================ PDF TEXT START =================');
    _printLongText(text);
    print('================ PDF TEXT END =================');

    return parsePayslipText(
      filePath: filePath,
      rawText: text,
    );
  }

  PayslipParsedData parsePayslipText({
    required String filePath,
    required String rawText,
  }) {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : filePath.split('/').last;

    final normalizedText = _prepareTextForParsing(rawText);
    final lines = _toCleanLines(normalizedText);
    final flatText = _flattenText(normalizedText);

    final monthLabel =
        _extractMonthLabel(
          normalizedText,
          flatText,
          lines,
          fileName: fileName,
        ) ??
        'Non rilevato';

    final year = _extractYearFromLabel(monthLabel);

    final cedolinoId =
        _extractFirstGroup(
          normalizedText,
          [
            RegExp(r'ID\s+CEDOLINO[:\s]+([A-Z0-9]+)', caseSensitive: false),
          ],
        ) ??
        '';

    final inquadramento = _extractInquadramento(normalizedText);
    final qualifica = _extractQualifica(normalizedText);

    final parametro = _extractEuroValueAfterLabels(
      normalizedText,
      const ['Parametro:', 'Parametro'],
    );

    final totaleNetto =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['Totale netto:', 'Totale netto'],
        ) ??
        0;

    final quintoCedibile = _extractEuroValueAfterLabels(
      normalizedText,
      const ['Quinto cedibile:', 'Quinto cedibile'],
    );

    final imponibileAc =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['Imponibile AC:', 'Imponibile AC'],
        ) ??
        0;

    final irpefAc =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['IRPEF AC:', 'IRPEF AC'],
        ) ??
        0;

    final aliquotaMassima =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['Aliquota massima:', 'Aliquota massima'],
        ) ??
        0;

    final imponibileAp =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['Imponibile AP:', 'Imponibile AP'],
        ) ??
        0;

    final irpefAp =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['IRPEF AP:', 'IRPEF AP'],
        ) ??
        0;

    final aliquotaMedia =
        _extractEuroValueAfterLabels(
          normalizedText,
          const ['Aliquota media:', 'Aliquota media'],
        ) ??
        0;

    final summaryFixedPay = _extractSummaryValue(
      lines,
      header: 'Competenze fisse',
      label: 'Stipendio',
    );

    final summaryOtherAllowances = _extractSummaryValue(
      lines,
      header: 'Competenze fisse',
      label: 'Altri assegni',
    );

    final summaryThirteenth = _extractSummaryValue(
      lines,
      header: 'Competenze fisse',
      label: 'Tredicesima',
    );

    final summaryAccessoryPay = _extractSummaryValue(
      lines,
      header: 'Competenze accessorie',
      label: 'Assegni accessori',
    );

    final summaryPrevidenziali = _extractSummaryValue(
      lines,
      header: 'Ritenute',
      label: 'Previdenziali',
    );

    final summaryFiscali = _extractSummaryValue(
      lines,
      header: 'Ritenute',
      label: 'Fiscali',
    );

    final summaryOtherDeductions = _extractSummaryValue(
      lines,
      header: 'Ritenute',
      label: 'Altre ritenute',
    );

    final summaryConguagli = _extractSummaryValue(
      lines,
      header: 'Conguagli fiscali e previdenziali',
      label: 'Totale',
    );

    final fixedEntries = _extractFixedEntries(flatText);
    final accessoryEntries = _extractAccessoryEntries(flatText);
    final deductionEntries = _extractDeductionEntries(flatText);

    final cleanedInquadramento = _cleanInlineText(inquadramento);
    final cleanedQualifica = _cleanInlineText(qualifica);

    return PayslipParsedData(
      filePath: filePath,
      fileName: fileName,
      rawText: rawText,
      monthLabel: monthLabel,
      year: year,
      cedolinoId: cedolinoId,
      inquadramento: cleanedInquadramento,
      qualifica: cleanedQualifica,
      detectedGradeLabel: _buildDetectedGradeLabel(
        inquadramento: cleanedInquadramento,
        qualifica: cleanedQualifica,
      ),
      parametro: parametro,
      totaleNetto: totaleNetto,
      quintoCedibile: quintoCedibile,
      summaryFixedPay: summaryFixedPay,
      summaryOtherAllowances: summaryOtherAllowances,
      summaryThirteenth: summaryThirteenth,
      summaryAccessoryPay: summaryAccessoryPay,
      summaryPrevidenziali: summaryPrevidenziali,
      summaryFiscali: summaryFiscali,
      summaryOtherDeductions: summaryOtherDeductions,
      summaryConguagli: summaryConguagli,
      taxes: PayslipTaxSnapshot(
        imponibileAc: imponibileAc,
        irpefAc: irpefAc,
        aliquotaMassima: aliquotaMassima,
        imponibileAp: imponibileAp,
        irpefAp: irpefAp,
        aliquotaMedia: aliquotaMedia,
      ),
      fixedEntries: fixedEntries,
      accessoryEntries: accessoryEntries,
      deductionEntries: deductionEntries,
    );
  }

  UserPayProfile buildDynamicProfile(List<PayslipParsedData> payslips) {
    if (payslips.isEmpty) {
      throw Exception('Nessun cedolino disponibile per costruire il profilo.');
    }

    final standardPayslips = payslips
        .where((item) => !item.isSupplementaryPayslip)
        .toList();

    final effectiveSource = standardPayslips.isNotEmpty
        ? standardPayslips
        : payslips;

    final baseSalary = _average(
      effectiveSource.map((item) => item.detectedBaseSalary).toList(),
    );

    final accessoryAverage = _average(
      effectiveSource
          .map((item) => item.detectedOperationalAccessoryTotal)
          .toList(),
    );

    final recurringDeductionsAverage = _average(
      effectiveSource
          .map((item) => item.detectedRecurringDeductionsTotal)
          .toList(),
    );

    final taxRateAverage = _average(
      effectiveSource.map((item) => item.effectiveTaxRateForEngine).toList(),
    );

    final latest = effectiveSource.last;
    final defaultProfile = UserPayProfile.defaultProfile();

    final windowLabel =
        effectiveSource.map((item) => item.monthLabel).join(' • ');

    return UserPayProfile(
      rank: latest.detectedGradeLabel == 'Non rilevato'
          ? defaultProfile.rank
          : latest.detectedGradeLabel,
      overtimeDayRate: defaultProfile.overtimeDayRate,
      overtimeNightOrHolidayRate: defaultProfile.overtimeNightOrHolidayRate,
      overtimeNightAndHolidayRate: defaultProfile.overtimeNightAndHolidayRate,
      orderPublicInSede: defaultProfile.orderPublicInSede,
      orderPublicFuoriSede: defaultProfile.orderPublicFuoriSede,
      orderPublicPernotto: defaultProfile.orderPublicPernotto,
      externalServiceRate: defaultProfile.externalServiceRate,
      holidayAllowance: defaultProfile.holidayAllowance,
      specialHolidayAllowance: defaultProfile.specialHolidayAllowance,
      profileVersion: 'v${DateTime.now().millisecondsSinceEpoch}',
      calibratedAt: DateTime.now(),
      sourceWindowLabel: windowLabel,
      detectedGradeLabel: latest.detectedGradeLabel,
      detectedBaseSalary: baseSalary,
      averageAccessoryPay: accessoryAverage,
      recurringDeductionsTotal: recurringDeductionsAverage,
      effectiveTaxRate: taxRateAverage > 0
          ? taxRateAverage
          : defaultProfile.effectiveTaxRate,
      sourcePayslips: effectiveSource,
    );
  }

  void _printLongText(String text) {
    const chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      print(text.substring(i, end));
    }
  }

  List<PayslipEntry> _extractFixedEntries(String flatText) {
    final results = <PayslipEntry>[];

    final patterns = <_FixedPattern>[
      _FixedPattern(
        code: 'MA03',
        description: 'STIPENDIOTABELLARE',
        normalizedDescription: 'STIPENDIO TABELLARE',
      ),
      _FixedPattern(
        code: '750/816',
        description: 'IISCONGLOBATAMA03',
        normalizedDescription: 'IIS CONGLOBATA MA03',
      ),
      _FixedPattern(
        code: '129/MA3',
        description: 'IND.VACANZACONTRATTUALE',
        normalizedDescription: 'IND. VACANZA CONTRATTUALE',
      ),
      _FixedPattern(
        code: '200/AB3',
        description: 'IND.PENS.MENS.MA03-MB02',
        normalizedDescription: 'IND.PENS.MENS. MA03 - MB02',
      ),
    ];

    for (final pattern in patterns) {
      final regex = RegExp(
        '${RegExp.escape(pattern.code)}'
        '${RegExp.escape(pattern.description)}'
        r'([0-9]{1,3}(?:\.[0-9]{3})*,[0-9]{2})',
        caseSensitive: false,
      );

      final match = regex.firstMatch(flatText);
      if (match == null) continue;

      results.add(
        PayslipEntry(
          code: pattern.code,
          description: pattern.normalizedDescription,
          amount: _parseEuro(match.group(1) ?? ''),
          sectionType: PayslipSectionType.fixedCompensation,
          isRecurring: true,
        ),
      );
    }

    return _dedupeEntries(results);
  }

  List<PayslipEntry> _extractAccessoryEntries(String flatText) {
    final results = <PayslipEntry>[];

    final regex = RegExp(
      r'([A-Z0-9]{3,6}/[A-Z0-9]{2,4}|A01B/[0-9]{4})'
      r'(.+?)'
      r'-Qta\.([0-9.,]+)'
      r'-Imp\.([0-9.,]+)'
      r'-Rif\.([0-9/]+)',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in regex.allMatches(flatText)) {
      final code = (match.group(1) ?? '').trim();
      final rawDescription = (match.group(2) ?? '').trim();
      final quantity = _parseLooseNumber(match.group(3) ?? '');
      final unitAmount = _parseLooseNumber(match.group(4) ?? '');
      final reference = (match.group(5) ?? '').trim();

      if (code.isEmpty || rawDescription.isEmpty) continue;
      if (quantity <= 0 || unitAmount <= 0) continue;

      results.add(
        PayslipEntry(
          code: code,
          description: _normalizeAccessoryDescription(rawDescription),
          amount: quantity * unitAmount,
          quantity: quantity,
          unitAmount: unitAmount,
          reference: reference.isEmpty ? null : reference,
          sectionType: PayslipSectionType.accessoryCompensation,
        ),
      );
    }

    return _dedupeEntries(results);
  }

  List<PayslipEntry> _extractDeductionEntries(String flatText) {
    final results = <PayslipEntry>[];

    final regex = RegExp(
      r'(800/[A-Z0-9]{2,4})'
      r'(.+?)'
      r'([0-9]{1,3}(?:\.[0-9]{3})*,[0-9]{2})',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in regex.allMatches(flatText)) {
      final code = (match.group(1) ?? '').trim();
      var description = (match.group(2) ?? '').trim();
      final amount = _parseEuro(match.group(3) ?? '');

      if (code.isEmpty || description.isEmpty || amount <= 0) continue;

      description = _normalizeDeductionDescription(description);

      results.add(
        PayslipEntry(
          code: code,
          description: description,
          amount: amount,
          sectionType: PayslipSectionType.deduction,
          isRecurring: _isRecurringDescription(description),
        ),
      );
    }

    return _dedupeEntries(results);
  }

  String _normalizeAccessoryDescription(String raw) {
    final value = raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    const mapping = {
      'STRORESUPERODIURNO': 'STR ORE SUPERO DIURNO',
      'ORD.PUBBL.INSEDE': 'ORD. PUBBL. IN SEDE',
      'ORD.PUBBL.F.SEDE1TURNO': 'ORD. PUBBL. F. SEDE 1 TURNO',
      "INDENNITA'SERVIZIOFESTIVO": "INDENNITA' SERVIZIO FESTIVO",
      "INDENNITA'SERVIZIONOTTURNO": "INDENNITA' SERVIZIO NOTTURNO",
      "INDENNITA'DICOMPENSAZIONE": "INDENNITA' DI COMPENSAZIONE",
      "INDENNITA'PRESENZASERVIZIESTERNI":
          "INDENNITA' PRESENZA SERVIZI ESTERNI",
      "INDENNITA'PERFESTIVITA'PARTICOLARI":
          "INDENNITA' PER FESTIVITA' PARTICOLARI",
      'STRAORDINARIODIURNO': 'STRAORDINARIO DIURNO',
      'STRAORDINARIONOTTURNOOFESTIVO':
          'STRAORDINARIO NOTTURNO O FESTIVO',
      'STRAORDINARIONOTTURNOEFESTIVO':
          'STRAORDINARIO NOTTURNO E FESTIVO',
      'STR.FERIALEREPARTIMOBILIENTROLIMITEMAXIND.':
          'STR. FERIALE REPARTI MOBILI ENTRO LIMITE MAX IND.',
      'STR.NOTTOFESTREP.MOBILIENTROLIMITEMAXIND.':
          'STR. NOTT O FEST REP. MOBILI ENTRO LIMITE MAX IND.',
      'STR.NOTTFESTREP.MOBILIENTROLIMITEMAXIND.':
          'STR. NOTT FEST REP. MOBILI ENTRO LIMITE MAX IND.',
    };

    return mapping[value] ?? raw;
  }

  String _normalizeDeductionDescription(String raw) {
    final value = raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    if (value.contains('INPSEXINPDAP-PREST.DOPPIODAL1/1/2004')) {
      return 'INPS EX INPDAP - PREST. DOPPIO DAL 1/1/2004';
    }
    if (value.contains('RITENUTASINDACALE')) {
      return 'RITENUTA SINDACALE';
    }
    if (value.contains('FONDOASSISTENZAPOLIZIADISTATO')) {
      return 'FONDO ASSISTENZA POLIZIA DI STATO';
    }
    if (value.contains('ADDIZ.REG.IRPEF')) {
      return 'ADDIZ. REG. IRPEF';
    }
    if (value.contains('ADDIZIONALECOMUNALE-SALDO')) {
      return 'ADDIZIONALE COMUNALE - SALDO';
    }
    if (value.contains('ADDIZIONALECOMUNALE-ACCONTO')) {
      return 'ADDIZIONALE COMUNALE - ACCONTO';
    }

    return raw;
  }

  List<String> _toCleanLines(String text) {
    return text
        .split('\n')
        .map(_cleanInlineText)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _flattenText(String text) {
    return text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _prepareTextForParsing(String rawText) {
    return rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'<PARSED TEXT FOR PAGE:[^>]+>'), '\n')
        .replaceAll(RegExp(r'<IMAGE FOR PAGE:[^>]+>'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String? _extractMonthLabel(
    String normalizedText,
    String flatText,
    List<String> lines, {
    required String fileName,
  }) {
    for (final line in lines) {
      final match = RegExp(
        r'RATA[:\s]+([A-Za-zÀ-ÿ]+)\s+(20\d{2})',
        caseSensitive: false,
      ).firstMatch(line);

      if (match != null) {
        final month = _capitalize((match.group(1) ?? '').trim());
        final year = (match.group(2) ?? '').trim();
        if (month.isNotEmpty && year.isNotEmpty) {
          return '$month $year';
        }
      }
    }

    final inlineMatch = RegExp(
      r'RATA[:\s]+([A-Za-zÀ-ÿ]+)\s+(20\d{2})',
      caseSensitive: false,
    ).firstMatch(flatText);

    if (inlineMatch != null) {
      final month = _capitalize((inlineMatch.group(1) ?? '').trim());
      final year = (inlineMatch.group(2) ?? '').trim();
      if (month.isNotEmpty && year.isNotEmpty) {
        return '$month $year';
      }
    }

    final fileMatch = RegExp(
      r'([A-Za-zÀ-ÿ]+)_(20\d{2})',
      caseSensitive: false,
    ).firstMatch(fileName);

    if (fileMatch != null) {
      final month = _capitalize(
        (fileMatch.group(1) ?? '').replaceAll('_', ' ').trim(),
      );
      final year = (fileMatch.group(2) ?? '').trim();
      if (month.isNotEmpty && year.isNotEmpty) {
        return '$month $year';
      }
    }

    return null;
  }

  String _extractInquadramento(String normalizedText) {
    final match = RegExp(
      r'Inquad\.\s*:\s*([A-ZÀ-ÿ ]+?)Tipo\s+rapporto',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(normalizedText);

    if (match == null) return '';
    return _cleanInlineText(match.group(1) ?? '');
  }

  String _extractQualifica(String normalizedText) {
    final match = RegExp(
      r'Qualifica[:\s]+([A-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(normalizedText);

    if (match == null) return '';
    return _cleanInlineText(match.group(1) ?? '');
  }

  bool _isRecurringDescription(String description) {
    final value = description.toUpperCase();

    return value.contains('PREST') ||
        value.contains('SINDAC') ||
        value.contains('FONDO ASSISTENZA') ||
        value.contains('QUINTO') ||
        value.contains('CESSIONE') ||
        value.contains('MUTUO');
  }

  List<PayslipEntry> _dedupeEntries(List<PayslipEntry> entries) {
    final seen = <String>{};
    final result = <PayslipEntry>[];

    for (final entry in entries) {
      final key =
          '${entry.sectionType.name}|${entry.code}|${entry.description}|${entry.amount.toStringAsFixed(2)}|${(entry.quantity ?? 0).toStringAsFixed(2)}|${(entry.unitAmount ?? 0).toStringAsFixed(2)}';

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      result.add(entry);
    }

    return result;
  }

  String _buildDetectedGradeLabel({
    required String inquadramento,
    required String qualifica,
  }) {
    if (inquadramento.isEmpty && qualifica.isEmpty) {
      return 'Non rilevato';
    }

    if (inquadramento.isNotEmpty && qualifica.isNotEmpty) {
      return '$inquadramento ($qualifica)';
    }

    return inquadramento.isNotEmpty ? inquadramento : qualifica;
  }

  String _cleanInlineText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  int? _extractYearFromLabel(String label) {
    final match = RegExp(r'(20\d{2})').firstMatch(label);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String? _extractFirstGroup(String source, List<RegExp> regexes) {
    for (final regex in regexes) {
      final match = regex.firstMatch(source);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  double _extractSummaryValue(
    List<String> lines, {
    required String header,
    required String label,
  }) {
    final headerUpper = header.toUpperCase();
    final labelUpper = label.toUpperCase();

    int headerIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toUpperCase().contains(headerUpper)) {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex == -1) return 0;

    for (int i = headerIndex; i < lines.length && i < headerIndex + 12; i++) {
      final lineUpper = lines[i].toUpperCase();
      if (!lineUpper.contains(labelUpper)) continue;

      final valueMatch = RegExp(
        r'([0-9]{1,3}(?:\.[0-9]{3})*,[0-9]{2})',
      ).allMatches(lines[i]).toList();

      if (valueMatch.isNotEmpty) {
        return _parseEuro(valueMatch.last.group(1) ?? '');
      }
    }

    return 0;
  }

  double? _extractEuroValueAfterLabels(String text, List<String> labels) {
    for (final label in labels) {
      final escapedLabel = RegExp.escape(label);
      final regex = RegExp(
        '$escapedLabel\\s*([0-9]{1,3}(?:\\.[0-9]{3})*,[0-9]{2})',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);
      if (match != null) {
        return _parseEuro(match.group(1) ?? '');
      }
    }

    return null;
  }

  String _normalizeExtractedText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  double _parseEuro(String raw) {
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double _parseLooseNumber(String raw) {
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class _FixedPattern {
  final String code;
  final String description;
  final String normalizedDescription;

  const _FixedPattern({
    required this.code,
    required this.description,
    required this.normalizedDescription,
  });
}