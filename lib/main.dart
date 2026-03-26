import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home/widgets/estimated_salary_card.dart';
import 'features/home/widgets/month_calendar_card.dart';
import 'features/shifts/presentation/calibrate_payslips_page.dart';
import 'features/shifts/presentation/models/shift.dart';
import 'features/shifts/presentation/models/user_pay_profile.dart';
import 'features/shifts/presentation/quick_add_shift_page.dart';

void main() {
  runApp(const DutyPayApp());
}

class DutyPayApp extends StatefulWidget {
  const DutyPayApp({super.key});

  @override
  State<DutyPayApp> createState() => _DutyPayAppState();
}

class _DutyPayAppState extends State<DutyPayApp> {
  static const String _userNameStorageKey = 'dutypay_user_name';

  bool isLoading = true;
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_userNameStorageKey)?.trim();

    if (!mounted) return;

    setState(() {
      userName = (savedName == null || savedName.isEmpty) ? null : savedName;
      isLoading = false;
    });
  }

  Future<void> _handleOnboardingCompleted(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameStorageKey, cleaned);

    if (!mounted) return;

    setState(() {
      userName = cleaned;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF22C55E),
        secondary: Color(0xFF3B82F6),
        surface: Color(0xFF171A21),
      ),
    );

    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('it'),
        supportedLocales: const [
          Locale('it'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'DutyPay',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('it'),
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: userName == null
          ? OnboardingPage(onCompleted: _handleOnboardingCompleted)
          : DutyPayHomePage(userName: userName!),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  final Future<void> Function(String value) onCompleted;

  const OnboardingPage({
    super.key,
    required this.onCompleted,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _nameController.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il tuo nome')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onCompleted(value);
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF171A21),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Benvenuto in DutyPay',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Inserisci il tuo nome per iniziare.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Il tuo nome',
                      filled: true,
                      fillColor: const Color(0xFF111827),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continua'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DutyPayHomePage extends StatefulWidget {
  final String userName;

  const DutyPayHomePage({
    super.key,
    required this.userName,
  });

  @override
  State<DutyPayHomePage> createState() => _DutyPayHomePageState();
}

class _DutyPayHomePageState extends State<DutyPayHomePage> {
  static const String shiftsStorageKey = 'dutypay_shifts';
  static const String payProfileStorageKey = 'dutypay_pay_profile';

  final List<Shift> shifts = [];
  bool isLoading = true;
  late DateTime selectedMonth;
  late DateTime selectedDay;
  UserPayProfile payProfile = UserPayProfile.defaultProfile();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    selectedDay = DateTime(now.year, now.month, now.day);
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawShifts = prefs.getStringList(shiftsStorageKey) ?? [];
    final rawProfile = prefs.getString(payProfileStorageKey);

    final loadedShifts = rawShifts
        .map((item) => Shift.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();

    loadedShifts.sort((a, b) => b.start.compareTo(a.start));

    final loadedProfile = rawProfile != null
        ? UserPayProfile.fromJson(jsonDecode(rawProfile) as Map<String, dynamic>)
        : UserPayProfile.defaultProfile();

    if (!mounted) return;

    setState(() {
      shifts
        ..clear()
        ..addAll(loadedShifts);
      payProfile = loadedProfile;
      isLoading = false;
    });
  }

  Future<void> saveShifts() async {
    shifts.sort((a, b) => b.start.compareTo(a.start));

    final prefs = await SharedPreferences.getInstance();
    final rawList = shifts.map((shift) => jsonEncode(shift.toJson())).toList();
    await prefs.setStringList(shiftsStorageKey, rawList);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Shift> get filteredShifts {
    return shifts.where((shift) {
      return shift.start.year == selectedMonth.year &&
          shift.start.month == selectedMonth.month;
    }).toList();
  }

  List<Shift> get selectedDayShifts {
    return filteredShifts
        .where((shift) => _isSameDay(shift.start, selectedDay))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  double get totalMonth {
    return filteredShifts.fold(
      0.0,
      (sum, shift) => sum + shift.getTotalAmount(payProfile),
    );
  }

  double get effectiveTaxRate {
    final rate = payProfile.effectiveTaxRate;
    if (rate.isNaN || !rate.isFinite) return 0.0;
    if (rate < 0) return 0.0;
    if (rate > 0.60) return 0.60;
    return rate;
  }

  double get estimatedBaseNet {
    final base = payProfile.detectedBaseSalary;
    if (base.isNaN || !base.isFinite) return 0.0;
    return base < 0 ? 0.0 : base;
  }

  double get estimatedExtraGross {
    final value = totalMonth;
    if (value.isNaN || !value.isFinite) return 0.0;
    return value < 0 ? 0.0 : value;
  }

  double get estimatedTaxesOnExtras {
    return estimatedExtraGross * effectiveTaxRate;
  }

  double get estimatedExtraNet {
    final value = estimatedExtraGross - estimatedTaxesOnExtras;
    return value < 0 ? 0.0 : value;
  }

  double get estimatedPayslipTotal {
    return estimatedBaseNet + estimatedExtraNet;
  }

  int get workedDaysCount {
    final uniqueDays = <String>{};

    for (final shift in filteredShifts) {
      if (shift.hasAbsence) continue;

      final key =
          '${shift.start.year}-'
          '${shift.start.month.toString().padLeft(2, '0')}-'
          '${shift.start.day.toString().padLeft(2, '0')}';

      uniqueDays.add(key);
    }

    return uniqueDays.length;
  }

  double get averagePerWorkedDay {
    if (workedDaysCount == 0) return 0.0;
    return totalMonth / workedDaysCount;
  }

  int get daysInSelectedMonth {
    return DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  }

  int get remainingDaysInSelectedMonth {
    final now = DateTime.now();

    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    if (!isCurrentMonth) return 0;

    final remaining = daysInSelectedMonth - now.day;
    return remaining > 0 ? remaining : 0;
  }

  double get projectedExtraFuture {
    if (workedDaysCount == 0) return 0.0;
    return averagePerWorkedDay * remainingDaysInSelectedMonth;
  }

  double get estimatedEndOfMonth {
    final now = DateTime.now();

    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    if (!isCurrentMonth) {
      return estimatedPayslipTotal;
    }

    if (workedDaysCount == 0) {
      return estimatedPayslipTotal;
    }

    final projectedExtraGross =
        totalMonth + (averagePerWorkedDay * remainingDaysInSelectedMonth);
    final projectedTaxes = projectedExtraGross * effectiveTaxRate;
    final projectedExtraNet = projectedExtraGross - projectedTaxes;

    return estimatedBaseNet + (projectedExtraNet < 0 ? 0.0 : projectedExtraNet);
  }

  double get estimatedRangeMin {
    if (estimatedEndOfMonth == 0) return 0.0;
    return estimatedEndOfMonth * 0.97;
  }

  double get estimatedRangeMax {
    if (estimatedEndOfMonth == 0) return 0.0;
    return estimatedEndOfMonth * 1.03;
  }

  double _dailyTotal(DateTime date) {
    return filteredShifts
        .where((shift) => _isSameDay(shift.start, date))
        .fold(0.0, (sum, shift) => sum + shift.getTotalAmount(payProfile));
  }

  List<MonthCalendarDayData> get calendarDays {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startWeekday = firstDayOfMonth.weekday;
    final gridStart = firstDayOfMonth.subtract(Duration(days: startWeekday - 1));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(35, (index) {
      final date = gridStart.add(Duration(days: index));
      final isInCurrentMonth = date.month == selectedMonth.month;

      return MonthCalendarDayData(
        date: date,
        isInCurrentMonth: isInCurrentMonth,
        amount: isInCurrentMonth ? _dailyTotal(date) : 0.0,
        isSelected: _isSameDay(date, selectedDay),
        isToday: _isSameDay(date, today),
      );
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
      selectedDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
      selectedDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    });
  }

  List<DateTime> _buildMonthPickerItems() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    return List.generate(24, (index) {
      return DateTime(start.year, start.month + index);
    });
  }

  Future<void> addShift(Shift shift) async {
    setState(() {
      shifts.add(shift);
      selectedMonth = DateTime(shift.start.year, shift.start.month);
      selectedDay = _normalizeDate(shift.start);
      shifts.sort((a, b) => b.start.compareTo(a.start));
    });
    await saveShifts();
  }

  Future<void> updateShift(int index, Shift shift) async {
    setState(() {
      shifts[index] = shift;
      selectedMonth = DateTime(shift.start.year, shift.start.month);
      selectedDay = _normalizeDate(shift.start);
      shifts.sort((a, b) => b.start.compareTo(a.start));
    });
    await saveShifts();
  }

  Future<void> removeShift(int index) async {
    setState(() {
      shifts.removeAt(index);
    });
    await saveShifts();
  }

  Future<void> openAddShift() async {
    final newShift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddShiftPage(
          onAdd: (shift) => Navigator.of(context).pop(shift),
          rates: payProfile,
          initialDate: selectedDay,
        ),
      ),
    );

    if (newShift != null && newShift is Shift) {
      await addShift(newShift);
    }
  }

  Future<void> openEditShift(int index) async {
    final editedShift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddShiftPage(
          onAdd: (shift) => Navigator.of(context).pop(shift),
          rates: payProfile,
          initialShift: shifts[index],
        ),
      ),
    );

    if (editedShift != null && editedShift is Shift) {
      await updateShift(index, editedShift);
    }
  }

  Future<void> openCalibratePayslips() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalibratePayslipsPage(),
      ),
    );

    if (result == true) {
      await loadData();
    }
  }

  Future<void> pickMonth() async {
    final months = _buildMonthPickerItems();

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF171A21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
              maxHeight: 520,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                    'Seleziona mese',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      itemCount: months.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.white10,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final month = months[index];
                        final isSelected =
                            month.year == selectedMonth.year &&
                            month.month == selectedMonth.month;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(
                            _formatMonthYear(month),
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF22C55E)
                                  : Colors.white,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF22C55E),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, month),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedMonth = DateTime(result.year, result.month);
        selectedDay = DateTime(result.year, result.month, 1);
      });
    }
  }

  String _formatShiftDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    return '${months[date.month - 1][0].toUpperCase()}${months[date.month - 1].substring(1)} ${date.year}';
  }

  String _formatSelectedDayTitle(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Shift shift, int index) {
    final shiftIndex = shifts.indexOf(shift);
    final orderPublicAmount = shift.getOrderPublicAmount(payProfile);
    final totalAmount = shift.getTotalAmount(payProfile);
    final extraAmount = totalAmount - orderPublicAmount;
    final breakdown = shift.getBreakdown(payProfile);

    return Dismissible(
      key: ValueKey('${shift.start.toIso8601String()}_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF171A21),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Elimina turno',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'Sei sicuro di voler eliminare questo turno?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annulla'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Elimina',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        if (shiftIndex >= 0) {
          removeShift(shiftIndex);
        }
      },
      child: GestureDetector(
        onTap: () {
          if (shiftIndex >= 0) {
            openEditShift(shiftIndex);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF171A21),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      shift.description.isEmpty
                          ? 'Turno senza descrizione'
                          : shift.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${shift.hours.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€ ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _formatShiftDate(shift.start),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip('OP: ${shift.effectiveOrderPublicLabel}'),
                  _infoChip('Esterno: ${shift.externalService ? "Sì" : "No"}'),
                  _infoChip('Assenza: ${shift.absence}'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _miniInfo(
                      'Straordinario',
                      shift.overtimeHours > 0
                          ? '${shift.overtimeHours.toStringAsFixed(1)}h'
                          : 'Nessuno',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniInfo(
                      'Extra',
                      '€ ${extraAmount.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dettaglio calcolo',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...breakdown.map((item) {
                        final label = item['label'] as String;
                        final amount =
                            (item['amount'] as num?)?.toDouble() ?? 0.0;
                        return _buildBreakdownRow(label, amount);
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EstimatedSalaryCard(
          baseNet: estimatedBaseNet,
          extraNet: estimatedExtraNet,
          extraGross: estimatedExtraGross,
          taxes: estimatedTaxesOnExtras,
          monthLabel: _formatMonthYear(selectedMonth),
          workedDays: workedDaysCount,
          totalDays: daysInSelectedMonth,
          avgPerDay: averagePerWorkedDay,
          projectedTotal: estimatedEndOfMonth,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Color(0xFF22C55E),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  workedDaysCount == 0
                      ? 'Aggiungi turni per vedere una stima'
                      : 'Se mantieni questo ritmo, potresti aggiungere circa € ${projectedExtraFuture.toStringAsFixed(0)} entro fine mese',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Benvenuto in DutyPay, ${widget.userName}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'La piattaforma per calcolare in modo preciso i guadagni extra giornalieri e stimare il tuo prossimo cedolino.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _miniInfo(
                'Giorni lavorati',
                workedDaysCount.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniInfo(
                'Aliquota stimata',
                '${(effectiveTaxRate * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _miniInfo(
          'Range cedolino stimato',
          '€ ${estimatedRangeMin.toStringAsFixed(0)} - € ${estimatedRangeMax.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Mese precedente',
        ),
        Expanded(
          child: GestureDetector(
            onTap: pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatMonthYear(selectedMonth),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _goToNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Mese successivo',
        ),
      ],
    );
  }

  Widget _buildSelectedDaySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turni del ${_formatSelectedDayTitle(selectedDay)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedDayShifts.isEmpty)
            const Text(
              'Nessun turno per questo giorno.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            )
          else
            ...selectedDayShifts.asMap().entries.map(
              (entry) => _buildShiftCard(entry.value, entry.key),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DutyPay'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Calibra profilo',
            onPressed: openCalibratePayslips,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  _buildHeaderContent(),
                  _buildCalendarHeader(),
                  const SizedBox(height: 12),
                  MonthCalendarCard(
                    month: selectedMonth,
                    days: calendarDays,
                    onDayTap: (date) {
                      setState(() {
                        selectedDay = _normalizeDate(date);
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSelectedDaySection(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      onPressed: openAddShift,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aggiungi turno',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}