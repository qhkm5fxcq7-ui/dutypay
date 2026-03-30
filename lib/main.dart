
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/data_backup_service.dart';
import 'features/home/widgets/month_calendar_card.dart';
import 'features/payslip/presentation/payslip_page.dart';
import 'features/shifts/presentation/calibrate_payslips_page.dart';
import 'features/shifts/presentation/models/shift.dart';
import 'features/shifts/presentation/models/user_pay_profile.dart';
import 'features/shifts/presentation/quick_add_shift_page.dart';
import 'features/shifts/presentation/services/payslip_projection_service.dart';

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

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme.dark(
      primary: DutyPayPalette.primary,
      secondary: DutyPayPalette.info,
      surface: DutyPayPalette.card,
      error: DutyPayPalette.danger,
    );

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DutyPayPalette.background,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: DutyPayPalette.divider,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF18212C),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DutyPayPalette.surface,
        labelStyle: const TextStyle(
          color: DutyPayPalette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: DutyPayPalette.textHint,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: DutyPayPalette.cardBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: DutyPayPalette.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: DutyPayPalette.primary,
            width: 1.2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DutyPayPalette.card,
        indicatorColor: DutyPayPalette.primary.withOpacity(0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12.8,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : DutyPayPalette.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? DutyPayPalette.primary : DutyPayPalette.textSecondary,
            size: 22,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DutyPayPalette.primary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: DutyPayPalette.cardBorder),
          backgroundColor: DutyPayPalette.surface.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DutyPayPalette.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DutyPayPalette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _buildTheme();

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DutyPayPalette.background,
              DutyPayPalette.backgroundSoft,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: DutyPayPalette.card,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: DutyPayPalette.cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: DutyPayPalette.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: DutyPayPalette.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Benvenuto in DutyPay',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'L’app pensata per capire subito quanto stai costruendo con i tuoi turni, senza schermate complicate.',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: DutyPayPalette.textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Il tuo nome',
                          hintText: 'Es. Manuel',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(_isSaving ? 'Salvataggio...' : 'Continua'),
                        ),
                      ),
                    ],
                  ),
                ),
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
  static const String basketPaymentsStorageKey = 'dutypay_basket_payments';

  final PayslipProjectionService _projectionService =
      const PayslipProjectionService();

  final List<Shift> shifts = [];
  final List<BasketPayment> basketPayments = [];

  bool isLoading = true;
  int selectedTabIndex = 0;

  late DateTime selectedMonth;
  late DateTime selectedDay;
  late DateTime selectedPayslipMonth;


  UserPayProfile payProfile = UserPayProfile.defaultProfile();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    selectedDay = DateTime(now.year, now.month, now.day);
    selectedPayslipMonth = DateTime(now.year, now.month);
    loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedShifts = await _loadShiftsFromPrefs(prefs);
    loadedShifts.sort((a, b) => b.start.compareTo(a.start));

    final rawProfile = prefs.getString(payProfileStorageKey);
    final loadedProfile = _loadPayProfile(rawProfile);

    final rawBasketPayments = prefs.getString(basketPaymentsStorageKey);
    final loadedBasketPayments = _loadBasketPayments(rawBasketPayments);

    if (!mounted) return;

    setState(() {
      shifts
        ..clear()
        ..addAll(loadedShifts);
      payProfile = loadedProfile;
      basketPayments
        ..clear()
        ..addAll(loadedBasketPayments);
      isLoading = false;
    });
  }

  Future<List<Shift>> _loadShiftsFromPrefs(SharedPreferences prefs) async {
    try {
      final rawJson = prefs.getString(shiftsStorageKey);

      if (rawJson != null && rawJson.trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => Shift.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        }
      }
    } catch (_) {}

    final rawLegacyList = prefs.getStringList(shiftsStorageKey);
    if (rawLegacyList == null || rawLegacyList.isEmpty) {
      return [];
    }

    final migrated = <Shift>[];

    for (final item in rawLegacyList) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          migrated.add(
            Shift.fromJson(Map<String, dynamic>.from(decoded as Map)),
          );
        }
      } catch (_) {}
    }

    await _saveShiftsToPrefs(prefs, migrated);
    return migrated;
  }

  UserPayProfile _loadPayProfile(String? rawProfile) {
    if (rawProfile == null || rawProfile.trim().isEmpty) {
      return UserPayProfile.defaultProfile();
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is Map) {
        return UserPayProfile.fromJson(
          Map<String, dynamic>.from(decoded as Map),
        );
      }
    } catch (_) {}

    return UserPayProfile.defaultProfile();
  }

  List<BasketPayment> _loadBasketPayments(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => BasketPayment.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList()
          ..sort((a, b) => a.paymentMonth.compareTo(b.paymentMonth));
      }
    } catch (_) {}

    return [];
  }

  Future<void> _saveBasketPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      basketPayments.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(basketPaymentsStorageKey, raw);
  }

  Future<void> addBasketPayment(
    DateTime paymentMonth,
    double hoursPaid,
    String note,
  ) async {
    final payment = BasketPayment(
      paymentMonth: DateTime(paymentMonth.year, paymentMonth.month),
      hoursPaid: hoursPaid,
      note: note,
    );

    final projectionForMonth = _projectionService.projectPayslip(
      payslipMonth: payment.paymentMonth,
      allShifts: shifts,
      payProfile: payProfile,
      basketPayments: basketPayments,
    );

    final availableHours = projectionForMonth.currentBasketResidualHours;

    if (availableHours <= 0) {
      throw Exception('Non ci sono ore disponibili nel basket');
    }

    if (payment.hoursPaid > availableHours) {
      throw Exception(
        'Non puoi scaricare più di ${availableHours.toStringAsFixed(1)} ore',
      );
    }

    setState(() {
      basketPayments.add(payment);
      basketPayments.sort((a, b) => a.paymentMonth.compareTo(b.paymentMonth));
    });

    await _saveBasketPayments();
  }

  Future<void> saveShifts() async {
    shifts.sort((a, b) => b.start.compareTo(a.start));
    final prefs = await SharedPreferences.getInstance();
    await _saveShiftsToPrefs(prefs, shifts);
  }

  Future<void> _saveShiftsToPrefs(
    SharedPreferences prefs,
    List<Shift> shiftsToSave,
  ) async {
    final rawJson = jsonEncode(
      shiftsToSave.map((shift) => shift.toJson()).toList(),
    );
    await prefs.setString(shiftsStorageKey, rawJson);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  List<Shift> get filteredShifts {
    return shifts.where((shift) {
      return shift.serviceDate.year == selectedMonth.year &&
          shift.serviceDate.month == selectedMonth.month;
    }).toList();
  }

  List<Shift> get selectedDayShifts {
    return filteredShifts
        .where((shift) => _isSameDay(shift.serviceDate, selectedDay))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  double get totalMonth {
    return filteredShifts.fold(
      0.0,
      (sum, shift) => sum + shift.getTotalAmount(payProfile),
    );
  }

  double get todayTotal {
    final now = DateTime.now();

    return shifts.where((shift) {
      return shift.serviceDate.year == now.year &&
          shift.serviceDate.month == now.month &&
          shift.serviceDate.day == now.day;
    }).fold(
      0.0,
      (sum, shift) => sum + shift.getTotalAmount(payProfile),
    );
  }

  double get weekTotal {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return shifts.where((shift) {
      final day = shift.serviceDate;
      return day.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          day.isBefore(now.add(const Duration(days: 1)));
    }).fold(
      0.0,
      (sum, shift) => sum + shift.getTotalAmount(payProfile),
    );
  }

  int get workedDaysCount {
    final uniqueDays = <String>{};

    for (final shift in filteredShifts) {
      if (shift.hasAbsence) continue;

      final day = shift.serviceDate;
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

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

  double _dailyTotal(DateTime date) {
    return filteredShifts
        .where((shift) => _isSameDay(shift.serviceDate, date))
        .fold(0.0, (sum, shift) => sum + shift.getTotalAmount(payProfile));
  }

  String? _absenceBadgeForDate(DateTime date) {
    final dayShifts = filteredShifts
        .where((shift) => _isSameDay(shift.serviceDate, date))
        .toList();

    if (dayShifts.isEmpty) return null;

    bool hasCongedoOrdinario = false;
    bool hasMalattia = false;
    bool hasRiposo = false;

    for (final shift in dayShifts) {
      final absence = shift.absence.trim().toLowerCase();

      if (absence == 'ferie' || absence == 'congedo ordinario') {
        hasCongedoOrdinario = true;
      } else if (absence == 'malattia') {
        hasMalattia = true;
      } else if (absence == 'riposo') {
        hasRiposo = true;
      }
    }

    if (hasCongedoOrdinario) return 'C.O.';
    if (hasMalattia) return 'MAL';
    if (hasRiposo) return 'RIP';

    return null;
  }

  List<MonthCalendarDayData> get calendarDays {
    final firstDayOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month, 1);
    final startWeekday = firstDayOfMonth.weekday;
    final gridStart = firstDayOfMonth.subtract(Duration(days: startWeekday - 1));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      final isInCurrentMonth = date.month == selectedMonth.month;

      return MonthCalendarDayData(
        date: date,
        isInCurrentMonth: isInCurrentMonth,
        amount: isInCurrentMonth ? _dailyTotal(date) : 0.0,
        isSelected: _isSameDay(date, selectedDay),
        isToday: _isSameDay(date, today),
        absenceBadge: isInCurrentMonth ? _absenceBadgeForDate(date) : null,
      );
    });
  }

  PayslipProjectionResult get payslipProjection {
    return _projectionService.projectPayslip(
      payslipMonth: selectedPayslipMonth,
      allShifts: shifts,
      payProfile: payProfile,
      basketPayments: basketPayments,
    );
  }

  PrecisionStatus get payslipPrecisionStatus {
    return _projectionService.calculatePrecision(
      allShifts: shifts,
    );
  }

  _MonthlyLiveProjection _buildMonthlyLiveProjection({
    required DateTime month,
    required double fixedBaseNet,
  }) {
    final monthShifts = shifts.where((shift) {
      return shift.serviceDate.year == month.year &&
          shift.serviceDate.month == month.month;
    }).toList();

    final extraGross = monthShifts.fold<double>(
      0.0,
      (sum, shift) => sum + shift.getTotalAmount(payProfile),
    );

    final effectiveTaxRate = payProfile.effectiveTaxRate.isFinite &&
            payProfile.effectiveTaxRate >= 0
        ? payProfile.effectiveTaxRate.clamp(0.0, 0.45)
        : 0.2625;

    final extraNet = extraGross * (1 - effectiveTaxRate);
    final taxes = extraGross - extraNet;

    final uniqueWorkedDays = <String>{};
    for (final shift in monthShifts) {
      if (shift.hasAbsence) continue;

      final day = shift.serviceDate;
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      uniqueWorkedDays.add(key);
    }

    final workedDays = uniqueWorkedDays.length;
    final totalDays = _daysInMonth(month);
    final avgPerDay = workedDays > 0 ? extraNet / workedDays : 0.0;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final isCurrentMonth = _isSameMonth(month, currentMonth);

    final remainingDays = isCurrentMonth
        ? ((totalDays - now.day) > 0 ? (totalDays - now.day) : 0)
        : 0;

    final projectedTotal = isCurrentMonth && workedDays > 0
        ? fixedBaseNet + extraNet + (avgPerDay * remainingDays)
        : fixedBaseNet + extraNet;

    return _MonthlyLiveProjection(
      baseNet: fixedBaseNet,
      extraGross: extraGross,
      extraNet: extraNet,
      taxes: taxes,
      workedDays: workedDays,
      totalDays: totalDays,
      avgPerDay: avgPerDay,
      projectedTotal: projectedTotal,
      isCurrentMonth: isCurrentMonth,
    );
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
      selectedMonth = DateTime(shift.serviceDate.year, shift.serviceDate.month);
      selectedDay = _normalizeDate(shift.serviceDate);
      shifts.sort((a, b) => b.start.compareTo(a.start));
    });
    await saveShifts();
  }

  Future<void> updateShift(int index, Shift shift) async {
    setState(() {
      shifts[index] = shift;
      selectedMonth = DateTime(shift.serviceDate.year, shift.serviceDate.month);
      selectedDay = _normalizeDate(shift.serviceDate);
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
    } else if (newShift != null && newShift is List<Shift>) {
      setState(() {
        shifts.addAll(newShift);
        shifts.sort((a, b) => b.start.compareTo(a.start));
      });
      await saveShifts();
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
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      itemCount: months.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: DutyPayPalette.divider,
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: isSelected
                              ? DutyPayPalette.primary.withOpacity(0.10)
                              : Colors.transparent,
                          title: Text(
                            _formatMonthYear(month),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? DutyPayPalette.primary
                                  : Colors.white,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: DutyPayPalette.primary,
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

  String _formatShiftDate(Shift shift) {
    final service = shift.serviceDate;
    final serviceDay = service.day.toString().padLeft(2, '0');
    final serviceMonth = service.month.toString().padLeft(2, '0');
    final serviceYear = service.year.toString();

    final startDay = shift.start.day.toString().padLeft(2, '0');
    final startMonth = shift.start.month.toString().padLeft(2, '0');
    final startYear = shift.start.year.toString();
    final startHour = shift.start.hour.toString().padLeft(2, '0');
    final startMinute = shift.start.minute.toString().padLeft(2, '0');

    if (_isSameDay(service, shift.start)) {
      return '$serviceDay/$serviceMonth/$serviceYear • $startHour:$startMinute';
    }

    return 'Servizio: $serviceDay/$serviceMonth/$serviceYear • Start: $startDay/$startMonth/$startYear • $startHour:$startMinute';
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

  String _formatCurrency(double value) {
    return '€ ${value.toStringAsFixed(2)}';
  }

  Widget _infoChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.2,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DutyPayPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DutyPayPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: DutyPayPalette.textSecondary,
            ),
            const SizedBox(height: 10),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.8,
              color: DutyPayPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              color: valueColor ?? Colors.white,
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
                color: DutyPayPalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontSize: 13.2,
              color: DutyPayPalette.primary,
              fontWeight: FontWeight.w800,
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

    final hasAbsence = shift.hasAbsence;
    final isExternal = shift.externalService;
    final hasOrderPublic =
        shift.effectiveOrderPublicLabel.trim().toLowerCase() != 'nessuno';

    return Dismissible(
      key: ValueKey('${shift.start.toIso8601String()}_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(
                  'Elimina turno',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'Sei sicuro di voler eliminare questo turno?',
                  style: TextStyle(color: DutyPayPalette.textSecondary),
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
                      style: TextStyle(color: DutyPayPalette.danger),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: DutyPayPalette.danger,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
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
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DutyPayPalette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DutyPayPalette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
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
                          color: DutyPayPalette.textSecondary,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(totalAmount),
                        style: const TextStyle(
                          color: DutyPayPalette.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _formatShiftDate(shift),
                style: const TextStyle(
                  fontSize: 13.2,
                  color: DutyPayPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasOrderPublic)
                    _infoChip(
                      label: 'OP: ${shift.effectiveOrderPublicLabel}',
                      color: DutyPayPalette.info,
                    ),
                  if (isExternal)
                    _infoChip(
                      label: 'Servizio esterno',
                      color: DutyPayPalette.warning,
                    ),
                  if (hasAbsence)
                    _infoChip(
                      label: 'Assenza: ${shift.absence}',
                      color: DutyPayPalette.danger,
                    ),
                  if (!hasOrderPublic && !isExternal && !hasAbsence)
                    _infoChip(
                      label: 'Turno standard',
                      color: DutyPayPalette.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      label: 'Straordinario',
                      value: shift.overtimeHours > 0
                          ? '${shift.overtimeHours.toStringAsFixed(1)}h'
                          : 'Nessuno',
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statTile(
                      label: 'Extra generati',
                      value: _formatCurrency(extraAmount),
                      valueColor: DutyPayPalette.primary,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DutyPayPalette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: DutyPayPalette.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dettaglio calcolo',
                        style: TextStyle(
                          fontSize: 13,
                          color: DutyPayPalette.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
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

  Widget _buildTurnsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2030),
            Color(0xFF111723),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF2B364C),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bentornato, ${widget.userName}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inserisci i turni, controlla il calendario e capisci subito quanto stai accumulando.',
            style: TextStyle(
              fontSize: 14.5,
              color: DutyPayPalette.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Oggi',
                  value: _formatCurrency(todayTotal),
                  valueColor: DutyPayPalette.primary,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Settimana',
                  value: _formatCurrency(weekTotal),
                  valueColor: DutyPayPalette.info,
                  icon: Icons.date_range_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Giorni lavorati',
                  value: workedDaysCount.toString(),
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Media giornaliera',
                  value: _formatCurrency(averagePerWorkedDay),
                  valueColor: DutyPayPalette.warning,
                  icon: Icons.analytics_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DutyPayPalette.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: DutyPayPalette.primary.withOpacity(0.22),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: DutyPayPalette.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    workedDaysCount == 0
                        ? 'Aggiungi i primi turni per vedere una proiezione del ritmo mensile.'
                        : 'Se mantieni questo ritmo, potresti aggiungere circa ${_formatCurrency(projectedExtraFuture)} entro fine mese.',
                    style: const TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w700,
                      color: DutyPayPalette.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await DataBackupService.exportData();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup esportato con successo'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore export: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Esporta dati'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await DataBackupService.importData();
                      await loadData();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup importato con successo'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Errore import: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Importa dati'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Mese precedente',
          onTap: _goToPreviousMonth,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: DutyPayPalette.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DutyPayPalette.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatMonthYear(selectedMonth),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: DutyPayPalette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Mese successivo',
          onTap: _goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildSelectedDaySection() {
    final selectedDayTotal = selectedDayShifts.fold<double>(
      0.0,
      (sum, shift) => sum + shift.getTotalAmount(payProfile),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: DutyPayPalette.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DutyPayPalette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turni del ${_formatSelectedDayTitle(selectedDay)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Turni del giorno',
                  value: selectedDayShifts.length.toString(),
                  icon: Icons.list_alt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Totale giorno',
                  value: _formatCurrency(selectedDayTotal),
                  valueColor: DutyPayPalette.primary,
                  icon: Icons.euro_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedDayShifts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DutyPayPalette.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DutyPayPalette.cardBorder),
              ),
              child: const Text(
                'Nessun turno per questo giorno.',
                style: TextStyle(
                  color: DutyPayPalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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

  Widget _buildTurnsPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DutyPayPalette.background,
            DutyPayPalette.backgroundSoft,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: ListView(
            children: [
              _buildTurnsHeader(),
              const SizedBox(height: 18),
              _buildCalendarHeader(),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: DutyPayPalette.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DutyPayPalette.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: MonthCalendarCard(
                  month: selectedMonth,
                  days: calendarDays,
                  onDayTap: (date) {
                    setState(() {
                      selectedDay = _normalizeDate(date);
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),
              _buildSelectedDaySection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openAddShift,
                  icon: const Icon(Icons.add_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Aggiungi turno',
                      style: TextStyle(fontSize: 15.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayslipPage() {
    final projection = payslipProjection;

    _buildMonthlyLiveProjection(
      month: selectedPayslipMonth,
      fixedBaseNet: projection.fixedBaseNetEstimated,
    );

    return PayslipPage(
      projection: projection,
      selectedMonth: selectedPayslipMonth,
      onOpenCalibration: openCalibratePayslips,
      onAddBasketPayment: addBasketPayment,
      precision: payslipPrecisionStatus,
    );
  }


  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildTurnsPage(),
      _buildPayslipPage(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('DutyPay'),
       actions: [
  if (selectedTabIndex == 1)
    Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton(
        tooltip: 'Carica cedolini',
        onPressed: openCalibratePayslips,
        icon: const Icon(Icons.upload_file_rounded),
      ),
    ),
],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[selectedTabIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            height: 72,
            selectedIndex: selectedTabIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedTabIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Turni',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Cedolino',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: selectedTabIndex == 0
          ? FloatingActionButton(
              onPressed: openAddShift,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DutyPayPalette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DutyPayPalette.cardBorder),
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MonthlyLiveProjection {
  final double baseNet;
  final double extraGross;
  final double extraNet;
  final double taxes;
  final int workedDays;
  final int totalDays;
  final double avgPerDay;
  final double projectedTotal;
  final bool isCurrentMonth;

  const _MonthlyLiveProjection({
    required this.baseNet,
    required this.extraGross,
    required this.extraNet,
    required this.taxes,
    required this.workedDays,
    required this.totalDays,
    required this.avgPerDay,
    required this.projectedTotal,
    required this.isCurrentMonth,
  });
}

class DutyPayPalette {
  static const background = Color(0xFF0B0F14);
  static const backgroundSoft = Color(0xFF11161E);

  static const card = Color(0xFF121922);
  static const surface = Color(0xFF18212C);

  static const cardBorder = Color(0xFF253140);
  static const divider = Color(0xFF24303E);

  static const textPrimary = Color(0xFFF2F6FA);
  static const textSecondary = Color(0xFF9AA8B7);
  static const textHint = Color(0xFF708092);

  static const primary = Color(0xFF5CE1A8);
  static const info = Color(0xFF67B7FF);
  static const warning = Color(0xFFFFC14D);
  static const danger = Color(0xFFFF6B6B);
}