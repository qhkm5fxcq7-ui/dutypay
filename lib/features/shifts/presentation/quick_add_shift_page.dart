import 'package:flutter/material.dart';

import 'models/shift.dart';
import 'models/user_pay_profile.dart';

class QuickAddShiftPage extends StatefulWidget {
  final ValueChanged<Shift> onAdd;
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
  ];

  late final TextEditingController _descriptionController;
  late final TextEditingController _manualExtraAmountController;
  late final TextEditingController _manualExtraLabelController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  late String _selectedOrderPublic;
  late String _selectedAbsence;
  late bool _externalService;
  bool _showAdvanced = false;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool get _isEditing => widget.initialShift != null;

  @override
  void initState() {
    super.initState();

    final baseStart = widget.initialShift?.start ?? widget.initialDate ?? DateTime.now();
    final baseEnd = widget.initialShift?.end ??
        baseStart.add(const Duration(hours: 6));

    _descriptionController = TextEditingController(
      text: widget.initialShift?.description ?? '',
    );

    _manualExtraAmountController = TextEditingController(
      text: widget.initialShift != null &&
              widget.initialShift!.manualExtraAmount > 0
          ? widget.initialShift!.manualExtraAmount.toStringAsFixed(2)
          : '',
    );

    _manualExtraLabelController = TextEditingController(
      text: widget.initialShift?.manualExtraLabel ?? '',
    );

    _noteController = TextEditingController(
      text: widget.initialShift?.note ?? '',
    );

    _selectedDate = DateTime(baseStart.year, baseStart.month, baseStart.day);
    _startTime = TimeOfDay(hour: baseStart.hour, minute: baseStart.minute);
    _endTime = TimeOfDay(hour: baseEnd.hour, minute: baseEnd.minute);

    _selectedOrderPublic = widget.initialShift?.orderPublic ?? 'Nessuno';
    if (!_orderPublicOptions.contains(_selectedOrderPublic)) {
      _selectedOrderPublic = 'Nessuno';
    }

    _selectedAbsence = widget.initialShift?.absence ?? 'Nessuna';
    if (!_absenceOptions.contains(_selectedAbsence)) {
      _selectedAbsence = 'Altro';
    }

    _externalService = widget.initialShift?.externalService ?? false;

    _showAdvanced = widget.initialShift != null &&
        (widget.initialShift!.manualExtraAmount > 0 ||
            widget.initialShift!.manualExtraLabel.trim().isNotEmpty ||
            widget.initialShift!.note.trim().isNotEmpty);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _manualExtraAmountController.dispose();
    _manualExtraLabelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0.0;
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

  String _formatTimeRange() {
    return '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';
  }

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
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

  Shift _buildShiftPreview() {
    final start = _combine(_selectedDate, _startTime);
    var end = _combine(_selectedDate, _endTime);

    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    return Shift(
      description: _descriptionController.text.trim(),
      start: start,
      end: end,
      orderPublic: _selectedOrderPublic,
      externalService: _externalService,
      absence: _selectedAbsence,
      manualExtraAmount: _parseDouble(_manualExtraAmountController.text),
      manualExtraLabel: _manualExtraLabelController.text.trim(),
      note: _noteController.text.trim(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
      locale: const Locale('it'),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
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
    );

    if (picked == null) return;
    _setStartTime(picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked == null) return;

    setState(() {
      _endTime = picked;
    });
  }

  Future<void> _openStartTimeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF131820),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleziona ora inizio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _quickTimes.map((time) {
                    final isSelected =
                        time.hour == _startTime.hour &&
                        time.minute == _startTime.minute;

                    return ElevatedButton(
                      onPressed: () {
                        _setStartTime(time);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF1A1F2B),
                        foregroundColor: isSelected ? Colors.black : Colors.white,
                      ),
                      child: Text(_formatTimeOfDay(time)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _pickCustomStartTime();
                    },
                    child: const Text('Orario personalizzato'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131820),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    IconData icon = Icons.chevron_right_rounded,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
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
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final shift = _buildShiftPreview();

    if (shift.description.trim().isEmpty && shift.absence == 'Nessuna') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci una descrizione del servizio'),
        ),
      );
      return;
    }

    widget.onAdd(shift);
  }

  @override
  Widget build(BuildContext context) {
    final previewShift = _buildShiftPreview();
    final breakdown = previewShift.getBreakdown(widget.rates);
    final total = previewShift.getTotalAmount(widget.rates);
    final workedHours = previewShift.workedHours;
    final overtimeHours = previewShift.overtimeHours;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica turno' : 'Aggiungi turno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Totale stimato turno',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '€ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Durata: ${_formatDuration(workedHours)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  if (overtimeHours > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Straordinario stimato: ${overtimeHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Dettagli servizio'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione lavoro / servizio',
                      hintText: 'Es. Volante, Ordine Pubblico, Ufficio',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _pickerTile(
                    label: 'Data',
                    value: _formatDate(_selectedDate),
                    onTap: _pickDate,
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 12),
                  _pickerTile(
                    label: 'Ora inizio',
                    value: _formatTimeOfDay(_startTime),
                    onTap: _openStartTimeSheet,
                    icon: Icons.flash_on_rounded,
                  ),
                  const SizedBox(height: 12),
                  _pickerTile(
                    label: 'Ora fine',
                    value: _formatTimeOfDay(_endTime),
                    onTap: _pickEndTime,
                    icon: Icons.access_time_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Indennità e condizioni'),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedOrderPublic,
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
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: _externalService,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Servizio esterno'),
                    subtitle: const Text(
                      'Applica l’indennità servizi esterni quando prevista',
                      style: TextStyle(color: Colors.white60),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _externalService = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAbsence,
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
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAdvanced = !_showAdvanced;
                });
              },
              child: Text(
                _showAdvanced ? '− Opzioni avanzate' : '+ Opzioni avanzate',
                style: const TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Extra manuali'),
                    const SizedBox(height: 14),
                    TextField(
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualExtraLabelController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Etichetta extra',
                        hintText: 'Es. Reperibilità, Missione, Recupero',
                      ),
                      onChanged: (_) => setState(() {}),
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
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Anteprima calcolo'),
                  const SizedBox(height: 12),
                  if (breakdown.isEmpty)
                    const Text(
                      'Nessun importo rilevato per questo turno.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    )
                  else
                    ...breakdown.map((item) {
                      final label = item['label'] as String? ?? '';
                      final amount =
                          (item['amount'] as num?)?.toDouble() ?? 0.0;
                      return _buildBreakdownRow(label, amount);
                    }),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_isEditing ? 'Salva modifiche' : 'Salva turno'),
            ),
          ],
        ),
      ),
    );
  }
}