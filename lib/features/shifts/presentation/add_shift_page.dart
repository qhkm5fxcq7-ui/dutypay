import 'package:flutter/material.dart';

import 'models/shift.dart';
import 'services/shift_rate_calculator.dart';

class AddShiftPage extends StatefulWidget {
  final Shift? initialShift;
  final ShiftDerivedRates? derivedRates;
  final String activeDepartmentId;

  const AddShiftPage({
    super.key,
    this.initialShift,
    this.derivedRates,
    required this.activeDepartmentId,
  });

  @override
  State<AddShiftPage> createState() => _AddShiftPageState();
}

class _AddShiftPageState extends State<AddShiftPage> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController manualExtraAmountController =
      TextEditingController(text: '0');
  final TextEditingController manualExtraLabelController =
      TextEditingController();

  String selectedOrderPublic = 'Nessuno';
  bool externalService = false;
  String selectedAbsence = 'Nessuna';

  final List<String> orderPublicOptions = [
    'Nessuno',
    'In sede',
    'Fuori sede',
    'Pernotto',
  ];

  final List<String> absenceOptions = [
    'Nessuna',
    'Congedo ordinario',
    'Congedo straordinario',
    'Riposo legge',
    'Riposo settimanale',
    'Riposo festivo',
    'Recupero riposo',
    'Riposo compensativo',
    'Aspettativa',
    'L104',
    'Donazione sangue',
    'Ore studio',
    'Permesso breve',
    'Permesso sindacale',
  ];

  DateTime? selectedStart;
  DateTime? selectedEnd;

  bool get isEditing => widget.initialShift != null;

  String get _resolvedDepartmentId {
    return widget.initialShift?.departmentId ?? widget.activeDepartmentId;
  }

  @override
  void initState() {
    super.initState();

    final initial = widget.initialShift;

    if (initial != null) {
      descriptionController.text = initial.description;
      selectedStart = initial.start;
      selectedEnd = initial.end;
      selectedOrderPublic = initial.orderPublic;
      externalService = initial.externalService;
      selectedAbsence = initial.absence;
      manualExtraAmountController.text =
          initial.manualExtraAmount.toStringAsFixed(2);
      manualExtraLabelController.text = initial.manualExtraLabel;
    } else {
      selectedStart = DateTime.now();
      selectedEnd = selectedStart!.add(const Duration(hours: 6));
    }

    _syncControllers();

    descriptionController.addListener(_refresh);
    manualExtraAmountController.addListener(_refresh);
    manualExtraLabelController.addListener(_refresh);
  }

  @override
  void dispose() {
    descriptionController.removeListener(_refresh);
    manualExtraAmountController.removeListener(_refresh);
    manualExtraLabelController.removeListener(_refresh);

    descriptionController.dispose();
    startController.dispose();
    endController.dispose();
    manualExtraAmountController.dispose();
    manualExtraLabelController.dispose();

    super.dispose();
  }

  void _refresh() {
    setState(() {});
  }

  void _syncControllers() {
    startController.text = formatItalianDateTime(selectedStart);
    endController.text = formatItalianDateTime(selectedEnd);
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> pickStartDateTime() async {
    final initial = selectedStart ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedStart = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (selectedEnd == null || !selectedEnd!.isAfter(selectedStart!)) {
        selectedEnd = selectedStart!.add(const Duration(hours: 6));
      }

      _syncControllers();
    });
  }

  Future<void> pickEndDateTime() async {
    final base =
        selectedEnd ?? selectedStart?.add(const Duration(hours: 6)) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (pickedTime == null) return;

    setState(() {
      selectedEnd = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      _syncControllers();
    });
  }

  Shift _buildPreviewShift() {
    return Shift(
      description: descriptionController.text.trim(),
      start: selectedStart ?? DateTime.now(),
      end: selectedEnd ?? DateTime.now().add(const Duration(hours: 6)),
      departmentId: _resolvedDepartmentId,
      orderPublic: selectedOrderPublic,
      externalService: externalService,
      absence: selectedAbsence,
      manualExtraAmount: _parseDouble(manualExtraAmountController.text),
      manualExtraLabel: manualExtraLabelController.text.trim(),
    );
  }

  double get previewHours {
    if (selectedStart == null || selectedEnd == null) return 0.0;
    final diff = selectedEnd!.difference(selectedStart!).inMinutes / 60.0;
    return diff > 0 ? diff : 0.0;
  }

  double get previewOvertimeHours {
    if (selectedAbsence != 'Nessuna') return 0.0;
    final extra = previewHours - Shift.standardHours;
    return extra > 0 ? extra : 0.0;
  }

  bool get previewIsSunday {
    if (selectedStart == null) return false;
    return selectedStart!.weekday == DateTime.sunday;
  }

  bool get previewCrossesMidnight {
    if (selectedStart == null || selectedEnd == null) return false;
    return selectedEnd!.day != selectedStart!.day ||
        selectedEnd!.month != selectedStart!.month ||
        selectedEnd!.year != selectedStart!.year;
  }

  bool get previewTouchesNightBand {
    if (selectedStart == null || selectedEnd == null) return false;

    final startMinutes = selectedStart!.hour * 60 + selectedStart!.minute;
    final endMinutes = selectedEnd!.hour * 60 + selectedEnd!.minute;

    const nightStart = 22 * 60;
    const nightEnd = 6 * 60;

    if (previewCrossesMidnight) return true;
    if (startMinutes >= nightStart) return true;
    if (endMinutes <= nightEnd) return true;

    return false;
  }

  bool get previewIsSuperHoliday {
    if (selectedStart == null) return false;
    final date = selectedStart!;

    final easter = _calculateEasterSunday(date.year);
    final easterMonday = easter.add(const Duration(days: 1));

    final superHolidays = [
      DateTime(date.year, 1, 1),
      easter,
      easterMonday,
      DateTime(date.year, 5, 1),
      DateTime(date.year, 6, 2),
      DateTime(date.year, 8, 15),
      DateTime(date.year, 12, 25),
      DateTime(date.year, 12, 26),
    ];

    return superHolidays.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  bool get previewIsHoliday {
    return previewIsSunday || previewIsSuperHoliday;
  }

  double get previewOvertimeRate {
    if (previewTouchesNightBand && previewIsHoliday) {
      return Shift.overtimeNightAndHolidayRate;
    }
    if (previewTouchesNightBand || previewIsHoliday) {
      return Shift.overtimeNightOrHolidayRate;
    }
    return Shift.overtimeDayRate;
  }

  double get previewOvertimeAmount {
    if (selectedAbsence != 'Nessuna') return 0.0;
    return previewOvertimeHours * previewOvertimeRate;
  }

  double get previewOrderPublicAmount {
    if (selectedAbsence != 'Nessuna') return 0.0;
    if (externalService) return 0.0;

    switch (selectedOrderPublic) {
      case 'In sede':
        return Shift.orderPublicInSede;
      case 'Fuori sede':
        return Shift.orderPublicFuoriSede;
      case 'Pernotto':
        return Shift.orderPublicPernotto;
      default:
        return 0.0;
    }
  }

  double get previewExternalAmount {
    if (selectedAbsence != 'Nessuna') return 0.0;
    return externalService ? Shift.externalServiceRate : 0.0;
  }

  double get previewFestiveAmount {
    if (selectedAbsence != 'Nessuna') return 0.0;
    if (previewIsSuperHoliday) return 0.0;
    return previewIsSunday ? Shift.holidayAllowance : 0.0;
  }

  double get previewSpecialHolidayAmount {
    if (selectedAbsence != 'Nessuna') return 0.0;
    return previewIsSuperHoliday ? Shift.specialHolidayAllowance : 0.0;
  }

  double get previewManualExtraAmount {
    if (selectedAbsence != 'Nessuna') return 0.0;
    final amount = _parseDouble(manualExtraAmountController.text);
    return amount > 0 ? amount : 0.0;
  }

  double get previewTotal {
    if (selectedAbsence != 'Nessuna') return 0.0;

    return previewOvertimeAmount +
        previewOrderPublicAmount +
        previewExternalAmount +
        previewFestiveAmount +
        previewSpecialHolidayAmount +
        previewManualExtraAmount;
  }

  String get previewDescription {
    if (descriptionController.text.trim().isEmpty) {
      return 'Turno senza descrizione';
    }
    return descriptionController.text.trim();
  }

  String get previewOvertimeLabel {
    if (previewOvertimeHours <= 0) return 'Nessuno';
    if (previewTouchesNightBand && previewIsHoliday) {
      return 'Straordinario notturno e festivo';
    }
    if (previewTouchesNightBand || previewIsHoliday) {
      return 'Straordinario notturno o festivo';
    }
    return 'Straordinario diurno';
  }

  String get previewDayTypeLabel {
    if (previewIsSuperHoliday) return 'Superfestivo';
    if (previewIsSunday) return 'Festivo';
    return 'Ordinario';
  }

  void saveShift() {
    final description = descriptionController.text.trim();
    final start = selectedStart;
    final end = selectedEnd;
    final manualExtraAmount = _parseDouble(manualExtraAmountController.text);
    final manualExtraLabel = manualExtraLabelController.text.trim();

    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona data e ora di inizio e fine turno'),
        ),
      );
      return;
    }

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'L’orario di fine deve essere successivo all’orario di inizio',
          ),
        ),
      );
      return;
    }

    if (manualExtraAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L’extra manuale non può essere negativo'),
        ),
      );
      return;
    }

    final shift = Shift(
      description: description,
      start: start,
      end: end,
      departmentId: _resolvedDepartmentId,
      orderPublic: selectedOrderPublic,
      externalService: externalService,
      absence: selectedAbsence,
      manualExtraAmount: manualExtraAmount,
      manualExtraLabel: manualExtraLabel,
    );

    Navigator.pop(context, shift);
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF171A21),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF22C55E),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _dateTimePickerField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF171A21),
        suffixIcon: const Icon(Icons.calendar_month_rounded),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF22C55E),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _styledDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF171A21),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF171A21),
            borderRadius: BorderRadius.circular(16),
            items: items.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _calculateEasterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    final previewShift = _buildPreviewShift();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica turno' : 'Nuovo turno'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F2A22),
                  Color(0xFF111827),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Modifica turno' : 'Inserisci turno',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Compila il servizio normale o aggiungi una voce particolare nello stesso flusso.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionTitle('Descrizione'),
          const SizedBox(height: 8),
          _styledTextField(
            controller: descriptionController,
            hintText: 'Es. OP Milano / Corpo di guardia / Stadio',
          ),
          const SizedBox(height: 20),

          _sectionTitle('Inizio servizio'),
          const SizedBox(height: 8),
          _dateTimePickerField(
            controller: startController,
            hintText: 'Seleziona inizio turno',
            onTap: pickStartDateTime,
          ),
          const SizedBox(height: 20),

          _sectionTitle('Fine servizio'),
          const SizedBox(height: 8),
          _dateTimePickerField(
            controller: endController,
            hintText: 'Seleziona fine turno',
            onTap: pickEndDateTime,
          ),
          const SizedBox(height: 20),

          _sectionTitle('Ordine pubblico'),
          const SizedBox(height: 8),
          _styledDropdown(
            value: selectedOrderPublic,
            items: orderPublicOptions,
            enabled: !externalService,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedOrderPublic = value;
              });
            },
          ),
          if (externalService)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Con servizio esterno attivo, OP non viene conteggiato.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 20),

          _sectionTitle('Assenza dal servizio'),
          const SizedBox(height: 8),
          _styledDropdown(
            value: selectedAbsence,
            items: absenceOptions,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedAbsence = value;
              });
            },
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131820),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opzioni aggiuntive',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Usale solo se servono. Tutto resta nello stesso turno.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Servizio esterno',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Se attivo, OP non sarà conteggiato',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  value: externalService,
                  onChanged: (value) {
                    setState(() {
                      externalService = value;
                      if (externalService) {
                        selectedOrderPublic = 'Nessuno';
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171A21),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voce particolare opzionale',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Per missioni, compensazioni, premi o qualunque importo che vuoi aggiungere manualmente.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _styledTextField(
                  controller: manualExtraLabelController,
                  hintText: 'Es. Missione Milano / Compensazione',
                ),
                const SizedBox(height: 12),
                _styledTextField(
                  controller: manualExtraAmountController,
                  hintText: 'Es. 25,50',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF171A21),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anteprima turno',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  previewDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPreviewRow(
                  'Fascia oraria',
                  '${formatItalianDateTime(previewShift.start)} → ${formatItalianDateTime(previewShift.end)}',
                ),
                _buildPreviewRow(
                  'Ore stimate',
                  '${previewHours.toStringAsFixed(1)}h',
                ),
                _buildPreviewRow(
                  'Straordinario',
                  previewOvertimeHours > 0
                      ? '$previewOvertimeLabel (${previewOvertimeHours.toStringAsFixed(1)}h × €${previewOvertimeRate.toStringAsFixed(2)})'
                      : 'Nessuno',
                ),
                _buildPreviewRow(
                  'Tipo giorno',
                  previewDayTypeLabel,
                ),
                _buildPreviewRow(
                  'Fascia notturna',
                  previewTouchesNightBand ? 'Sì' : 'No',
                ),
                _buildPreviewRow(
                  'OP',
                  externalService ? 'Non applicato' : selectedOrderPublic,
                ),
                _buildPreviewRow(
                  'Esterno',
                  externalService ? 'Sì' : 'No',
                ),
                _buildPreviewRow(
                  'Assenza',
                  selectedAbsence,
                ),
                if (previewManualExtraAmount > 0)
                  _buildPreviewRow(
                    'Extra manuale',
                    '${manualExtraLabelController.text.trim().isEmpty ? "Extra manuale" : manualExtraLabelController.text.trim()} • € ${previewManualExtraAmount.toStringAsFixed(2)}',
                  ),
                const SizedBox(height: 10),
                Text(
                  'Valore stimato: € ${previewTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saveShift,
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  isEditing ? 'Salva modifiche' : 'Salva turno',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatItalianDateTime(DateTime? dateTime) {
  if (dateTime == null) return '';

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}