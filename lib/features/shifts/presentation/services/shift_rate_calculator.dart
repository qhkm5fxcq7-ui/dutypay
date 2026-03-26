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

  Map<String, double> toMap() {
    return {
      'straordinario': straordinarioDiurnoOrario,
      'notturno': indennitaNotturnaPerTurno,
      'festivo': indennitaFestivaPerTurno,
      'ordine_pubblico': ordinePubblicoInSedePerTurno,
      'esterno': servizioEsternoPerTurno,
    };
  }

  factory ShiftDerivedRates.fromMap(Map<String, double> map) {
    final hasStraordinario = map.containsKey('straordinario');
    final hasNotturno = map.containsKey('notturno');
    final hasFestivo = map.containsKey('festivo');
    final hasOP = map.containsKey('ordine_pubblico');
    final hasEsterno = map.containsKey('esterno');

    return ShiftDerivedRates(
      straordinarioDiurnoOrario: map['straordinario'] ?? 12.0,
      indennitaNotturnaPerTurno: map['notturno'] ?? 6.0,
      indennitaFestivaPerTurno: map['festivo'] ?? 8.0,
      ordinePubblicoInSedePerTurno: map['ordine_pubblico'] ?? 6.0,
      servizioEsternoPerTurno: map['esterno'] ?? 6.0,
      isStraordinarioReal: hasStraordinario,
      isNotturnoReal: hasNotturno,
      isFestivoReal: hasFestivo,
      isOPReal: hasOP,
      isEsternoReal: hasEsterno,
    );
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
        notturnoRate ??
            (profile.overtimeNightOrHolidayRate - profile.overtimeDayRate),
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

  bool _isStraordinarioDiurnoPuro(PayslipEntry entry) {
    final t = _norm(entry.normalizedDescription);
    final code = entry.code.toUpperCase();

    final positive =
        code == 'STS0/ST01' ||
        code == 'AA01/ST01' ||
        t.contains('STRAORDINARIODIURNO') ||
        t.contains('STRORESUPERODIURNO');

    final excluded =
        t.contains('NOTT') ||
        t.contains('FEST') ||
        t.contains('COMPENSAZIONE') ||
        t.contains('REP.MOBILI') ||
        t.contains('REPMOBILI') ||
        t.contains('LIMITEMAX') ||
        t.contains('ENTROLIMITE');

    return positive && !excluded;
  }

  bool _isNotturnoPuro(PayslipEntry entry) {
    final t = _norm(entry.normalizedDescription);
    final code = entry.code.toUpperCase();

    final positive =
        code == 'AA06/E1BL' ||
        t.contains('INDENNITASERVIZIONOTTURNO');

    final excluded =
        t.contains('FEST') ||
        t.contains('STRAORD') ||
        t.contains('COMPENSAZIONE') ||
        t.contains('REPMOBILI') ||
        t.contains('REP.MOBILI') ||
        t.contains('LIMITEMAX') ||
        t.contains('ENTROLIMITE');

    return positive && !excluded;
  }

  bool _isFestivoPuro(PayslipEntry entry) {
    final t = _norm(entry.normalizedDescription);
    final code = entry.code.toUpperCase();

    final positive =
        code == 'AA06/E1BJ' ||
        t.contains('INDENNITASERVIZIOFESTIVO');

    final excluded =
        t.contains('NOTT') ||
        t.contains('STRAORD') ||
        t.contains('COMPENSAZIONE') ||
        t.contains('REPMOBILI') ||
        t.contains('REP.MOBILI') ||
        t.contains('LIMITEMAX') ||
        t.contains('ENTROLIMITE');

    return positive && !excluded;
  }

  bool _isOrdinePubblicoInSedePuro(PayslipEntry entry) {
    final t = _norm(entry.normalizedDescription);
    final code = entry.code.toUpperCase();

    final positive =
        code == 'B003/0001' ||
        t.contains('ORD.PUBBL.INSEDE');

    final excluded =
        t.contains('1TURNO') ||
        t.contains('F.SEDE') ||
        t.contains('FUORISEDE') ||
        t.contains('PERNOTTO') ||
        t.contains('COMPENSAZIONE') ||
        t.contains('NOTT') ||
        t.contains('FEST') ||
        t.contains('STRAORD');

    return positive && !excluded;
  }

  bool _isServizioEsternoPuro(PayslipEntry entry) {
    final t = _norm(entry.normalizedDescription);
    final code = entry.code.toUpperCase();

    final positive =
        code == 'AA06/E1BW' ||
        t.contains('INDENNITAPRESENZASERVIZIESTERNI');

    final excluded =
        t.contains('COMPENSAZIONE') ||
        t.contains('NOTT') ||
        t.contains('FEST') ||
        t.contains('STRAORD');

    return positive && !excluded;
  }

  double? _averageUnitAmount(List<PayslipEntry> entries) {
    final values = <double>[];

    for (final entry in entries) {
      final unit = entry.unitAmount;
      final qty = entry.quantity ?? 0;

      if (unit != null && unit > 0) {
        values.add(unit);
        continue;
      }

      if (qty > 0) {
        values.add(entry.amount / qty);
      }
    }

    if (values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  String _norm(String value) {
    return value.toUpperCase().replaceAll(' ', '');
  }

  double _round2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}