import '../models/user_pay_profile.dart';

class ShiftDerivedRates {
  final double straordinarioDiurnoOrario;
  final double indennitaNotturnaPerTurno;
  final double indennitaFestivaPerTurno;
  final double ordinePubblicoInSedePerTurno;
  final double servizioEsternoPerTurno;

  final bool isStraordinarioReal;
  final bool isNotturnoReal;
  final bool isFestivoReal;
  final bool isOPReal;
  final bool isEsternoReal;

  const ShiftDerivedRates({
    required this.straordinarioDiurnoOrario,
    required this.indennitaNotturnaPerTurno,
    required this.indennitaFestivaPerTurno,
    required this.ordinePubblicoInSedePerTurno,
    required this.servizioEsternoPerTurno,
    this.isStraordinarioReal = false,
    this.isNotturnoReal = false,
    this.isFestivoReal = false,
    this.isOPReal = false,
    this.isEsternoReal = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'straordinario': straordinarioDiurnoOrario,
      'notturno': indennitaNotturnaPerTurno,
      'festivo': indennitaFestivaPerTurno,
      'ordine_pubblico': ordinePubblicoInSedePerTurno,
      'esterno': servizioEsternoPerTurno,
      'is_straordinario_real': isStraordinarioReal,
      'is_notturno_real': isNotturnoReal,
      'is_festivo_real': isFestivoReal,
      'is_op_real': isOPReal,
      'is_esterno_real': isEsternoReal,
    };
  }

  factory ShiftDerivedRates.fromMap(Map<String, dynamic> map) {
    return ShiftDerivedRates(
      straordinarioDiurnoOrario: _readDouble(map['straordinario'], 12.0),
      indennitaNotturnaPerTurno: _readDouble(map['notturno'], 4.3),
      indennitaFestivaPerTurno: _readDouble(map['festivo'], 8.0),
      ordinePubblicoInSedePerTurno: _readDouble(map['ordine_pubblico'], 6.0),
      servizioEsternoPerTurno: _readDouble(map['esterno'], 6.0),
      isStraordinarioReal:
          _readBool(map['is_straordinario_real'], map.containsKey('straordinario')),
      isNotturnoReal:
          _readBool(map['is_notturno_real'], map.containsKey('notturno')),
      isFestivoReal:
          _readBool(map['is_festivo_real'], map.containsKey('festivo')),
      isOPReal: _readBool(map['is_op_real'], map.containsKey('ordine_pubblico')),
      isEsternoReal:
          _readBool(map['is_esterno_real'], map.containsKey('esterno')),
    );
  }

  static double _readDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase();
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return fallback;
  }
}

class ShiftRateCalculator {
  const ShiftRateCalculator();

  ShiftDerivedRates buildFromProfile(UserPayProfile profile) {
    final entries = profile.sourcePayslips
        .expand((p) => p.operationalAccessoryEntries)
        .toList();

    final straordinarioEntries =
        entries.where(_isStraordinarioDiurnoPuro).toList();
    final notturnoEntries = entries.where(_isNotturnoPuro).toList();
    final festivoEntries = entries.where(_isFestivoPuro).toList();
    final opInSedeEntries = entries.where(_isOrdinePubblicoInSedePuro).toList();
    final servizioEsternoEntries =
        entries.where(_isServizioEsternoPuro).toList();

    final straordinarioRate = _averageUnitAmount(straordinarioEntries);
    final notturnoRate = _averageUnitAmount(notturnoEntries);
    final festivoRate = _averageUnitAmount(festivoEntries);
    final opInSedeRate = _averageUnitAmount(opInSedeEntries);
    final servizioEsternoRate = _averageUnitAmount(servizioEsternoEntries);

    return ShiftDerivedRates(
      straordinarioDiurnoOrario: _round2(
        straordinarioRate ?? profile.overtimeDayRate,
      ),
      indennitaNotturnaPerTurno: _round2(
        notturnoRate ?? 4.3,
      ),
      indennitaFestivaPerTurno: _round2(
        festivoRate ?? profile.holidayAllowance,
      ),
      ordinePubblicoInSedePerTurno: _round2(
        opInSedeRate ?? profile.orderPublicInSede,
      ),
      servizioEsternoPerTurno: _round2(
        servizioEsternoRate ?? profile.externalServiceRate,
      ),
      isStraordinarioReal: straordinarioRate != null,
      isNotturnoReal: notturnoRate != null,
      isFestivoReal: festivoRate != null,
      isOPReal: opInSedeRate != null,
      isEsternoReal: servizioEsternoRate != null,
    );
  }

