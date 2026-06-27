import 'package:flutter/material.dart';

import 'models/department.dart';
import 'models/shift.dart';
import 'models/user_pay_profile.dart';

import '../application/usecases/build_daily_shift_result_usecase.dart';

enum SpmnPreset {
  none,
  sera,
  pomeriggio,
  mattina,
  notte,
  smontante,
  riposo,
  aggiornamento,
}

enum QuesturaProgrammedOvertimePreset {
  none,
  morning912,
  afternoon1518,
  evening2023,
}

class QuickAddShiftPage extends StatefulWidget {
  const QuickAddShiftPage({
    super.key,
    required this.onAdd,
    required this.rates,
    required this.activeDepartment,
    this.initialShift,
    this.initialDate,
    this.initialSuggestedSpmnPresetCode,
  });

  final void Function(Shift shift) onAdd;
  final UserPayProfile rates;
  final Department activeDepartment;
  final Shift? initialShift;
  final DateTime? initialDate;
  final String? initialSuggestedSpmnPresetCode;

  @override
  State<QuickAddShiftPage> createState() => _QuickAddShiftPageState();
}

class _QuickAddShiftPageState extends State<QuickAddShiftPage> {
  static const List<String> _orderPublicOptions = [
    'Nessuno',
    'In sede',
    'Fuori sede',
    'Pernotto',
  ];

  static const List<String> _absenceOptions = [
    'Nessuna',
    'Ferie',
    'Malattia',
    'Riposo',
    'Recupero compensativo',
    'Permesso',
    'Altro',
  ];

  static const List<TimeOfDay> _quickTimes = [
    TimeOfDay(hour: 6, minute: 55),
    TimeOfDay(hour: 7, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 12, minute: 55),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 18, minute: 55),
    TimeOfDay(hour: 19, minute: 0),
    TimeOfDay(hour: 23, minute: 0),
    TimeOfDay(hour: 23, minute: 55),
  ];

  static const List<SpmnPreset> _spmnPresetOptions = [
    SpmnPreset.none,
    SpmnPreset.sera,
    SpmnPreset.pomeriggio,
    SpmnPreset.mattina,
    SpmnPreset.notte,
    SpmnPreset.smontante,
    SpmnPreset.riposo,
    SpmnPreset.aggiornamento,
  ];

  static const double _genereDiConfortoCdgRate = 0.72;

  late final TextEditingController _descriptionController;
  late final TextEditingController _manualExtraAmountController;
  late final TextEditingController _manualExtraLabelController;
  late final TextEditingController _noteController;

  late final TextEditingController _polferReducedDayController;
  late final TextEditingController _polferReducedNightController;
  late final TextEditingController _polferFullDayController;
  late final TextEditingController _polferFullNightController;
  late final TextEditingController _compensativeOvertimeHoursController;
late final TextEditingController _compensativeOvertimeNoteController;
late final TextEditingController _compensativeRecoveryHoursController;
  late final TextEditingController _ordinaryHoursOverrideController;
late final TextEditingController _ordinaryHoursOverrideNoteController;

  late DateTime _serviceDate;
  late DateTime _realStartDate;
  late DateTime _absenceEndDate;

  bool _multiDayAbsence = false;
  late String _selectedOrderPublic;
  late String _selectedAbsence;
  late bool _externalService;

  late PolferTerritoryControlType _polferTerritoryControlType;
  late PolferScaloMode _polferScaloMode;
  late bool _polferScaloManualOverride;

  bool _showAdvanced = false;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isSaving = false;

  bool _includeGenereDiConfortoCdg = false;
  bool _includeGenereDiConforto = false;
  bool _includeTicketPasto = false;
  bool _includeCompensazione = false;
  bool _includeReperibilita = false;
  bool _includeAutostradaService = false;

  late SpmnPreset _selectedSpmnPreset;
  QuesturaMode _questuraMode = QuesturaMode.uffici;
QuesturaPreset _questuraPreset = QuesturaPreset.none;
QuesturaProgrammedOvertimePreset _questuraProgrammedOvertimePreset =
    QuesturaProgrammedOvertimePreset.none;
    bool _programmedOvertimeEnabled = false;

late TimeOfDay _programmedOvertimeStartTime;
late TimeOfDay _programmedOvertimeEndTime;
QuesturaOfficeProfile _questuraOfficeProfile =
    QuesturaOfficeProfile.sixHours;
  

  bool get _isEditing => widget.initialShift != null;
  bool get _hasAbsence => _selectedAbsence != 'Nessuna';
  bool get _isPolfer => widget.activeDepartment == Department.polfer;
bool get _isQuestura => widget.activeDepartment == Department.questura;
bool get _isPolstrada => widget.activeDepartment == Department.polstrada;

bool get _usesQuesturaPresetLogic => _isQuestura || _isPolstrada;

  bool get _hasPolferScalo => _polferScaloMode != PolferScaloMode.none;

  bool get _absenceNeedsCustomDescription =>
      _selectedAbsence == 'Permesso' || _selectedAbsence == 'Altro';

  bool get _isTuesdayUpdateCase =>
      _selectedSpmnPreset == SpmnPreset.riposo &&
      _serviceDate.weekday == DateTime.tuesday;

  bool get _isSmontanteOrRiposoLocked =>
      _selectedSpmnPreset == SpmnPreset.smontante ||
      (_selectedSpmnPreset == SpmnPreset.riposo && !_isTuesdayUpdateCase);

  UserPayProfile get _profile => widget.rates;

  OvertimeDestination _overtimeDestination =
    OvertimeDestination.payment;

  bool _ordinaryHoursOverrideEnabled = false;

TimeOfDay _ordinaryHoursOverrideTime =
    const TimeOfDay(hour: 6, minute: 0);

