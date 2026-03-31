import 'package:flutter/material.dart';

import 'models/shift.dart';
import 'models/user_pay_profile.dart';

class QuickAddShiftPage extends StatefulWidget {
  final ValueChanged<dynamic> onAdd;
  final UserPayProfile? rates;
  final Shift? initialShift;
  final DateTime? initialDate;

  const QuickAddShiftPage({
    super.key,
    required this.onAdd,
    this.rates,
    this.initialShift,
    this.initialDate,
  });

  @override
  State<QuickAddShiftPage> createState() => _QuickAddShiftPageState();
}

class _QuickAddShiftPageState extends State<QuickAddShiftPage> {
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
    'Permesso',
    'Altro',
  ];

  static const List<TimeOfDay> _quickTimes = [
    TimeOfDay(hour: 7, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
    TimeOfDay(hour: 23, minute: 0),
  ];

  late final TextEditingController _descriptionController;
  late final TextEditingController _manualExtraAmountController;
  late final TextEditingController _manualExtraLabelController;
  late final TextEditingController _noteController;

  late DateTime _serviceDate;
  late DateTime _realStartDate;
  late DateTime _absenceEndDate;

  bool _multiDayAbsence = false;
  late String _selectedOrderPublic;
  late String _selectedAbsence;
  late bool _externalService;
  bool _showAdvanced = false;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isSaving = false;

  bool _includeGenereDiConforto = false;
  bool _includeTicketPasto = false;

  bool get _isEditing => widget.initialShift != null;
  bool get _hasAbsence => _selectedAbsence != 'Nessuna';
  bool get _startIsPreviousDay => !_isSameDay(_realStartDate, _serviceDate);

  bool get _absenceNeedsCustomDescription =>
      _selectedAbsence == 'Permesso' || _selectedAbsence == 'Altro';

  UserPayProfile get _profile => widget.rates ?? UserPayProfile.defaultProfile();

  double get _genereDiConfortoRate => _profile.genereDiConfortoRate;
  double get _ticketPastoRate => _profile.ticketPastoRate;

  @override
  void initState() {
    super.initState();

    final baseServiceDate =
        widget.initialShift?.serviceDate ?? widget.initialDate ?? DateTime.now();

    final baseStart = widget.initialShift?.start ?? baseServiceDate;
    final baseEnd =
        widget.initialShift?.end ?? baseStart.add(const Duration(hours: 6));

    final initialShift = widget.initialShift;
    final initialManualLabel = initialShift?.manualExtraLabel ?? '';
    final initialManualAmount = initialShift?.manualExtraAmount ?? 0.0;

    final hadGenere = _containsGenereDiConforto(initialManualLabel);
    final hadTicket = _containsTicketPasto(initialManualLabel);

    final extractedAutoAmount =
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

    _serviceDate = _normalizeDate(baseServiceDate);
    _realStartDate = _normalizeDate(baseStart);
    _absenceEndDate = _serviceDate;

    _startTime = TimeOfDay(hour: baseStart.hour, minute: baseStart.minute);
    _endTime = TimeOfDay(hour: baseEnd.hour, minute: baseEnd.minute);

    _selectedOrderPublic = initialShift?.orderPublic ?? 'Nessuno';
    if (!_orderPublicOptions.contains(_selectedOrderPublic)) {
      _selectedOrderPublic = 'Nessuno';
    }

    _selectedAbsence = initialShift?.absence ?? 'Nessuna';
    if (!_absenceOptions.contains(_selectedAbsence)) {
      _selectedAbsence = 'Altro';
    }

    _externalService = initialShift?.externalService ?? false;

    _includeGenereDiConforto = hadGenere;
    _includeTicketPasto = hadTicket;

    _showAdvanced = initialShift != null &&
        (cleanedManualAmount > 0 ||
            cleanedManualLabel.trim().isNotEmpty ||
            initialShift.note.trim().isNotEmpty);

    if (_hasAbsence) {
      _applyAbsenceConstraints();
      if (!_absenceNeedsCustomDescription &&
          _descriptionController.text.trim().isEmpty) {
        _descriptionController.text = _defaultAbsenceDescription(_selectedAbsence);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _manualExtraAmountController.dispose();
    _manualExtraLabelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _containsGenereDiConforto(String label) {
    return label.toLowerCase().contains('genere di conforto');
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
      case 'Altro':
        return 'Altro';
      default:
        return '';
    }
  }

  void _applyAbsenceConstraints() {
    _selectedOrderPublic = 'Nessuno';
    _externalService = false;
    _manualExtraAmountController.text = '';
    _manualExtraLabelController.text = '';
    _includeGenereDiConforto = false;
    _includeTicketPasto = false;

    if (_absenceEndDate.isBefore(_serviceDate)) {
      _absenceEndDate = _serviceDate;
    }

    _realStartDate = _serviceDate;
    _startTime = const TimeOfDay(hour: 0, minute: 0);
    _endTime = const TimeOfDay(hour: 0, minute: 0);

    if (!_absenceNeedsCustomDescription) {
      _descriptionController.text = _defaultAbsenceDescription(_selectedAbsence);
    }
  }

  double _autoMealAndComfortAmount() {
    if (_hasAbsence) return 0.0;

    double total = 0.0;

    if (_includeGenereDiConforto) {
      total += _genereDiConfortoRate;
    }

    if (_includeTicketPasto) {
      total += _ticketPastoRate;
    }

    return total;
  }

  String _autoMealAndComfortLabel() {
    final labels = <String>[];

    if (_includeGenereDiConforto) {
      labels.add('Genere di conforto');
    }

    if (_includeTicketPasto) {
      labels.add('Ticket pasto');
    }

    return labels.join(' • ');
  }

    Shift _buildShiftPreview() {
    final manualAmount = _parseDouble(_manualExtraAmountController.text);
    final manualLabel = _manualExtraLabelController.text.trim();

    if (_hasAbsence) {
      final description = _descriptionController.text.trim().isEmpty
          ? _defaultAbsenceDescription(_selectedAbsence)
          : _descriptionController.text.trim();

      return Shift(
        description: description,
        start: DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day),
        end: DateTime(_serviceDate.year, _serviceDate.month, _serviceDate.day),
        serviceDate: _serviceDate,
        orderPublic: 'Nessuno',
        externalService: false,
        absence: _normalizedAbsenceForSave(_selectedAbsence),
        manualExtraAmount: 0,
        manualExtraLabel: '',
        genereDiConforto: false,
        ticketPasto: false,
        note: _noteController.text.trim(),
      );
    }

    final start = _combine(_realStartDate, _startTime);
    var end = _combine(_serviceDate, _endTime);

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
      absence: _normalizedAbsenceForSave(_selectedAbsence),
      manualExtraAmount: manualAmount,
      manualExtraLabel: manualLabel,
      genereDiConforto: _includeGenereDiConforto,
      ticketPasto: _includeTicketPasto,
      note: _noteController.text.trim(),
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

    setState(() {
      _serviceDate = _normalizeDate(picked);

      if (!_startIsPreviousDay || _hasAbsence) {
        _realStartDate = _serviceDate;
      }

      if (_absenceEndDate.isBefore(_serviceDate)) {
        _absenceEndDate = _serviceDate;
      }
    });
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
      _endTime = _addSixHours(start);
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
            color: Colors.black.withOpacity(0.16),
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

  String? _validateBeforeSave() {
    final description = _descriptionController.text.trim();
    final manualExtra = _parseDouble(_manualExtraAmountController.text);

    if (manualExtra < 0) {
      return 'L’importo extra non può essere negativo';
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

    return null;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final error = _validateBeforeSave();
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
              genereDiConforto: false,
              ticketPasto: false,
              note: shift.note,
            ),
          );

          current = current.add(const Duration(days: 1));
        }

        if (!mounted) return;
        Navigator.of(context).pop(shifts);
        return;
      }

      widget.onAdd(shift);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewShift = _buildShiftPreview();
    final breakdown = previewShift.getBreakdown(widget.rates);
    final total = previewShift.getTotalAmount(widget.rates);
    final workedHours = previewShift.workedHours;
    final overtimeHours = previewShift.overtimeHours;
    final autoExtra = _autoMealAndComfortAmount();

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

              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      title: 'Dettagli servizio',
                      subtitle: 'Compila i dati principali del turno in modo semplice e veloce.',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
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
                      enabled: !_hasAbsence,
                    ),
                    const SizedBox(height: 12),
                    _pickerTile(
                      label: 'Ora inizio',
                      value: _formatTimeOfDay(_startTime),
                      onTap: _openStartTimeSheet,
                      icon: Icons.flash_on_rounded,
                      enabled: !_hasAbsence,
                    ),
                    const SizedBox(height: 12),
                    _pickerTile(
                      label: 'Ora fine',
                      value: _formatTimeOfDay(_endTime),
                      onTap: _pickEndTime,
                      icon: Icons.access_time_rounded,
                      enabled: !_hasAbsence,
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
                      subtitle: 'Attiva solo ciò che spetta davvero per questo servizio.',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 12),
                    IgnorePointer(
                      ignoring: _hasAbsence,
                      child: Opacity(
                        opacity: _hasAbsence ? 0.46 : 1,
                        child: _ModernSwitchTile(
                          value: _externalService,
                          title: 'Servizio esterno',
                          subtitle:
                              'Applica l’indennità servizi esterni quando prevista.',
                          onChanged: (value) {
                            setState(() {
                              _externalService = value;
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
                        setState(() {
                          _selectedAbsence = value;
                          if (_hasAbsence) {
                            _applyAbsenceConstraints();
                          } else {
                            _multiDayAbsence = false;
                            _absenceEndDate = _serviceDate;
                            _realStartDate = _serviceDate;
                            _startTime = const TimeOfDay(hour: 7, minute: 0);
                            _endTime = const TimeOfDay(hour: 13, minute: 0);
                            _includeGenereDiConforto = false;
                            _includeTicketPasto = false;
                            _descriptionController.text = '';
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
                            keyboardType: const TextInputType.numberWithOptions(
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
                    if (breakdown.isEmpty)
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
                      ...breakdown.map((item) {
                        final label = item['label'] as String? ?? '';
                        final amount =
                            (item['amount'] as num?)?.toDouble() ?? 0.0;
                        return _buildBreakdownRow(label, amount);
                      }),
                      const SizedBox(height: 10),
                      const Divider(color: _QuickAddPalette.divider, height: 1),
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
            activeColor: _QuickAddPalette.primary,
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