  bool _isStraordinarioDiurnoPuro(PayslipEntry e) {
    final t = _norm(e.description);
    final code = e.code.toUpperCase().trim();

    final positive =
        code.contains('ST01') ||
        t.contains('STRAORDINARIODIURNO') ||
        t.contains('STRORESUPERODIURNO');

    final excluded =
        t.contains('COMPENSAZIONE') ||
        t.contains('SERVIZIONOTTURNO') ||
        t.contains('SERVIZIOFESTIVO');

    return positive && !excluded;
  }

  bool _isNotturnoPuro(PayslipEntry e) {
    final t = _norm(e.description);
    final code = e.code.toUpperCase().trim();

    final positive =
        code == 'AA06/E1BL' ||
        t.contains('INDENNITASERVIZIONOTTURNO') ||
        t.contains('SERVIZIONOTTURNO');

    final excluded =
        t.contains('COMPENSAZIONE') ||
        t.contains('STRAORD');

    return positive && !excluded;
  }

  bool _isFestivoPuro(PayslipEntry e) {
    final t = _norm(e.description);
    final code = e.code.toUpperCase().trim();

    final positive =
        code == 'AA06/E1BJ' ||
        t.contains('INDENNITASERVIZIOFESTIVO') ||
        t.contains('SERVIZIOFESTIVO');

    final excluded =
        t.contains('FESTIVITAPARTICOLARI') ||
        t.contains('COMPENSAZIONE') ||
        t.contains('STRAORD') ||
        t.contains('NOTT');

    return positive && !excluded;
  }

  bool _isOrdinePubblicoInSedePuro(PayslipEntry e) {
    final t = _norm(e.description);
    final code = e.code.toUpperCase().trim();

    final positive =
        code == 'B003/0001' ||
        t.contains('ORDPUBBLINSEDE');

    final excluded =
        t.contains('FSEDE') ||
        t.contains('FUORISEDE') ||
        t.contains('1TURNO') ||
        t.contains('INTERA') ||
        t.contains('PERNOTTO') ||
        t.contains('COMPENSAZIONE');

    return positive && !excluded;
  }

  bool _isServizioEsternoPuro(PayslipEntry e) {
    final t = _norm(e.description);
    final code = e.code.toUpperCase().trim();

    final positive =
        code == 'AA06/E1BW' ||
        t.contains('INDENNITAPRESENZASERVIZIESTERNI') ||
        t.contains('SERVIZIESTERNI');

    final excluded =
        t.contains('COMPENSAZIONE') ||
        t.contains('STRAORD') ||
        t.contains('NOTT') ||
        t.contains('FEST');

    return positive && !excluded;
  }

  double? _averageUnitAmount(List<PayslipEntry> entries) {
    final values = <double>[];

    for (final e in entries) {
      final unit = e.unitAmount;
      final qty = e.quantity ?? 0;

      if (unit != null && unit > 0) {
        values.add(unit);
        continue;
      }

      if (qty > 0 && e.amount > 0) {
        final derived = e.amount / qty;
        if (derived > 0 && derived < 100) {
          values.add(derived);
        }
      }
    }

    if (values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  String _norm(String v) {
    return v
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll("'", '')
        .replaceAll('-', '')
        .replaceAll('/', '');
  }

  double _round2(double v) {
    return double.parse(v.toStringAsFixed(2));
  }
}