bool get _usesCompensativeOvertime =>
    _overtimeDestination == OvertimeDestination.compensative;

  double get _genereDiConfortoRate => _profile.genereDiConfortoRate;
  double get _ticketPastoRate => _profile.ticketPastoRate;

  @override
  void initState() {
    super.initState();

    final baseServiceDate =
        widget.initialShift?.serviceDate ?? widget.initialDate ?? DateTime.now();

    final normalizedBaseDate = _normalizeDate(baseServiceDate);

    final baseStart = widget.initialShift?.start ??
        DateTime(
          normalizedBaseDate.year,
          normalizedBaseDate.month,
          normalizedBaseDate.day,
          7,
          0,
        );

    final baseEnd = widget.initialShift?.end ??
        DateTime(
          normalizedBaseDate.year,
          normalizedBaseDate.month,
          normalizedBaseDate.day,
          13,
          0,
        );

    final initialShift = widget.initialShift;
    final initialManualLabel = initialShift?.manualExtraLabel ?? '';
    final initialManualAmount = initialShift?.manualExtraAmount ?? 0.0;

    final hadGenereCdg = initialShift?.genereDiConfortoCdg == true ||
        _containsGenereDiConfortoCdg(initialManualLabel);
    final hadGenere = initialShift?.genereDiConforto == true ||
        _containsGenereDiConforto(initialManualLabel);
    final hadTicket = initialShift?.ticketPasto == true ||
        _containsTicketPasto(initialManualLabel);

    final extractedAutoAmount =
        (hadGenereCdg ? _genereDiConfortoCdgRate : 0.0) +
            (hadGenere ? _genereDiConfortoRate : 0.0) +
            (hadTicket ? _ticketPastoRate : 0.0);

    final cleanedManualAmount = (initialManualAmount - extractedAutoAmount) < 0
        ? 0.0
        : (initialManualAmount - extractedAutoAmount);

    final cleanedManualLabel = _stripAutoLabels(initialManualLabel);

    _descriptionController = TextEditingController(
      text: initialShift?.description ?? '',
    );

    _manualExtraAmountController = TextEditingController(
      text: cleanedManualAmount > 0 ? cleanedManualAmount.toStringAsFixed(2) : '',
    );

    _manualExtraLabelController = TextEditingController(
      text: cleanedManualLabel,
    );

    _noteController = TextEditingController(
      text: initialShift?.note ?? '',
    );

    _polferReducedDayController = TextEditingController(
      text: (initialShift?.polferScaloReducedDayHours ?? 0) > 0
          ? initialShift!.polferScaloReducedDayHours.toStringAsFixed(2)
          : '',
    );

    _polferReducedNightController = TextEditingController(
      text: (initialShift?.polferScaloReducedNightHours ?? 0) > 0
          ? initialShift!.polferScaloReducedNightHours.toStringAsFixed(2)
          : '',
    );

    _polferFullDayController = TextEditingController(
      text: (initialShift?.polferScaloFullDayHours ?? 0) > 0
          ? initialShift!.polferScaloFullDayHours.toStringAsFixed(2)
          : '',
    );

    _polferFullNightController = TextEditingController(
      text: (initialShift?.polferScaloFullNightHours ?? 0) > 0
          ? initialShift!.polferScaloFullNightHours.toStringAsFixed(2)
          : '',
    );

    _compensativeOvertimeHoursController = TextEditingController(
  text: (initialShift?.compensativeOvertimeHours ?? 0) > 0
      ? initialShift!.compensativeOvertimeHours.toStringAsFixed(2)
      : '',
);

_compensativeOvertimeNoteController = TextEditingController(
  text: initialShift?.compensativeOvertimeNote ?? '',
);

_compensativeRecoveryHoursController = TextEditingController(
  text: (initialShift?.compensativeRecoveryHours ?? 0) > 0
      ? initialShift!.compensativeRecoveryHours.toStringAsFixed(2)
      : '6',
);

_overtimeDestination =
    initialShift?.overtimeDestination ??
        OvertimeDestination.payment;
_ordinaryHoursOverrideEnabled =
    initialShift?.ordinaryHoursOverrideEnabled ?? false;

_ordinaryHoursOverrideController = TextEditingController(
  text: (initialShift?.ordinaryHoursOverride ?? 0) > 0
      ? initialShift!.ordinaryHoursOverride.toStringAsFixed(2)
      : '',
);

_ordinaryHoursOverrideTime = _decimalHoursToTimeOfDay(
  initialShift?.ordinaryHoursOverride ?? 6.0,
);

_ordinaryHoursOverrideNoteController = TextEditingController(
  text: initialShift?.ordinaryHoursOverrideNote ?? '',
);

_programmedOvertimeEnabled =
    initialShift?.programmedOvertimeEnabled ?? false;

_programmedOvertimeStartTime = TimeOfDay(
  hour: initialShift?.programmedOvertimeStart?.hour ?? 20,
  minute: initialShift?.programmedOvertimeStart?.minute ?? 0,
);

_programmedOvertimeEndTime = TimeOfDay(
  hour: initialShift?.programmedOvertimeEnd?.hour ?? 23,
  minute: initialShift?.programmedOvertimeEnd?.minute ?? 0,
);

    _serviceDate = _normalizeDate(baseServiceDate);
    _realStartDate = _normalizeDate(baseStart);
    _absenceEndDate = _serviceDate;

    _startTime = TimeOfDay(hour: baseStart.hour, minute: baseStart.minute);
    _endTime = TimeOfDay(hour: baseEnd.hour, minute: baseEnd.minute);

    _selectedOrderPublic = initialShift?.orderPublic ?? 'Nessuno';
    if (!_orderPublicOptions.contains(_selectedOrderPublic)) {
      _selectedOrderPublic = 'Nessuno';
    }

    _selectedAbsence =
        _initialAbsenceUiValue(initialShift?.absence ?? 'Nessuna');
    _externalService = initialShift?.externalService ?? false;

    _polferTerritoryControlType =
        initialShift?.polferTerritoryControlType ??
            PolferTerritoryControlType.none;
    _polferScaloMode = initialShift?.polferScaloMode ?? PolferScaloMode.none;
    _polferScaloManualOverride =
        initialShift?.polferScaloManualOverride ?? false;
    _questuraMode =
    initialShift?.questuraMode ?? QuesturaMode.uffici;

_questuraPreset =
    initialShift?.questuraPreset ?? QuesturaPreset.none;

_questuraOfficeProfile =
    initialShift?.questuraOfficeProfile ??
        QuesturaOfficeProfile.sixHours;    

    _includeGenereDiConfortoCdg = hadGenereCdg;
    _includeGenereDiConforto = hadGenere;
    _includeTicketPasto = hadTicket;
    _includeCompensazione = initialShift?.hasCompensazione ?? false;
    _includeReperibilita = initialShift?.hasReperibilita ?? false;
    _includeAutostradaService =
    initialShift?.hasAutostradaService ?? false;

    _showAdvanced = initialShift != null &&
        (cleanedManualAmount > 0 ||
            cleanedManualLabel.trim().isNotEmpty ||
            initialShift.note.trim().isNotEmpty);

    _selectedSpmnPreset = _inferInitialSpmnPreset();

    if (_hasAbsence) {
      _applyAbsenceConstraints();
      if (!_absenceNeedsCustomDescription &&
          _descriptionController.text.trim().isEmpty) {
        _descriptionController.text =
            _defaultAbsenceDescription(_selectedAbsence);
      }
    }

    if (!_isEditing &&
        _isPolfer &&
        _selectedSpmnPreset == SpmnPreset.none &&
        (widget.initialSuggestedSpmnPresetCode?.trim().isNotEmpty ?? false)) {
      final suggested = _presetFromCode(widget.initialSuggestedSpmnPresetCode!);
      if (suggested != SpmnPreset.none) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _applySpmnPreset(
            suggested,
            showFeedback: false,
          );
        });
      }
    }
  }

  SpmnPreset _spmnPresetFromQuesturaPreset(QuesturaPreset preset) {
  switch (preset) {
    case QuesturaPreset.none:
      return SpmnPreset.none;
    case QuesturaPreset.mattina:
      return SpmnPreset.mattina;
    case QuesturaPreset.pomeriggio:
      return SpmnPreset.pomeriggio;
    case QuesturaPreset.sera:
      return SpmnPreset.sera;
    case QuesturaPreset.notte:
      return SpmnPreset.notte;
    case QuesturaPreset.smontante:
      return SpmnPreset.smontante;
    case QuesturaPreset.riposo:
      return SpmnPreset.riposo;
    case QuesturaPreset.aggiornamento:
      return SpmnPreset.aggiornamento;
  }
}

  @override
  void dispose() {
    _descriptionController.dispose();
    _manualExtraAmountController.dispose();
    _manualExtraLabelController.dispose();
    _noteController.dispose();
    _polferReducedDayController.dispose();
    _polferReducedNightController.dispose();
    _polferFullDayController.dispose();
    _polferFullNightController.dispose();
    _compensativeOvertimeHoursController.dispose();
_compensativeOvertimeNoteController.dispose();
_compensativeRecoveryHoursController.dispose();
_ordinaryHoursOverrideController.dispose();
_ordinaryHoursOverrideNoteController.dispose();
    super.dispose();
  }

  String _initialAbsenceUiValue(String value) {
    switch (value.trim().toUpperCase()) {
      case 'C.O.':
      case 'C.O':
      case 'FERIE':
        return 'Ferie';
      case 'C.S.':
      case 'C.S':
      case 'MAL':
      case 'MALATTIA':
        return 'Malattia';
      case 'RIP':
      case 'RIPOSO':
        return 'Riposo';
      case 'NESSUNA':
        return 'Nessuna';
      default:
        return value;
    }
  }

  SpmnPreset _presetFromCode(String code) {
    switch (code.trim().toLowerCase()) {
      case 'sera':
        return SpmnPreset.sera;
      case 'pomeriggio':
        return SpmnPreset.pomeriggio;
      case 'mattina':
        return SpmnPreset.mattina;
      case 'notte':
        return SpmnPreset.notte;
      case 'smontante':
        return SpmnPreset.smontante;
      case 'riposo':
        return SpmnPreset.riposo;
      case 'aggiornamento':
        return SpmnPreset.aggiornamento;
      default:
        return SpmnPreset.none;
    }
  }

  SpmnPreset _inferInitialSpmnPreset() {
    final shift = widget.initialShift;
    if (shift == null) return SpmnPreset.none;

    final codePreset = _presetFromCode(shift.spmnPresetCode);
    if (codePreset != SpmnPreset.none) return codePreset;

    final desc = shift.description.trim().toLowerCase();
    final absence = shift.absence.trim().toLowerCase();

    if (desc == 'aggiornamento') return SpmnPreset.aggiornamento;
    if (absence == 'riposo' || absence == 'rip') return SpmnPreset.riposo;
    if (desc == 'smontante') return SpmnPreset.smontante;
    if (desc == 'turno sera') return SpmnPreset.sera;
    if (desc == 'turno pomeriggio') return SpmnPreset.pomeriggio;
    if (desc == 'turno mattina') return SpmnPreset.mattina;
    if (desc == 'turno notte') return SpmnPreset.notte;

    return SpmnPreset.none;
  }

  String _spmnPresetLabel(SpmnPreset preset) {
    switch (preset) {
      case SpmnPreset.none:
        return 'Nessuno';
      case SpmnPreset.sera:
        return 'Sera';
      case SpmnPreset.pomeriggio:
        return 'Pomeriggio';
      case SpmnPreset.mattina:
        return 'Mattina';
      case SpmnPreset.notte:
        return 'Notte';
      case SpmnPreset.smontante:
        return 'Smontante';
      case SpmnPreset.riposo:
        return 'Riposo';
      case SpmnPreset.aggiornamento:
        return 'Aggiornamento';
    }
  }

  String _questuraProgrammedOvertimeLabel(
  QuesturaProgrammedOvertimePreset preset,
) {
  switch (preset) {
    case QuesturaProgrammedOvertimePreset.none:
      return 'Nessuno';
    case QuesturaProgrammedOvertimePreset.morning912:
      return '09:00 → 12:00';
    case QuesturaProgrammedOvertimePreset.afternoon1518:
      return '15:00 → 18:00';
    case QuesturaProgrammedOvertimePreset.evening2023:
      return '20:00 → 23:00';
  }
}

  String _spmnPresetSummary(SpmnPreset preset) {
    switch (preset) {
      case SpmnPreset.none:
        return 'Compilazione manuale.';
      case SpmnPreset.sera:
        return 'Orario preset: 18:55 → 00:08';
      case SpmnPreset.pomeriggio:
        return 'Orario preset: 12:55 → 19:08';
      case SpmnPreset.mattina:
        return 'Orario preset: 06:55 → 13:08';
      case SpmnPreset.notte:
        return 'Orario preset: 23:55 → 07:08';
      case SpmnPreset.smontante:
        return 'Giornata non operativa.';
      case SpmnPreset.riposo:
        return _serviceDate.weekday == DateTime.tuesday
            ? 'Martedì: il riposo diventa aggiornamento 08:00 → 14:00'
            : 'Riposo standard senza orari.';
      case SpmnPreset.aggiornamento:
        return 'Orario preset: 08:00 → 14:00';
    }
  }

  void _showPresetAppliedMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _applySpmnPreset(
    SpmnPreset preset, {
    bool showFeedback = true,
  }) {
    setState(() {
      _selectedSpmnPreset = preset;

      switch (preset) {
        case SpmnPreset.none:
          break;

        case SpmnPreset.sera:
          _selectedAbsence = 'Nessuna';
          _descriptionController.text = 'Turno Sera';
          _realStartDate = _serviceDate;
          _startTime = const TimeOfDay(hour: 18, minute: 55);

_endTime = _isPolstrada
    ? const TimeOfDay(hour: 1, minute: 8)
    : const TimeOfDay(hour: 0, minute: 8);
          break;

        case SpmnPreset.pomeriggio:
          _selectedAbsence = 'Nessuna';
          _descriptionController.text = 'Turno Pomeriggio';
          _realStartDate = _serviceDate;
          _startTime = const TimeOfDay(hour: 12, minute: 55);
          _endTime = const TimeOfDay(hour: 19, minute: 8);
          break;

        case SpmnPreset.mattina:
          _selectedAbsence = 'Nessuna';
          _descriptionController.text = 'Turno Mattina';
          _realStartDate = _serviceDate;
          _startTime = const TimeOfDay(hour: 6, minute: 55);
          _endTime = const TimeOfDay(hour: 13, minute: 8);
          break;

        case SpmnPreset.notte:
  _selectedAbsence = 'Nessuna';
  _descriptionController.text = 'Turno Notte';

  _realStartDate = _isPolstrada
    ? _serviceDate
    : _serviceDate.subtract(
        const Duration(days: 1),
      );

_startTime = _isPolstrada
    ? const TimeOfDay(hour: 0, minute: 55)
    : const TimeOfDay(hour: 23, minute: 55);

_endTime = const TimeOfDay(hour: 7, minute: 8);

  break;

        case SpmnPreset.smontante:
          _selectedAbsence = 'Riposo';
          _applyAbsenceConstraints();
          _descriptionController.text = 'Smontante';
          break;

        case SpmnPreset.riposo:
          if (_serviceDate.weekday == DateTime.tuesday) {
            _selectedAbsence = 'Nessuna';
            _descriptionController.text = 'Aggiornamento';
            _realStartDate = _serviceDate;
            _startTime = const TimeOfDay(hour: 8, minute: 0);
            _endTime = const TimeOfDay(hour: 14, minute: 0);
            _externalService = false;
            _selectedOrderPublic = 'Nessuno';
            _includeGenereDiConfortoCdg = false;
            _includeGenereDiConforto = false;
            _includeTicketPasto = false;
            _clearPolferFields();
          } else {
            _selectedAbsence = 'Riposo';
            _applyAbsenceConstraints();
            _descriptionController.text = 'Riposo';
          }
          break;

        case SpmnPreset.aggiornamento:
          _selectedAbsence = 'Nessuna';
          _descriptionController.text = 'Aggiornamento';
          _realStartDate = _serviceDate;
          _startTime = const TimeOfDay(hour: 8, minute: 0);
          _endTime = const TimeOfDay(hour: 14, minute: 0);
          _externalService = false;
          _selectedOrderPublic = 'Nessuno';
          _includeGenereDiConfortoCdg = false;
          _includeGenereDiConforto = false;
          _includeTicketPasto = false;
          _clearPolferFields();
          break;
      }
    });

    if (!mounted || !showFeedback) return;

    switch (preset) {
      case SpmnPreset.none:
        _showPresetAppliedMessage('Preset disattivato');
        break;
      case SpmnPreset.riposo:
        if (_serviceDate.weekday == DateTime.tuesday) {
          _showPresetAppliedMessage(
            'Riposo trasformato in aggiornamento (08:00 - 14:00)',
          );
        } else {
          _showPresetAppliedMessage('Preset applicato: Riposo');
        }
        break;
      default:
        _showPresetAppliedMessage(
          'Preset applicato: ${_spmnPresetLabel(preset)}',
        );
        break;
    }
  }

  String _normalizedAbsenceForSave(String value) {
    switch (value.trim().toLowerCase()) {
      case 'malattia':
      case 'mal':
      case 'c.s.':
      case 'c.s':
        return 'C.S.';
      case 'ferie':
      case 'c.o.':
      case 'c.o':
        return 'C.O.';
      case 'riposo':
      case 'rip':
        return 'RIP';
      default:
        return value;
    }
  }

  bool _containsGenereDiConfortoCdg(String label) {
    return label.toLowerCase().contains('genere di conforto cdg');
  }

  bool _containsGenereDiConforto(String label) {
    final lower = label.toLowerCase();
    return lower.contains('genere di conforto') &&
        !lower.contains('genere di conforto cdg');
  }

  bool _containsTicketPasto(String label) {
    return label.toLowerCase().contains('ticket pasto');
  }

  String _stripAutoLabels(String label) {
    if (label.trim().isEmpty) return '';

    final parts = label
        .split('•')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where(
          (e) =>
              e.toLowerCase() != 'genere di conforto cdg' &&
              e.toLowerCase() != 'genere di conforto' &&
              e.toLowerCase() != 'ticket pasto',
        )
        .toList();

    return parts.join(' • ');
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0.0;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  double _timeOfDayToDecimalHours(TimeOfDay time) {
  return time.hour + (time.minute / 60.0);
}

TimeOfDay _decimalHoursToTimeOfDay(double value) {
  final totalMinutes = (value * 60).round();

  return TimeOfDay(
    hour: totalMinutes ~/ 60,
    minute: totalMinutes % 60,
  );
}

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _formatCurrency(double value) {
    return '€ ${value.toStringAsFixed(2)}';
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  TimeOfDay _addSixHours(TimeOfDay start) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = (startMinutes + 360) % (24 * 60);
    return TimeOfDay(
      hour: endMinutes ~/ 60,
      minute: endMinutes % 60,
    );
  }

  String _defaultAbsenceDescription(String absence) {
    switch (absence) {
      case 'Ferie':
        return 'Ferie';
      case 'Malattia':
        return 'Malattia';
      case 'Riposo':
        return 'Riposo';
      case 'Permesso':
        return 'Permesso';
      case 'Recupero compensativo':
  return 'Recupero compensativo';
      case 'Altro':
        return 'Altro';
      default:
        return '';
    }
  }

  String _territoryControlLabel(PolferTerritoryControlType type) {
    switch (type) {
      case PolferTerritoryControlType.none:
        return 'Nessuno';
      case PolferTerritoryControlType.serale:
        return 'Serale';
      case PolferTerritoryControlType.notturno:
        return 'Notturno';
    }
  }

  String _scaloModeLabel(PolferScaloMode mode) {
    switch (mode) {
      case PolferScaloMode.none:
        return 'Nessuno';
      case PolferScaloMode.ridotta:
        return 'Ridotta';
      case PolferScaloMode.intera:
        return 'Intera';
    }
  }

  String _questuraModeLabel(QuesturaMode mode) {
  switch (mode) {
    case QuesturaMode.uffici:
      return 'Uffici';
    case QuesturaMode.volanti:
      return _isPolstrada ? 'Pattuglia' : 'Volanti';
  }
}

String _questuraPresetLabel(QuesturaPreset preset) {
  switch (preset) {
    case QuesturaPreset.none:
      return 'Nessuno';
    case QuesturaPreset.mattina:
      return 'Mattina';
    case QuesturaPreset.pomeriggio:
      return 'Pomeriggio';
    case QuesturaPreset.sera:
      return 'Sera';
    case QuesturaPreset.notte:
      return 'Notte';
    case QuesturaPreset.smontante:
      return 'Smontante';
    case QuesturaPreset.riposo:
      return 'Riposo';
    case QuesturaPreset.aggiornamento:
      return 'Aggiornamento';
  }
}

String _questuraOfficeProfileLabel(QuesturaOfficeProfile profile) {
  switch (profile) {
    case QuesturaOfficeProfile.sixHours:
      return '6 ore';
    case QuesturaOfficeProfile.settimanaCorta:
      return 'Settimana corta';
    case QuesturaOfficeProfile.settimanaLunga:
      return 'Settimana lunga';
    case QuesturaOfficeProfile.custom:
      return 'Personalizzato';
  }
}

double _questuraOfficeOrdinaryHours() {
  switch (_questuraOfficeProfile) {
    case QuesturaOfficeProfile.custom:
      return _ordinaryHoursOverrideEnabled
          ? double.tryParse(
                _ordinaryHoursOverrideController.text.replaceAll(',', '.'),
              ) ??
              6.0
          : 6.0;

    case QuesturaOfficeProfile.sixHours:
    case QuesturaOfficeProfile.settimanaCorta:
    case QuesturaOfficeProfile.settimanaLunga:
      return 6.0;
  }
}

DateTime? _buildQuesturaProgrammedOvertimeStart() {
  if (!_usesQuesturaPresetLogic|| _questuraMode != QuesturaMode.volanti) {
    return null;
  }

  switch (_questuraProgrammedOvertimePreset) {
    case QuesturaProgrammedOvertimePreset.morning912:
      return DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day, 9);
    case QuesturaProgrammedOvertimePreset.afternoon1518:
      return DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day, 15);
    case QuesturaProgrammedOvertimePreset.evening2023:
      return DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day, 20);
    case QuesturaProgrammedOvertimePreset.none:
      return null;
  }
}

DateTime? _buildQuesturaProgrammedOvertimeEnd() {
  if (!_usesQuesturaPresetLogic || _questuraMode != QuesturaMode.volanti) {
    return null;
  }

  switch (_questuraProgrammedOvertimePreset) {
    case QuesturaProgrammedOvertimePreset.morning912:
      return DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day, 12);
    case QuesturaProgrammedOvertimePreset.afternoon1518:
      return DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day, 18);
    case QuesturaProgrammedOvertimePreset.evening2023:
      return DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day, 23);
    case QuesturaProgrammedOvertimePreset.none:
      return null;
  }
}

DateTime? _buildCustomProgrammedOvertimeStart() {
  if (!_programmedOvertimeEnabled) return null;

  return DateTime(
    _serviceDate.year,
    _serviceDate.month,
    _serviceDate.day,
    _programmedOvertimeStartTime.hour,
    _programmedOvertimeStartTime.minute,
  );
}

DateTime? _buildCustomProgrammedOvertimeEnd() {
  if (!_programmedOvertimeEnabled) return null;

  final startMinutes =
      _programmedOvertimeStartTime.hour * 60 + _programmedOvertimeStartTime.minute;
  final endMinutes =
      _programmedOvertimeEndTime.hour * 60 + _programmedOvertimeEndTime.minute;

  return DateTime(
    _serviceDate.year,
    _serviceDate.month,
    _serviceDate.day + (endMinutes <= startMinutes ? 1 : 0),
    _programmedOvertimeEndTime.hour,
    _programmedOvertimeEndTime.minute,
  );
}

  void _clearPolferFields() {
    _polferTerritoryControlType = PolferTerritoryControlType.none;
    _polferScaloMode = PolferScaloMode.none;
    _polferScaloManualOverride = false;
    _polferReducedDayController.text = '';
    _polferReducedNightController.text = '';
    _polferFullDayController.text = '';
    _polferFullNightController.text = '';
  }

  void _applyAbsenceConstraints() {
    _selectedOrderPublic = 'Nessuno';
    _externalService = false;
    _manualExtraAmountController.text = '';
    _manualExtraLabelController.text = '';
    _includeGenereDiConfortoCdg = false;
    _includeGenereDiConforto = false;
    _includeTicketPasto = false;
    _clearPolferFields();

    if (_absenceEndDate.isBefore(_serviceDate)) {
      _absenceEndDate = _serviceDate;
    }

    _realStartDate = _serviceDate;
    _startTime = const TimeOfDay(hour: 0, minute: 0);
    _endTime = const TimeOfDay(hour: 0, minute: 0);

    if (!_absenceNeedsCustomDescription) {
      _descriptionController.text =
          _defaultAbsenceDescription(_selectedAbsence);
    }
  }

  double _autoMealAndComfortAmount() {
    if (_hasAbsence) return 0.0;

    double total = 0.0;

    if (_includeGenereDiConfortoCdg) {
      total += _genereDiConfortoCdgRate;
    }

    if (_includeGenereDiConforto) {
      total += _genereDiConfortoRate;
    }

    if (_includeTicketPasto) {
      total += _ticketPastoRate;
    }

    return total;
  }

  Shift _buildShiftPreview() {
    final manualAmount = _parseDouble(_manualExtraAmountController.text);
    final manualLabel = _manualExtraLabelController.text.trim();

    final reducedDay = _parseDouble(_polferReducedDayController.text);
    final reducedNight = _parseDouble(_polferReducedNightController.text);
    final fullDay = _parseDouble(_polferFullDayController.text);
    final fullNight = _parseDouble(_polferFullNightController.text);

    if (_hasAbsence) {
      final description = _descriptionController.text.trim().isEmpty
          ? _defaultAbsenceDescription(_selectedAbsence)
          : _descriptionController.text.trim();

      return Shift(
        description: description,
        start: DateTime(
  _serviceDate.year,
  _serviceDate.month,
  _serviceDate.day,
  8,
  0,
),
end: DateTime(
  _serviceDate.year,
  _serviceDate.month,
  _serviceDate.day,
  14,
  0,
),
        serviceDate: _serviceDate,
        orderPublic: 'Nessuno',
        externalService: false,
        absence: _normalizedAbsenceForSave(_selectedAbsence),
        manualExtraAmount: 0,
        manualExtraLabel: '',
        genereDiConfortoCdg: false,
        genereDiConforto: false,
        ticketPasto: false,
        overtimeDestination: OvertimeDestination.payment,
compensativeOvertimeHours: 0.0,
compensativeOvertimeNote: '',
compensativeRecoveryHours:
    _selectedAbsence == 'Recupero compensativo'
        ? _parseDouble(_compensativeRecoveryHoursController.text)
        : 0.0,
        ordinaryHoursOverrideEnabled: false,
        programmedOvertimeEnabled: false,
programmedOvertimeStart: null,
programmedOvertimeEnd: null,
programmedOvertimeNote: '',
        
ordinaryHoursOverride: 0.0,
ordinaryHoursOverrideNote: '',
questuraMode: QuesturaMode.uffici,
questuraPreset: QuesturaPreset.none,
questuraOfficeProfile: QuesturaOfficeProfile.sixHours,
questuraOfficeOrdinaryHours: 6.0,
        hasCompensazione: false,
        hasReperibilita: false,
        hasAutostradaService: false,
        note: _noteController.text.trim(),
        polferTerritoryControlType: PolferTerritoryControlType.none,
        polferScaloMode: PolferScaloMode.none,
        polferScaloManualOverride: false,
        polferScaloReducedDayHours: 0,
        polferScaloReducedNightHours: 0,
        polferScaloFullDayHours: 0,
        polferScaloFullNightHours: 0,
        spmnPresetCode: _usesQuesturaPresetLogic
    ? (_questuraPreset == QuesturaPreset.none ? '' : _questuraPreset.name)
    : (_selectedSpmnPreset == SpmnPreset.none ? '' : _selectedSpmnPreset.name),
      );
    }

    final start = _combine(_realStartDate, _startTime);

final isPolstradaNightPreset =
    _isPolstrada && _questuraPreset == QuesturaPreset.notte;

var end = _combine(
  isPolstradaNightPreset ? _realStartDate : _serviceDate,
  _endTime,
);

if (!end.isAfter(start)) {
  end = end.add(const Duration(days: 1));
}

    return Shift(
      description: _descriptionController.text.trim(),
      start: start,
      end: end,
      serviceDate: _serviceDate,
      orderPublic: _selectedOrderPublic,
      externalService: _externalService,
      absence: 'Nessuna',
      manualExtraAmount: manualAmount,
      manualExtraLabel: manualLabel,
      genereDiConfortoCdg:
    widget.activeDepartment == Department.repartoMobile
        ? _includeGenereDiConfortoCdg
        : false,
genereDiConforto:
    widget.activeDepartment == Department.repartoMobile
        ? _includeGenereDiConforto
        : false,
ticketPasto: _includeTicketPasto,
      
overtimeDestination: _overtimeDestination,
compensativeOvertimeHours:
    _usesCompensativeOvertime
        ? _parseDouble(_compensativeOvertimeHoursController.text)
        : 0.0,
compensativeOvertimeNote:
    _usesCompensativeOvertime
        ? _compensativeOvertimeNoteController.text.trim()
        : '',
      ordinaryHoursOverrideEnabled:
    _ordinaryHoursOverrideEnabled,


ordinaryHoursOverride:
    _ordinaryHoursOverrideEnabled
        ? _timeOfDayToDecimalHours(
            _ordinaryHoursOverrideTime,
          )
        : 0.0,

programmedOvertimeEnabled:
    _programmedOvertimeEnabled ||
    (_usesQuesturaPresetLogic &&
        _questuraMode == QuesturaMode.volanti &&
        _questuraProgrammedOvertimePreset !=
            QuesturaProgrammedOvertimePreset.none),

programmedOvertimeStart:
    _programmedOvertimeEnabled
        ? _buildCustomProgrammedOvertimeStart()
        : _buildQuesturaProgrammedOvertimeStart(),

programmedOvertimeEnd:
    _programmedOvertimeEnabled
        ? _buildCustomProgrammedOvertimeEnd()
        : _buildQuesturaProgrammedOvertimeEnd(),

programmedOvertimeNote:
    _programmedOvertimeEnabled
        ? 'Straordinario programmato personalizzato'
        : (_usesQuesturaPresetLogic &&
                _questuraMode == QuesturaMode.volanti &&
                _questuraProgrammedOvertimePreset !=
                    QuesturaProgrammedOvertimePreset.none
            ? (_isPolstrada ? 'Straordinario programmato Pattuglia' : 'Straordinario programmato Volanti')
            : ''),
questuraMode:
    _usesQuesturaPresetLogic ? _questuraMode : QuesturaMode.uffici,

questuraPreset:
    _usesQuesturaPresetLogic ? _questuraPreset : QuesturaPreset.none,

questuraOfficeProfile:
    _usesQuesturaPresetLogic
        ? _questuraOfficeProfile
        : QuesturaOfficeProfile.sixHours,

questuraOfficeOrdinaryHours:
    _usesQuesturaPresetLogic
        ? _questuraOfficeOrdinaryHours()
        : 6.0,

      hasCompensazione: _includeCompensazione,
      hasReperibilita: _includeReperibilita,
      hasAutostradaService: _includeAutostradaService,
      note: _noteController.text.trim(),
      polferTerritoryControlType:
    (_isPolfer || (_usesQuesturaPresetLogic && _questuraMode == QuesturaMode.volanti))
        ? _polferTerritoryControlType
        : PolferTerritoryControlType.none,
      polferScaloMode:
          _isPolfer ? _polferScaloMode : PolferScaloMode.none,
      polferScaloManualOverride:
          _isPolfer && _hasPolferScalo ? _polferScaloManualOverride : false,
      polferScaloReducedDayHours:
          _isPolfer && _hasPolferScalo && _polferScaloManualOverride
              ? reducedDay
              : 0.0,
      polferScaloReducedNightHours:
          _isPolfer && _hasPolferScalo && _polferScaloManualOverride
              ? reducedNight
              : 0.0,
      polferScaloFullDayHours:
          _isPolfer && _hasPolferScalo && _polferScaloManualOverride
              ? fullDay
              : 0.0,
      polferScaloFullNightHours:
          _isPolfer && _hasPolferScalo && _polferScaloManualOverride
              ? fullNight
              : 0.0,
      spmnPresetCode:
          _selectedSpmnPreset == SpmnPreset.none ? '' : _selectedSpmnPreset.name,
    );
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
      locale: const Locale('it'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _QuickAddPalette.primary,
              secondary: _QuickAddPalette.info,
              surface: _QuickAddPalette.card,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: _QuickAddPalette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final currentPreset = _selectedSpmnPreset;

    setState(() {
      _serviceDate = _normalizeDate(picked);

      if (_hasAbsence || _realStartDate.isAfter(_serviceDate)) {
        _realStartDate = _serviceDate;
      }

      if (_absenceEndDate.isBefore(_serviceDate)) {
        _absenceEndDate = _serviceDate;
      }
    });

    if (currentPreset != SpmnPreset.none) {
      _applySpmnPreset(currentPreset, showFeedback: false);
    }
  }

  Future<void> _pickRealStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _realStartDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
      locale: const Locale('it'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _QuickAddPalette.primary,
              secondary: _QuickAddPalette.info,
              surface: _QuickAddPalette.card,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: _QuickAddPalette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
  _realStartDate = _normalizeDate(picked);
});
  }

  Future<void> _pickAbsenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _absenceEndDate,
      firstDate: _serviceDate,
      lastDate: DateTime(DateTime.now().year + 3),
      locale: const Locale('it'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _QuickAddPalette.primary,
              secondary: _QuickAddPalette.info,
              surface: _QuickAddPalette.card,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: _QuickAddPalette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _absenceEndDate = _normalizeDate(picked);
    });
  }

  void _setStartTime(TimeOfDay start) {
  setState(() {
    _startTime = start;

    if (_selectedSpmnPreset == SpmnPreset.none) {
      _endTime = _addSixHours(start);
    }
  });
}

  Future<void> _pickCustomStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _QuickAddPalette.primary,
              secondary: _QuickAddPalette.info,
              surface: _QuickAddPalette.card,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: _QuickAddPalette.card,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    _setStartTime(picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _QuickAddPalette.primary,
              secondary: _QuickAddPalette.info,
              surface: _QuickAddPalette.card,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: _QuickAddPalette.card,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
  _endTime = picked;
});
  }

  Future<void> _openStartTimeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _QuickAddPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Seleziona ora inizio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _quickTimes.map((time) {
                    final isSelected = time.hour == _startTime.hour &&
                        time.minute == _startTime.minute;

                    return InkWell(
                      onTap: () {
                        _setStartTime(time);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _QuickAddPalette.primary
                              : _QuickAddPalette.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _QuickAddPalette.primary
                                : _QuickAddPalette.cardBorder,
                          ),
                        ),
                        child: Text(
                          _formatTimeOfDay(time),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _pickCustomStartTime();
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Orario personalizzato'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _QuickAddPalette.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _QuickAddPalette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _QuickAddPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _QuickAddPalette.cardBorder),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _QuickAddPalette.info,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13.2,
                  color: _QuickAddPalette.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    IconData icon = Icons.chevron_right_rounded,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.46,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: _QuickAddPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _QuickAddPalette.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _QuickAddPalette.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: _QuickAddPalette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildInformativeRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _QuickAddPalette.textSecondary,
              fontSize: 13.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _QuickAddPalette.textSecondary,
                fontSize: 13.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              color: _QuickAddPalette.primary,
              fontSize: 13.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpmnFields() {
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Preset turnazione SPMN',
            subtitle:
                'Seleziona il turno tipico oppure usa il suggerimento già proposto per il giorno scelto.',
            icon: Icons.view_timeline_rounded,
          ),
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: _hasAbsence,
            child: Opacity(
              opacity: _hasAbsence ? 0.46 : 1,
              child: DropdownButtonFormField<SpmnPreset>(
                initialValue: _selectedSpmnPreset,
                dropdownColor: _QuickAddPalette.card,
                decoration: const InputDecoration(
                  labelText: 'Preset turno',
                ),
                items: _spmnPresetOptions
                    .map(
                      (item) => DropdownMenuItem<SpmnPreset>(
                        value: item,
                        child: Text(_spmnPresetLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _applySpmnPreset(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _QuickAddPalette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _QuickAddPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dettaglio preset',
                  style: TextStyle(
                    fontSize: 13.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _spmnPresetSummary(_selectedSpmnPreset),
                  style: const TextStyle(
                    color: _QuickAddPalette.textSecondary,
                    fontSize: 13.0,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedSpmnPreset == SpmnPreset.notte) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _QuickAddPalette.info.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _QuickAddPalette.info.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'Fine turno il giorno successivo',
                      style: TextStyle(
                        color: _QuickAddPalette.info,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (_isTuesdayUpdateCase) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _QuickAddPalette.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _QuickAddPalette.primary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'Martedì: il riposo diventa aggiornamento 08:00 - 14:00',
                      style: TextStyle(
                        color: _QuickAddPalette.primary,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (_selectedSpmnPreset == SpmnPreset.riposo &&
                    !_isTuesdayUpdateCase) ...[
                  const SizedBox(height: 10),
                  _buildRiposoLockInfoCard(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiposoLockInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _QuickAddPalette.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _QuickAddPalette.info.withValues(alpha: 0.24),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _QuickAddPalette.info,
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hai selezionato Riposo. In questa modalità il servizio resta bloccato perché viene trattato come assenza. Per inserire un turno operativo cambia la voce Assenza da Riposo a Nessuna.',
              style: TextStyle(
                color: _QuickAddPalette.info,
                fontSize: 12.8,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuesturaFields() {
  if (_isPolstrada && _questuraMode != QuesturaMode.volanti) {
    _questuraMode = QuesturaMode.volanti;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
  _isPolstrada
      ? 'Configurazione Polizia Stradale'
      : 'Configurazione Questura',
  style: const TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    color: _QuickAddPalette.info,
  ),
),
      const SizedBox(height: 12),

      DropdownButtonFormField<QuesturaMode>(
        initialValue: _questuraMode,
        dropdownColor: _QuickAddPalette.card,
        decoration: const InputDecoration(
          labelText: 'Tipo servizio',
        ),
        items: QuesturaMode.values
            .map(
              (item) => DropdownMenuItem<QuesturaMode>(
                value: item,
                child: Text(_questuraModeLabel(item)),
              ),
            )
            .toList(),
        onChanged: _hasAbsence
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _questuraMode = value;

                  if (value == QuesturaMode.volanti) {
                    _externalService = true;
                    _questuraOfficeProfile = QuesturaOfficeProfile.sixHours;
                  } else {
                    _questuraPreset = QuesturaPreset.none;
                    _polferTerritoryControlType =
                        PolferTerritoryControlType.none;
                  }
                });
              },
      ),

      if (_questuraMode == QuesturaMode.volanti || _isPolstrada) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<QuesturaPreset>(
          initialValue: _questuraPreset,
          dropdownColor: _QuickAddPalette.card,
          decoration: InputDecoration(
  labelText: _isPolstrada ? 'Preset Pattuglia' : 'Preset Volanti',
),
          items: QuesturaPreset.values
              .map(
                (item) => DropdownMenuItem<QuesturaPreset>(
                  value: item,
                  child: Text(_questuraPresetLabel(item)),
                ),
              )
              .toList(),
          onChanged: _hasAbsence
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _questuraPreset = value;
                  });

                  _applySpmnPreset(
                    _spmnPresetFromQuesturaPreset(value),
                    showFeedback: false,
                  );
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PolferTerritoryControlType>(
          initialValue: _polferTerritoryControlType,
          dropdownColor: _QuickAddPalette.card,
          decoration: const InputDecoration(
            labelText: 'Controllo del territorio',
          ),
          items: PolferTerritoryControlType.values
              .map(
                (item) => DropdownMenuItem<PolferTerritoryControlType>(
                  value: item,
                  child: Text(_territoryControlLabel(item)),
                ),
              )
              .toList(),
          onChanged: _hasAbsence
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _polferTerritoryControlType = value;
                  });
                },
        ),
      ],
      const SizedBox(height: 12),
DropdownButtonFormField<QuesturaProgrammedOvertimePreset>(
  value: _questuraProgrammedOvertimePreset,
  dropdownColor: _QuickAddPalette.card,
  decoration: const InputDecoration(
    labelText: 'Straordinario programmato',
  ),
  items: QuesturaProgrammedOvertimePreset.values
      .map(
        (item) => DropdownMenuItem<QuesturaProgrammedOvertimePreset>(
          value: item,
          child: Text(_questuraProgrammedOvertimeLabel(item)),
        ),
      )
      .toList(),
  onChanged: _hasAbsence
      ? null
      : (value) {
          if (value == null) return;
          setState(() {
            _questuraProgrammedOvertimePreset = value;
          });
        },
),
const SizedBox(height: 12),



if (_programmedOvertimeEnabled) ...[
  const SizedBox(height: 12),
  Row(
    children: [
      Expanded(
        child: _pickerTile(
          label: 'Inizio programmato',
          value: _formatTimeOfDay(_programmedOvertimeStartTime),
          icon: Icons.schedule_rounded,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _programmedOvertimeStartTime,
            );

            if (picked == null) return;

            setState(() {
              _programmedOvertimeStartTime = picked;
            });
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _pickerTile(
          label: 'Fine programmato',
          value: _formatTimeOfDay(_programmedOvertimeEndTime),
          icon: Icons.schedule_send_rounded,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _programmedOvertimeEndTime,
            );

            if (picked == null) return;

            setState(() {
              _programmedOvertimeEndTime = picked;
            });
          },
        ),
      ),
    ],
  ),
],

      if (_questuraMode == QuesturaMode.uffici) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<QuesturaOfficeProfile>(
          value: _questuraOfficeProfile,
          dropdownColor: _QuickAddPalette.card,
          decoration: const InputDecoration(
            labelText: 'Profilo ufficio',
          ),
          items: const [
  QuesturaOfficeProfile.sixHours,
  QuesturaOfficeProfile.custom,
]
              .map(
                (item) => DropdownMenuItem<QuesturaOfficeProfile>(
                  value: item,
                  child: Text(_questuraOfficeProfileLabel(item)),
                ),
              )
              .toList(),
          onChanged: _hasAbsence
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _questuraOfficeProfile = value;
                  });
                },
        ),
      ],

      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _selectedOrderPublic,
        dropdownColor: _QuickAddPalette.card,
        decoration: const InputDecoration(
          labelText: 'Ordine pubblico',
        ),
        items: _orderPublicOptions
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: _hasAbsence
            ? null
            : (value) {
                if (value == null) return;
                setState(() {
                  _selectedOrderPublic = value;
                });
              },
      ),
      if (_isPolstrada) ...[
  const SizedBox(height: 12),
  IgnorePointer(
    ignoring: _hasAbsence,
    child: Opacity(
      opacity: _hasAbsence ? 0.46 : 1,
      child: _ModernSwitchTile(
        value: _includeAutostradaService,
        title: 'Servizio autostradale',
        subtitle: 'Aggiunge l’indennità autostradale quando spettante.',
        onChanged: (value) {
  

  setState(() {
    _includeAutostradaService = value;
  });
},
      ),
    ),
  ),
],

            const SizedBox(height: 12),
      _ModernSwitchTile(
        value: _externalService,
        title: 'Servizio esterno',
        subtitle: _questuraMode == QuesturaMode.volanti
            ? (_isPolstrada
                ? 'Attivo per i servizi di pattuglia.'
                : 'Attivo per i servizi Volanti.')
            : 'Applica l’indennità servizi esterni quando prevista.',
        onChanged: (_questuraMode == QuesturaMode.volanti && !_isPolstrada)
            ? (_) {}
            : (value) {
                setState(() {
                  _externalService = value;
                });
              },
      ),
    ],
  );
}

  Widget _buildPolferFields(Shift previewShift) {
    final autoDay = previewShift.polferWorkedDayHours;
    final autoNight = previewShift.polferWorkedNightHours;
    final bool fieldsLocked = _hasAbsence || _isSmontanteOrRiposoLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accessorie Polizia di Stato',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: _QuickAddPalette.info,
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: fieldsLocked,
          child: Opacity(
            opacity: fieldsLocked ? 0.46 : 1,
            child: _ModernSwitchTile(
              value: _externalService,
              title: 'Servizio esterno',
              subtitle:
                  'Attivalo quando il servizio Polizia di Stato lo prevede.',
              onChanged: (value) {
                setState(() {
                  _externalService = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: fieldsLocked,
          child: Opacity(
            opacity: fieldsLocked ? 0.46 : 1,
            child: DropdownButtonFormField<PolferTerritoryControlType>(
              value: _polferTerritoryControlType,
              dropdownColor: _QuickAddPalette.card,
              decoration: const InputDecoration(
                labelText: 'Controllo del territorio',
              ),
              items: PolferTerritoryControlType.values
                  .map(
                    (item) => DropdownMenuItem<PolferTerritoryControlType>(
                      value: item,
                      child: Text(_territoryControlLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _polferTerritoryControlType = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: fieldsLocked,
          child: Opacity(
            opacity: fieldsLocked ? 0.46 : 1,
            child: DropdownButtonFormField<String>(
              value: _selectedOrderPublic,
              dropdownColor: _QuickAddPalette.card,
              decoration: const InputDecoration(
                labelText: 'Ordine pubblico',
              ),
              items: _orderPublicOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedOrderPublic = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Divider(color: _QuickAddPalette.divider),
        const SizedBox(height: 14),
        const Text(
          'Basket Trenitalia / RFI',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: _QuickAddPalette.info,
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: fieldsLocked,
          child: Opacity(
            opacity: fieldsLocked ? 0.46 : 1,
            child: DropdownButtonFormField<PolferScaloMode>(
              value: _polferScaloMode,
              dropdownColor: _QuickAddPalette.card,
              decoration: const InputDecoration(
                labelText: 'Vigilanza scalo',
              ),
              items: PolferScaloMode.values
                  .map(
                    (item) => DropdownMenuItem<PolferScaloMode>(
                      value: item,
                      child: Text(_scaloModeLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _polferScaloMode = value;
                  if (value == PolferScaloMode.none) {
                    _polferScaloManualOverride = false;
                    _polferReducedDayController.text = '';
                    _polferReducedNightController.text = '';
                    _polferFullDayController.text = '';
                    _polferFullNightController.text = '';
                  }
                });
              },
            ),
          ),
        ),
        if (_hasPolferScalo && !_hasAbsence && !_isSmontanteOrRiposoLocked) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _QuickAddPalette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _QuickAddPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calcolo automatico Trenitalia / RFI',
                  style: TextStyle(
                    fontSize: 13.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ore effettive turno 06-22: ${autoDay.toStringAsFixed(2)}h\n'
                  'Ore effettive turno 22-06: ${autoNight.toStringAsFixed(2)}h',
                  style: const TextStyle(
                    color: _QuickAddPalette.textSecondary,
                    fontSize: 12.8,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Se non personalizzi, DutyPay usa automaticamente queste ore per calcolare il basket Trenitalia / RFI.',
                  style: TextStyle(
                    color: _QuickAddPalette.textSecondary,
                    fontSize: 12.6,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ModernSwitchTile(
            value: _polferScaloManualOverride,
            title: 'Personalizza il calcolo',
            subtitle:
                'Attivalo solo se il turno è stato misto o anomalo e vuoi inserire manualmente le quote ridotte e intere.',
            onChanged: (value) {
              setState(() {
                _polferScaloManualOverride = value;
                if (!value) {
                  _polferReducedDayController.text = '';
                  _polferReducedNightController.text = '';
                  _polferFullDayController.text = '';
                  _polferFullNightController.text = '';
                }
              });
            },
          ),
          if (_polferScaloManualOverride) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _polferReducedDayController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ridotta giorno',
                hintText: 'Es. 2,00',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _polferReducedNightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ridotta notte',
                hintText: 'Es. 1,50',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _polferFullDayController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Intera giorno',
                hintText: 'Es. 3,00',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _polferFullNightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Intera notte',
                hintText: 'Es. 1,00',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDepartmentSpecificFields(Shift previewShift) {
    if (_isPolfer) {
      return _buildPolferFields(previewShift);
    }

  

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IgnorePointer(
          ignoring: _hasAbsence,
          child: Opacity(
            opacity: _hasAbsence ? 0.46 : 1,
            child: DropdownButtonFormField<String>(
              value: _selectedOrderPublic,
              dropdownColor: _QuickAddPalette.card,
              decoration: const InputDecoration(
                labelText: 'Ordine pubblico',
              ),
              items: _orderPublicOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedOrderPublic = value;
                });
              },
            ),
          ),
        ),
        
      ],
    );
  }

  String? _validateBeforeSave(Shift previewShift) {
    final description = _descriptionController.text.trim();
    final manualExtra = _parseDouble(_manualExtraAmountController.text);
    final reducedDay = _parseDouble(_polferReducedDayController.text);
    final reducedNight = _parseDouble(_polferReducedNightController.text);
    final fullDay = _parseDouble(_polferFullDayController.text);
    final fullNight = _parseDouble(_polferFullNightController.text);

    if (manualExtra < 0) {
      return 'L’importo extra non può essere negativo';
    }

    if (reducedDay < 0 || reducedNight < 0 || fullDay < 0 || fullNight < 0) {
      return 'Le ore scalo non possono essere negative';
    }

    if (_hasAbsence) {
      if (_absenceNeedsCustomDescription && description.isEmpty) {
        return 'Inserisci una descrizione per l’assenza';
      }
      if (_multiDayAbsence && _absenceEndDate.isBefore(_serviceDate)) {
        return 'La data finale dell’assenza non può essere prima di quella iniziale';
      }
      return null;
    }

    if (description.isEmpty) {
      return 'Inserisci una descrizione del servizio';
    }

    final start = _combine(_realStartDate, _startTime);
    var end = _combine(_serviceDate, _endTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start).inMinutes / 60.0;

    if (duration <= 0) {
      return 'La durata del turno non è valida';
    }

    if (duration > 24) {
      return 'Il turno supera 24 ore: controlla date e orari';
    }

    if (_isPolfer && _hasPolferScalo && _polferScaloManualOverride) {
      final totalManual = reducedDay + reducedNight + fullDay + fullNight;

      if (totalManual <= 0) {
        return 'Inserisci almeno una quota oraria manuale per lo scalo';
      }

      if (totalManual > duration) {
        return 'Le ore scalo manuali superano la durata del turno';
      }
    }

    if (_isPolfer &&
        _hasPolferScalo &&
        !_polferScaloManualOverride &&
        previewShift.polferScaloAmount <= 0) {
      return 'Controlla il turno: non risultano ore valide per il calcolo automatico dello scalo';
    }

    return null;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final previewShift = _buildShiftPreview();
    final error = _validateBeforeSave(previewShift);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final shift = _buildShiftPreview();

      if (_multiDayAbsence && _hasAbsence) {
        final shifts = <Shift>[];
        DateTime current = _serviceDate;

        while (!current.isAfter(_absenceEndDate)) {
          shifts.add(
            Shift(
              description: shift.description,
              start: DateTime(current.year, current.month, current.day, 0, 0),
              end: DateTime(current.year, current.month, current.day, 0, 0),
              serviceDate: current,
              orderPublic: 'Nessuno',
              externalService: false,
              absence: _normalizedAbsenceForSave(_selectedAbsence),
              manualExtraAmount: 0,
              manualExtraLabel: '',
              genereDiConfortoCdg: false,
              genereDiConforto: false,
              ticketPasto: false,
              hasCompensazione: false,
              hasReperibilita: false,
              note: shift.note,
              polferTerritoryControlType: PolferTerritoryControlType.none,
              polferScaloMode: PolferScaloMode.none,
              polferScaloManualOverride: false,
              polferScaloReducedDayHours: 0,
              polferScaloReducedNightHours: 0,
              polferScaloFullDayHours: 0,
              polferScaloFullNightHours: 0,
              spmnPresetCode: _selectedSpmnPreset == SpmnPreset.none
                  ? ''
                  : _selectedSpmnPreset.name,
            ),
          );

          current = current.add(const Duration(days: 1));
        }

        if (!mounted) return;
        Navigator.of(context).pop(shifts);
        return;
      }

      widget.onAdd(shift);
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildEnginePreviewBreakdown(Shift previewShift) {
  if (previewShift.absence != 'Nessuna') {
    return [];
  }

  const useCase = BuildDailyShiftResultUseCase();

  final result = useCase.execute(
    shifts: [previewShift],
    profile: widget.rates,
    department: widget.activeDepartment,
  );

  final computation = result.computations[previewShift];
  if (computation == null) {
    return [];
  }

 if (previewShift.ordinaryHoursOverrideEnabled &&
    computation.overtimeHours > 0 &&
    result.totalAmount > 0) {
  return computation.breakdown;
}

  if (result.compensativeHours <= 0) {
    return computation.breakdown;
  }

  return computation.breakdown.map((item) {
    final label = item['label'] as String? ?? '';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

    if (label.toLowerCase().contains('straordinario') &&
        result.totalAmount < amount) {
      return {
        ...item,
        'amount': result.totalAmount,
        'label': '$label • pagato al netto del recupero',
      };
    }

    return item;
  }).toList();
}

double _buildPreviewTotalFromBreakdown(
  List<Map<String, dynamic>> breakdown,
) {
  final total = breakdown.fold<double>(
    0.0,
    (sum, item) =>
        sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
  );

  debugPrint('PREVIEW TOTAL = $total');
  return total;
}

  List<Map<String, String>> _buildInformativePreviewItems(Shift previewShift) {
  if (previewShift.absence != 'Nessuna') {
    return [];
  }
  debugPrint(
  'PREVIEW SHIFT -> auto=${previewShift.hasAutostradaService}, '
  'preset=${previewShift.questuraPreset}, '
  'spmn=${previewShift.spmnPresetCode}, '
  'dept=${widget.activeDepartment}',
);

  final items = <Map<String, String>>[];

if (previewShift.ordinaryHoursOverrideEnabled)
  items.insert(0, {
    'label': 'Orario ordinario impostato',
    'value': _formatTimeOfDay(
      _ordinaryHoursOverrideTime,
    ),
  });
  items.add({
    'label': 'Servizio ordinario',
    'value': 'Compreso nello stipendio',
  });

  if (previewShift.overtimeDestination == OvertimeDestination.compensative) {
  final hours = previewShift.compensativeOvertimeHours > 0
      ? previewShift.compensativeOvertimeHours
      : previewShift.overtimeHours;

  if (hours > 0) {
    final formattedHours = _formatDuration(hours);

    items.add({
      'label': 'Recupero compensativo',
      'value': '$formattedHours sottratte dal pagamento',
    });
  }
}

  if (previewShift.ticketPasto) {
    items.add({
      'label': 'Ticket pasto',
      'value': 'Benefit separato',
    });
  }

  if (previewShift.genereDiConforto) {
    items.add({
      'label': 'Genere di conforto',
      'value': 'Benefit separato',
    });
  }

  if (previewShift.genereDiConfortoCdg) {
    items.add({
      'label': 'Genere di conforto CDG',
      'value': 'Benefit separato',
    });
  }

  return items;
}

  @override
  Widget build(BuildContext context) {
    final previewShift = _buildShiftPreview();
    final breakdown = _buildEnginePreviewBreakdown(previewShift);
final total = _buildPreviewTotalFromBreakdown(breakdown);
final informativeItems = _buildInformativePreviewItems(previewShift);
final workedHours = previewShift.workedHours;

const previewUseCase = BuildDailyShiftResultUseCase();
final previewResult = previewUseCase.execute(
  shifts: [previewShift],
  profile: widget.rates,
  department: widget.activeDepartment,
);

final previewComputation = previewResult.computations[previewShift];
final overtimeHours = previewComputation?.overtimeHours ?? 0.0;
    final autoExtra = _autoMealAndComfortAmount();
    final fieldsLockedByPreset = _isSmontanteOrRiposoLocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica turno' : 'Aggiungi turno'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _QuickAddPalette.background,
              _QuickAddPalette.backgroundSoft,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Totale stimato turno',
                      style: TextStyle(
                        color: _QuickAddPalette.textSecondary,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: _QuickAddPalette.primary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _TopStatPill(
                          icon: Icons.event_rounded,
                          label: 'Giorno servizio',
                          value: _formatDate(_serviceDate),
                        ),
                        _TopStatPill(
                          icon: _hasAbsence
                              ? Icons.hotel_rounded
                              : Icons.schedule_rounded,
                          label: _hasAbsence ? 'Stato' : 'Durata',
                          value: _hasAbsence
                              ? 'Assenza registrata'
                              : _formatDuration(workedHours),
                        ),
                        if (!_hasAbsence && overtimeHours > 0)
                          _TopStatPill(
                            icon: Icons.timelapse_rounded,
                            label: 'Straordinario',
                            value: '${overtimeHours.toStringAsFixed(1)}h',
                          ),
                        if (!_hasAbsence && autoExtra > 0)
                          _TopStatPill(
                            icon: Icons.add_card_rounded,
                            label: 'Extra selezionati',
                            value: _formatCurrency(autoExtra),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isPolfer) ...[
                _buildSpmnFields(),
                const SizedBox(height: 16),
              ],
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      title: 'Dettagli servizio',
                      subtitle:
                          'Compila i dati principali del turno in modo semplice e veloce.',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedSpmnPreset == SpmnPreset.riposo &&
                        !_isTuesdayUpdateCase) ...[
                      _buildRiposoLockInfoCard(),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_hasAbsence || _absenceNeedsCustomDescription,
                      decoration: InputDecoration(
                        labelText: _hasAbsence
                            ? (_absenceNeedsCustomDescription
                                ? 'Descrizione assenza'
                                : 'Descrizione assenza automatica')
                            : 'Descrizione lavoro / servizio',
                        hintText: _hasAbsence
                            ? (_absenceNeedsCustomDescription
                                ? 'Es. Permesso visite, Altro'
                                : 'Compilata automaticamente')
                            : 'Es. Volante, Ordine Pubblico, Ufficio',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_usesQuesturaPresetLogic) ...[
  const SizedBox(height: 16),
  _buildQuesturaFields(),
  const SizedBox(height: 6),
],
                    const SizedBox(height: 14),
                    _pickerTile(
                      label: 'Giorno servizio',
                      value: _formatDate(_serviceDate),
                      onTap: _pickServiceDate,
                      icon: Icons.calendar_month_rounded,
                    ),
                    const SizedBox(height: 12),
                    _pickerTile(
                      label: 'Data inizio reale',
                      value: _formatDate(_realStartDate),
                      onTap: _pickRealStartDate,
                      icon: Icons.event_rounded,
                      enabled: !_hasAbsence && !fieldsLockedByPreset,
                    ),
                    const SizedBox(height: 12),
                    _pickerTile(
                      label: 'Ora inizio',
                      value: _formatTimeOfDay(_startTime),
                      onTap: _openStartTimeSheet,
                      icon: Icons.flash_on_rounded,
                      enabled: !_hasAbsence && !fieldsLockedByPreset,
                    ),
                    const SizedBox(height: 12),
                    _pickerTile(
                      label: 'Ora fine',
                      value: _formatTimeOfDay(_endTime),
                      onTap: _pickEndTime,
                      icon: Icons.access_time_rounded,
                      enabled: !_hasAbsence && !fieldsLockedByPreset,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      title: 'Indennità e condizioni',
                      subtitle:
                          'Attiva solo ciò che spetta davvero per questo servizio.',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildDepartmentSpecificFields(previewShift),
                    const SizedBox(height: 10),
                    if (widget.activeDepartment == Department.repartoMobile) ...[
  IgnorePointer(
    ignoring: _hasAbsence,
    child: Opacity(
      opacity: _hasAbsence ? 0.46 : 1,
      child: _ModernSwitchTile(
        value: _includeGenereDiConfortoCdg,
        title:
            'Genere di conforto CDG (${_formatCurrency(_genereDiConfortoCdgRate)})',
        subtitle: 'Attivalo solo quando spetta davvero.',
        onChanged: (value) {
          setState(() {
            _includeGenereDiConfortoCdg = value;
          });
        },
      ),
    ),
  ),
  const SizedBox(height: 10),

  IgnorePointer(
    ignoring: _hasAbsence,
    child: Opacity(
      opacity: _hasAbsence ? 0.46 : 1,
      child: _ModernSwitchTile(
        value: _includeGenereDiConforto,
        title:
            'Genere di conforto (${_formatCurrency(_genereDiConfortoRate)})',
        subtitle: 'Attivalo solo quando spetta davvero.',
        onChanged: (value) {
          setState(() {
            _includeGenereDiConforto = value;
          });
        },
      ),
    ),
  ),
  const SizedBox(height: 10),
],
                    const SizedBox(height: 10),
                    IgnorePointer(
                      ignoring: _hasAbsence,
                      child: Opacity(
                        opacity: _hasAbsence ? 0.46 : 1,
                        child: _ModernSwitchTile(
                          value: _includeCompensazione,
                          title: 'Compensazione (€ 12.00)',
                          subtitle: 'Attivalo solo quando spetta davvero.',
                          onChanged: (value) {
                            setState(() {
                              _includeCompensazione = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    IgnorePointer(
                      ignoring: _hasAbsence,
                      child: Opacity(
                        opacity: _hasAbsence ? 0.46 : 1,
                        child: _ModernSwitchTile(
                          value: _includeReperibilita,
                          title: 'Reperibilità (€ 17.50)',
                          subtitle: 'Attivala solo quando spetta davvero.',
                          onChanged: (value) {
                            setState(() {
                              _includeReperibilita = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 10),

IgnorePointer(
  ignoring: _hasAbsence,
  child: Opacity(
    opacity: _hasAbsence ? 0.46 : 1,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _QuickAddPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _QuickAddPalette.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destinazione straordinario',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scegli se lo straordinario deve essere pagato o recuperato.',
            style: TextStyle(
              fontSize: 12.5,
              color: _QuickAddPalette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<OvertimeDestination>(
  segments: const [
    ButtonSegment(
      value: OvertimeDestination.payment,
      label: Text('Pagato'),
      icon: Icon(Icons.payments_outlined),
    ),
    ButtonSegment(
      value: OvertimeDestination.compensative,
      label: Text('Compensativo'),
      icon: Icon(Icons.event_repeat_rounded),
    ),
  ],
  selected: {_overtimeDestination},
  onSelectionChanged: (values) {
    setState(() {
      _overtimeDestination = values.first;
    });
  },
),

const SizedBox(height: 14),

_ModernSwitchTile(
  value: _programmedOvertimeEnabled,
  title: 'Straordinario programmato personalizzato',
  subtitle:
      'Indica un intervallo che deve essere conteggiato sempre come straordinario.',
  onChanged: (value) {
    setState(() {
      _programmedOvertimeEnabled = value;

      if (value) {
        _questuraProgrammedOvertimePreset =
            QuesturaProgrammedOvertimePreset.none;
      }
    });
  },
),

if (_programmedOvertimeEnabled) ...[
  const SizedBox(height: 12),

  Row(
    children: [
      Expanded(
        child: _pickerTile(
          label: 'Inizio straordinario',
          value: _formatTimeOfDay(_programmedOvertimeStartTime),
          icon: Icons.schedule_rounded,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _programmedOvertimeStartTime,
            );

            if (picked == null) return;

            setState(() {
              _programmedOvertimeStartTime = picked;
            });
          },
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: _pickerTile(
          label: 'Fine straordinario',
          value: _formatTimeOfDay(_programmedOvertimeEndTime),
          icon: Icons.schedule_send_rounded,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _programmedOvertimeEndTime,
            );

            if (picked == null) return;

            setState(() {
              _programmedOvertimeEndTime = picked;
            });
          },
        ),
      ),
    ],
  ),
],

if (_usesCompensativeOvertime) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _compensativeOvertimeHoursController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Ore a recupero compensativo',
                hintText: 'Es. 3',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _compensativeOvertimeNoteController,
              decoration: const InputDecoration(
                labelText: 'Nota compensativo',
                hintText: 'Es. Recupero programmato',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 14),
          SwitchListTile(
            value: _ordinaryHoursOverrideEnabled,
            onChanged: (value) {
              setState(() {
                _ordinaryHoursOverrideEnabled = value;

                if (value) {
                  if (_ordinaryHoursOverrideController.text.trim().isEmpty) {
                    _ordinaryHoursOverrideController.text = '6';
                  }
                  _ordinaryHoursOverrideNoteController.text =
                      'Orario ordinario personalizzato';
                } else {
                  _ordinaryHoursOverrideController.text = '';
                  _ordinaryHoursOverrideNoteController.text = '';
                }
              });
            },
            title: const Text(
              'Orario ordinario personalizzato',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Usalo per uffici, tribunale o servizi particolari. Lo straordinario partirà solo oltre le ore indicate.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_ordinaryHoursOverrideEnabled) ...[
  const SizedBox(height: 10),

  _pickerTile(
    label: 'Ore ordinarie da conteggiare',
    value: _formatTimeOfDay(
      _ordinaryHoursOverrideTime,
    ),
    icon: Icons.timer_outlined,
    onTap: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: _ordinaryHoursOverrideTime,
      );

      if (picked == null) return;

      setState(() {
        _ordinaryHoursOverrideTime = picked;

        _ordinaryHoursOverrideController.text =
            _timeOfDayToDecimalHours(
              picked,
            ).toStringAsFixed(2);
      });
    },
  ),
],
        ],
      ),
    ),
  ),
),
                    
                    const SizedBox(height: 10),
                    IgnorePointer(
                      ignoring: _hasAbsence,
                      child: Opacity(
                        opacity: _hasAbsence ? 0.46 : 1,
                        child: _ModernSwitchTile(
                          value: _includeTicketPasto,
                          title:
                              'Ticket pasto (${_formatCurrency(_ticketPastoRate)})',
                          subtitle:
                              'Attivalo solo nei servizi in cui spetta davvero.',
                          onChanged: (value) {
                            setState(() {
                              _includeTicketPasto = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedAbsence,
                      dropdownColor: _QuickAddPalette.card,
                      decoration: const InputDecoration(
                        labelText: 'Assenza',
                      ),
                      items: _absenceOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
  if (value == null) return;

  // Se l’utente seleziona di nuovo la stessa voce, non fare nulla.
  if (value == _selectedAbsence) return;

  setState(() {
    _selectedAbsence = value;
    _selectedSpmnPreset =
        value == 'Riposo' ? SpmnPreset.riposo : SpmnPreset.none;

    if (_hasAbsence) {
      _applyAbsenceConstraints();
    } else {
      _multiDayAbsence = false;
      _absenceEndDate = _serviceDate;
      _realStartDate = _serviceDate;
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = const TimeOfDay(hour: 13, minute: 0);
      _includeGenereDiConfortoCdg = false;
      _includeGenereDiConforto = false;
      _includeTicketPasto = false;
      _includeCompensazione = false;
      _includeReperibilita = false;
      _includeAutostradaService = false;
      _descriptionController.text = '';
      _clearPolferFields();
    }
  });
},
                    ),
                    const SizedBox(height: 10),
if (_hasAbsence) ...[
  _ModernSwitchTile(
    value: _multiDayAbsence,
    title: 'Assenza su più giorni',
    subtitle:
        'Inserisci un intervallo per ferie, malattia, riposi o permessi.',
    onChanged: (value) {
      setState(() {
        _multiDayAbsence = value;
        if (_absenceEndDate.isBefore(_serviceDate)) {
          _absenceEndDate = _serviceDate;
        }
      });
    },
  ),
  if (_selectedAbsence == 'Recupero compensativo') ...[
    const SizedBox(height: 12),
    TextField(
      controller: _compensativeRecoveryHoursController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Ore da scaricare dal basket',
        hintText: 'Es. 6, 5.13, 7.12',
      ),
      onChanged: (_) => setState(() {}),
    ),
  ],
  if (_multiDayAbsence) ...[
    const SizedBox(height: 12),
    _pickerTile(
      label: 'Data fine assenza',
      value: _formatDate(_absenceEndDate),
      onTap: _pickAbsenceEndDate,
      icon: Icons.event_repeat_rounded,
    ),
  ],
],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  setState(() {
                    _showAdvanced = !_showAdvanced;
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _QuickAddPalette.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _QuickAddPalette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced
                            ? Icons.remove_circle_outline_rounded
                            : Icons.add_circle_outline_rounded,
                        color: _QuickAddPalette.info,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _showAdvanced
                            ? 'Nascondi opzioni avanzate'
                            : 'Mostra opzioni avanzate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showAdvanced) ...[
                const SizedBox(height: 16),
                _sectionCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        title: 'Extra manuali e note',
                        subtitle:
                            'Usa questa sezione solo quando devi aggiungere qualcosa di specifico.',
                        icon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: 16),
                      IgnorePointer(
                        ignoring: _hasAbsence,
                        child: Opacity(
                          opacity: _hasAbsence ? 0.46 : 1,
                          child: TextField(
                            controller: _manualExtraAmountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Importo extra manuale',
                              hintText: 'Es. 12,50',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: _hasAbsence,
                        child: Opacity(
                          opacity: _hasAbsence ? 0.46 : 1,
                          child: TextField(
                            controller: _manualExtraLabelController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Etichetta extra',
                              hintText: 'Es. Reperibilità, Missione, Recupero',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'Annotazioni interne sul turno',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      title: 'Anteprima calcolo',
                      subtitle:
                          'Qui vedi subito come DutyPay sta leggendo questo turno.',
                      icon: Icons.analytics_outlined,
                    ),
                    const SizedBox(height: 14),
                    if (breakdown.isEmpty && informativeItems.isEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _QuickAddPalette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _QuickAddPalette.cardBorder),
    ),
    child: Text(
      _hasAbsence
          ? 'Per le assenze non viene calcolato alcun importo extra.'
          : 'Nessun importo rilevato per questo turno.',
      style: const TextStyle(
        color: _QuickAddPalette.textSecondary,
        fontSize: 13.4,
        fontWeight: FontWeight.w600,
      ),
    ),
  )
else ...[
  if (informativeItems.isNotEmpty) ...[
    ...informativeItems.map((item) {
      return _buildInformativeRow(
        item['label'] ?? '',
        item['value'] ?? '',
      );
    }),
    if (breakdown.isNotEmpty) const SizedBox(height: 8),
  ],
  ...breakdown.map((item) {
    final label = item['label'] as String? ?? '';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    return _buildBreakdownRow(label, amount);
  }),
  const SizedBox(height: 10),
  const Divider(
    color: _QuickAddPalette.divider,
    height: 1,
  ),
  const SizedBox(height: 12),
  Row(
    children: [
      const Expanded(
        child: Text(
          'Totale turno',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            _formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _QuickAddPalette.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Icon(
                          _isEditing
                              ? Icons.save_rounded
                              : Icons.add_task_rounded,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Salvataggio...'
                        : (_isEditing ? 'Salva modifiche' : 'Salva turno'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStatPill extends StatelessWidget {
  const _TopStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _QuickAddPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _QuickAddPalette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _QuickAddPalette.info,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _QuickAddPalette.textSecondary,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernSwitchTile extends StatelessWidget {
  const _ModernSwitchTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _QuickAddPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _QuickAddPalette.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _QuickAddPalette.textSecondary,
                      fontSize: 12.8,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _QuickAddPalette.primary,
          ),
        ],
      ),
    );
  }
}

class _QuickAddPalette {
  static const background = Color(0xFF0B0F14);
  static const backgroundSoft = Color(0xFF11161E);

  static const card = Color(0xFF121922);
  static const surface = Color(0xFF18212C);

  static const cardBorder = Color(0xFF253140);
  static const divider = Color(0xFF24303E);

  static const textSecondary = Color(0xFF9AA8B7);

  static const primary = Color(0xFF5CE1A8);
  static const info = Color(0xFF67B7FF);
}