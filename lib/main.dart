import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/data_backup_service.dart';
import 'features/break/presentation/break_page.dart';
import 'features/home/widgets/month_calendar_card.dart';
import 'features/payslip/presentation/payslip_page.dart';
import 'features/shifts/application/models/daily_shift_computation.dart';
import 'features/shifts/application/models/daily_shift_result.dart';
import 'features/shifts/application/models/monthly_summary.dart';
import 'features/shifts/application/models/compensative_basket_movement.dart';
import 'features/shifts/application/usecases/build_compensative_basket_movements_usecase.dart';
import 'features/shifts/application/usecases/build_compensative_basket_summary_from_movements_usecase.dart';
import 'features/shifts/application/usecases/build_daily_shift_result_usecase.dart';
import 'features/shifts/application/usecases/build_monthly_summary_usecase.dart';
import 'features/shifts/application/usecases/build_shift_computation_usecase.dart';
import 'features/shifts/domain/engine/models/basket_payment.dart';
import 'features/shifts/domain/engine/models/payslip_projection_result.dart';
import 'features/shifts/domain/engine/models/precision_status.dart';
import 'features/shifts/domain/engine/models/rfi_basket_payment.dart';
import 'features/shifts/domain/engine/models/overtime_basket_adjustment.dart';
import 'features/shifts/presentation/calibrate_payslips_page.dart';
import 'features/shifts/presentation/department_selection_page.dart';
import 'features/shifts/presentation/models/department.dart';
import 'features/shifts/presentation/models/shift.dart';
import 'features/shifts/presentation/models/user_pay_profile.dart';
import 'features/shifts/presentation/quick_add_shift_page.dart';
import 'features/shifts/presentation/services/payslip_projection_service.dart';
import 'features/shifts/application/usecases/manage_compensative_basket_adjustments_usecase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    firebaseReady = true;

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await FirebaseAnalytics.instance.logAppOpen();
  } catch (_) {
    firebaseReady = false;
  }

  runZonedGuarded<Future<void>>(() async {
    runApp(const DutyPayApp());
  }, (error, stack) {
    if (firebaseReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

class DutyPayApp extends StatefulWidget {
  const DutyPayApp({super.key});

  @override
  State<DutyPayApp> createState() => _DutyPayAppState();
}

class _DutyPayAppState extends State<DutyPayApp> {
  static const String _userNameStorageKey = 'dutypay_user_name';
  static const String _activeDepartmentStorageKey = 'dutypay_active_department';

  bool isLoading = true;
  String? userName;
  Department? activeDepartment;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_userNameStorageKey)?.trim();
    final savedDepartmentId = prefs.getString(_activeDepartmentStorageKey);

    Department? resolvedDepartment;
    if (savedDepartmentId != null) {
      for (final dept in Department.values) {
        if (dept.id == savedDepartmentId) {
          resolvedDepartment = dept;
          break;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      userName = (savedName == null || savedName.isEmpty) ? null : savedName;
      activeDepartment = resolvedDepartment;
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

  Future<void> _handleDepartmentSelected(Department department) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeDepartmentStorageKey, department.id);

    if (!mounted) return;

    setState(() {
      activeDepartment = department;
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
          borderSide: const BorderSide(color: DutyPayPalette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DutyPayPalette.cardBorder),
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
        indicatorColor: DutyPayPalette.primary.withValues(alpha: 0.14),
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
            color: selected
                ? DutyPayPalette.primary
                : DutyPayPalette.textSecondary,
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
          backgroundColor: DutyPayPalette.surface.withValues(alpha: 0.35),
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
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'DutyPay',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('it'),
      supportedLocales: const [Locale('it'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: userName == null
          ? OnboardingPage(onCompleted: _handleOnboardingCompleted)
          : activeDepartment == null
              ? DepartmentSelectionPage(
                  initialDepartment: null,
                  onSelected: _handleDepartmentSelected,
                )
              : DutyPayHomePage(
                  key: ValueKey(activeDepartment!.id),
                  userName: userName!,
                  activeDepartment: activeDepartment!,
                  onDepartmentChanged: _handleDepartmentSelected,
                ),
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
                    border: Border.all(color: DutyPayPalette.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
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
                          color: DutyPayPalette.primary.withValues(alpha: 0.12),
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
  final Department activeDepartment;
  final Future<void> Function(Department department) onDepartmentChanged;

  const DutyPayHomePage({
    super.key,
    required this.userName,
    required this.activeDepartment,
    required this.onDepartmentChanged,
  });

  @override
  State<DutyPayHomePage> createState() => _DutyPayHomePageState();
}

class _DutyPayHomePageState extends State<DutyPayHomePage> {
  static const String _legacyShiftsStorageKey = 'dutypay_shifts';
  static const String _legacyPayProfileStorageKey = 'dutypay_pay_profile';
  static const String _legacyBasketPaymentsStorageKey =
      'dutypay_basket_payments';

  String get _storageScope => widget.activeDepartment.id;
  String get shiftsStorageKey => 'dutypay_shifts_$_storageScope';
  String get payProfileStorageKey => 'dutypay_pay_profile_$_storageScope';
  String get basketPaymentsStorageKey =>
      'dutypay_basket_payments_$_storageScope';
  String get rfiBasketPaymentsStorageKey =>
      'dutypay_rfi_basket_payments_$_storageScope';
  String get overtimeBasketAdjustmentsStorageKey =>
    'dutypay_overtime_basket_adjustments_$_storageScope';
  String get compensativeBasketMovementsStorageKey =>
    'dutypay_compensative_basket_movements_$_storageScope';
  String get monthNotesStorageKey => 'dutypay_month_notes_$_storageScope';

  bool get _isRepartoMobileScope =>
      widget.activeDepartment == Department.repartoMobile;

  final PayslipProjectionService _projectionService =
      const PayslipProjectionService();
  final BuildShiftComputationUseCase _buildShiftComputationUseCase =
      const BuildShiftComputationUseCase();
  final BuildDailyShiftResultUseCase _buildDailyShiftResultUseCase =
      const BuildDailyShiftResultUseCase();
  final BuildMonthlySummaryUseCase _buildMonthlySummaryUseCase =
      const BuildMonthlySummaryUseCase();

  final BuildCompensativeBasketMovementsUseCase
    _buildCompensativeBasketMovementsUseCase =
        const BuildCompensativeBasketMovementsUseCase();

final BuildCompensativeBasketSummaryFromMovementsUseCase
    _buildCompensativeBasketSummaryFromMovementsUseCase =
        const BuildCompensativeBasketSummaryFromMovementsUseCase();
  final ManageCompensativeBasketAdjustmentsUseCase
    _manageCompensativeBasketAdjustmentsUseCase =
        const ManageCompensativeBasketAdjustmentsUseCase();
  final List<Shift> shifts = [];
  final List<BasketPayment> basketPayments = [];
  final List<RfiBasketPayment> rfiBasketPayments = [];
  final List<OvertimeBasketAdjustment> overtimeBasketAdjustments = [];
  final List<CompensativeBasketMovement> manualCompensativeBasketMovements = [];

  bool isLoading = true;
  int selectedTabIndex = 0;

  late DateTime selectedMonth;
  late DateTime selectedDay;
  late DateTime selectedPayslipMonth;

  UserPayProfile payProfile = UserPayProfile.defaultProfile();
  String searchQuery = '';

  Future<void> _confirmAndClearAllData() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancella tutti i dati'),
      content: const Text(
        'Questa operazione elimina turni, profilo, basket, note e dati salvati del reparto attivo. Vuoi continuare?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cancella'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final prefs = await SharedPreferences.getInstance();

  await prefs.remove(shiftsStorageKey);
  await prefs.remove(payProfileStorageKey);
  await prefs.remove(basketPaymentsStorageKey);
  await prefs.remove(rfiBasketPaymentsStorageKey);
  await prefs.remove(overtimeBasketAdjustmentsStorageKey);
  await prefs.remove(compensativeBasketMovementsStorageKey);
  await prefs.remove(monthNotesStorageKey);

  setState(() {
    shifts.clear();
    basketPayments.clear();
    rfiBasketPayments.clear();
    overtimeBasketAdjustments.clear();
    manualCompensativeBasketMovements.clear();
    payProfile = UserPayProfile.defaultProfile();
    searchQuery = '';
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Dati del reparto cancellati'),
    ),
  );
}

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
  void didUpdateWidget(DutyPayHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activeDepartment != widget.activeDepartment) {
      setState(() {
        isLoading = true;
        shifts.clear();
        basketPayments.clear();
        rfiBasketPayments.clear();
        overtimeBasketAdjustments.clear();
        payProfile = UserPayProfile.defaultProfile();
        searchQuery = '';

        final now = DateTime.now();
        selectedMonth = DateTime(now.year, now.month);
        selectedDay = DateTime(now.year, now.month, now.day);
        selectedPayslipMonth = DateTime(now.year, now.month);
      });

      loadData();
    }
  }

  String _activeDepartmentLabel() {
    return widget.activeDepartment.label;
  }

  Future<String?> _readScopedString({
    required SharedPreferences prefs,
    required String scopedKey,
    required String legacyKey,
  }) async {
    final scoped = prefs.getString(scopedKey);
    if (scoped != null) return scoped;

    if (_isRepartoMobileScope) {
      final legacy = prefs.getString(legacyKey);
      if (legacy != null) {
        await prefs.setString(scopedKey, legacy);
        return legacy;
      }
    }

    return null;
  }

  Future<List<String>?> _readScopedStringList({
    required SharedPreferences prefs,
    required String scopedKey,
    required String legacyKey,
  }) async {
    final scoped = prefs.getStringList(scopedKey);
    if (scoped != null) return scoped;

    if (_isRepartoMobileScope) {
      final legacy = prefs.getStringList(legacyKey);
      if (legacy != null) {
        await prefs.setStringList(scopedKey, legacy);
        return legacy;
      }
    }

    return null;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedShifts = await _loadShiftsFromPrefs(prefs);
    loadedShifts.sort((a, b) => b.start.compareTo(a.start));

    final rawProfile = await _readScopedString(
      prefs: prefs,
      scopedKey: payProfileStorageKey,
      legacyKey: _legacyPayProfileStorageKey,
    );
    final loadedProfile = _loadPayProfile(rawProfile);

    final rawBasketPayments = await _readScopedString(
      prefs: prefs,
      scopedKey: basketPaymentsStorageKey,
      legacyKey: _legacyBasketPaymentsStorageKey,
    );
    final loadedBasketPayments = _loadBasketPayments(rawBasketPayments);

    final rawRfiBasketPayments = prefs.getString(rfiBasketPaymentsStorageKey);
    final loadedRfiBasketPayments =
        _loadRfiBasketPayments(rawRfiBasketPayments);
    final rawOvertimeBasketAdjustments =
    prefs.getString(overtimeBasketAdjustmentsStorageKey);

final loadedOvertimeBasketAdjustments =
    _loadOvertimeBasketAdjustments(rawOvertimeBasketAdjustments);

    final rawCompensativeMovements =
    prefs.getString(compensativeBasketMovementsStorageKey);

final loadedCompensativeMovements =
    _loadCompensativeBasketMovements(rawCompensativeMovements);

    if (!mounted) return;

    setState(() {
      shifts
        ..clear()
        ..addAll(loadedShifts);
      basketPayments
        ..clear()
        ..addAll(loadedBasketPayments);
      rfiBasketPayments
        ..clear()
        ..addAll(loadedRfiBasketPayments);
        overtimeBasketAdjustments
  ..clear()
  ..addAll(loadedOvertimeBasketAdjustments);
        manualCompensativeBasketMovements
  ..clear()
  ..addAll(loadedCompensativeMovements);
      payProfile = loadedProfile;
      isLoading = false;
    });
  }

  Future<List<Shift>> _loadShiftsFromPrefs(SharedPreferences prefs) async {
    try {
      final rawJson = await _readScopedString(
        prefs: prefs,
        scopedKey: shiftsStorageKey,
        legacyKey: _legacyShiftsStorageKey,
      );

      if (rawJson != null && rawJson.trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);

        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => Shift.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }
    } catch (_) {}

    final rawLegacyList = await _readScopedStringList(
      prefs: prefs,
      scopedKey: shiftsStorageKey,
      legacyKey: _legacyShiftsStorageKey,
    );

    if (rawLegacyList == null || rawLegacyList.isEmpty) {
      return [];
    }

    final migrated = <Shift>[];

    for (final item in rawLegacyList) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          migrated.add(
            Shift.fromJson(Map<String, dynamic>.from(decoded)),
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
          Map<String, dynamic>.from(decoded),
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
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
          ..sort((a, b) => a.paymentMonth.compareTo(b.paymentMonth));
      }
    } catch (_) {}

    return [];
  }

  List<RfiBasketPayment> _loadRfiBasketPayments(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (item) => RfiBasketPayment.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
          ..sort((a, b) => a.sourceMonth.compareTo(b.sourceMonth));
      }
    } catch (_) {}

    return [];
  }

List<OvertimeBasketAdjustment> _loadOvertimeBasketAdjustments(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => OvertimeBasketAdjustment.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  } catch (_) {}

  return [];
}

  List<CompensativeBasketMovement> _loadCompensativeBasketMovements(
  String? raw,
) {
  if (raw == null || raw.trim().isEmpty) {
    return [];
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CompensativeBasketMovement.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
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

  Future<void> saveShifts() async {
    shifts.sort((a, b) => b.start.compareTo(a.start));
    final prefs = await SharedPreferences.getInstance();
    await _saveShiftsToPrefs(prefs, shifts);
  }

  Future<void> _saveBasketPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(basketPayments.map((e) => e.toJson()).toList());
    await prefs.setString(basketPaymentsStorageKey, raw);
  }

  Future<void> _saveRfiBasketPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(rfiBasketPayments.map((e) => e.toJson()).toList());
    await prefs.setString(rfiBasketPaymentsStorageKey, raw);
  }

  Future<void> _saveOvertimeBasketAdjustments() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = jsonEncode(
    overtimeBasketAdjustments.map((e) => e.toJson()).toList(),
  );
  await prefs.setString(overtimeBasketAdjustmentsStorageKey, raw);
}

  Future<void> _saveCompensativeBasketMovements() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = jsonEncode(
    manualCompensativeBasketMovements.map((e) => e.toJson()).toList(),
  );
  await prefs.setString(compensativeBasketMovementsStorageKey, raw);
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
      department: widget.activeDepartment,
      basketPayments: basketPayments,
      overtimeBasketAdjustments: overtimeBasketAdjustments,
      rfiBasketPayments: rfiBasketPayments,
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

  Future<void> addRfiBasketPayment(
    DateTime sourceMonth,
    DateTime paidInMonth,
    String note,
  ) async {
    final normalizedSourceMonth = DateTime(sourceMonth.year, sourceMonth.month);
    final normalizedPaidInMonth = DateTime(paidInMonth.year, paidInMonth.month);

    final alreadyExists = rfiBasketPayments.any(
      (item) =>
          item.sourceMonth.year == normalizedSourceMonth.year &&
          item.sourceMonth.month == normalizedSourceMonth.month,
    );

    if (alreadyExists) {
      throw Exception('Questo mese RFI risulta già scaricato');
    }

    final payment = RfiBasketPayment(
      sourceMonth: normalizedSourceMonth,
      paidInMonth: normalizedPaidInMonth,
      note: note,
    );

    setState(() {
      rfiBasketPayments.add(payment);
      rfiBasketPayments.sort((a, b) => a.sourceMonth.compareTo(b.sourceMonth));
    });

    await _saveRfiBasketPayments();
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

String _buildSearchText(Shift shift) {
  return [
    shift.description,
    shift.effectiveOrderPublicLabel,
    shift.absence,
    shift.note,
    shift.manualExtraLabel,
  ].join(' ').toLowerCase();
}

DailyShiftComputation _buildSingleShiftComputation(Shift shift) {
  final data = _buildShiftComputationUseCase.execute(
    shift: shift,
    profile: payProfile,
    department: widget.activeDepartment,
  );

  return DailyShiftComputation(
    overtimeHours: data.overtimeHours,
    totalAmount: data.totalAmount,
    extraAmount: data.extraAmount,
    breakdown: data.breakdown,
  );
}

DailyShiftResult _buildDailyShiftResult(List<Shift> dayShifts) {
  return _buildDailyShiftResultUseCase.execute(
    shifts: dayShifts,
    profile: payProfile,
    department: widget.activeDepartment,
  );
}

DailyShiftResult _buildDailyShiftResultForDate(DateTime date) {
  final dayShifts = filteredShifts
      .where((shift) => _isSameDay(shift.serviceDate, date))
      .toList();

  return _buildDailyShiftResult(dayShifts);
}

double _totalPayableFromDailyResult(DailyShiftResult result) {
  return result.computations.values.fold<double>(
    0.0,
    (sum, computation) => sum + computation.totalAmount,
  );
}

double _salaryOnlyAmount(Shift shift) {
  final computation = _buildSingleShiftComputation(shift);
  return computation.extraAmount;
}

List<Shift> get filteredShifts {
  return shifts.where((shift) {
    return shift.serviceDate.year == selectedMonth.year &&
        shift.serviceDate.month == selectedMonth.month;
  }).toList();
}

List<Shift> get yearlySearchResults {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) return [];

  final now = DateTime.now();

  final annualBase = shifts.where((shift) {
    return shift.serviceDate.year == now.year;
  }).toList();

  final results = annualBase.where((shift) {
    return _buildSearchText(shift).contains(query);
  }).toList()
    ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

  return results;
}

MonthlySummary get monthlySummary {
  return _buildMonthlySummaryUseCase.execute(
    shifts: shifts,
    selectedMonth: selectedMonth,
    profile: payProfile,
    department: widget.activeDepartment,
  );
}

List<Shift> get selectedDayShifts {
  return filteredShifts
      .where((shift) => _isSameDay(shift.serviceDate, selectedDay))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

double get _netEstimateMultiplier {
  final raw = payProfile.straordinarioNetMultiplier;

  if (raw.isNaN || !raw.isFinite || raw <= 0 || raw > 1) {
    return 0.67;
  }

  return raw;
}

double get selectedDayGross {
  return _totalPayableFromDailyResult(
    _buildDailyShiftResultForDate(selectedDay),
  );
}

double get selectedDayNet => selectedDayGross * _netEstimateMultiplier;

double get totalMonthGross => monthlySummary.totalAmount;

double get totalMonthNet => totalMonthGross * _netEstimateMultiplier;

double get weekTotalGross => monthlySummary.weekTotal;

double get averagePerWorkedDayGross =>
    monthlySummary.averagePerDay;

double get monthlyOvertimeHours => monthlySummary.totalOvertimeHours;

int get workedDaysCount => monthlySummary.workedDays;
double get averagePerWorkedDay => monthlySummary.averagePerDay;
double get projectedExtraFuture => monthlySummary.projectedExtraFuture;
double get monthlyRfiBasketAmount => monthlySummary.rfiBasketAmount;

List<CompensativeBasketMovement>
    get compensativeBasketMovements {
  final automaticMovements =
      _buildCompensativeBasketMovementsUseCase.execute(
    shifts: shifts,
  );

  return [
    ...automaticMovements,
    ...manualCompensativeBasketMovements,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

double get compensativeBasketEarnedHours {
  final summary =
      _buildCompensativeBasketSummaryFromMovementsUseCase.execute(
    movements: compensativeBasketMovements,
  );

  return summary.earnedHours;
}

double get compensativeBasketRecoveredHours {
  final summary =
      _buildCompensativeBasketSummaryFromMovementsUseCase.execute(
    movements: compensativeBasketMovements,
  );

  return summary.recoveredHours;
}

double get compensativeBasketResidualHours {
  final summary =
      _buildCompensativeBasketSummaryFromMovementsUseCase.execute(
    movements: compensativeBasketMovements,
  );

  return summary.residualHours;
}

int get monthlyTicketPastoCount {
  return filteredShifts.where((shift) => shift.ticketPasto).length;
}

int get monthlyGenereDiConfortoCount {
  return filteredShifts.where((shift) => shift.genereDiConforto).length;
}

double get monthlyTicketPastoTotal {
  return filteredShifts.fold<double>(
    0.0,
    (sum, shift) =>
        sum + (shift.ticketPasto ? payProfile.ticketPastoRate : 0.0),
  );
}

double get monthlyGenereDiConfortoTotal {
  return filteredShifts.fold<double>(
    0.0,
    (sum, shift) =>
        sum +
        (shift.genereDiConforto ? payProfile.genereDiConfortoRate : 0.0),
  );
}

double _dailyTotal(DateTime date) {
  return _totalPayableFromDailyResult(
    _buildDailyShiftResultForDate(date),
  );
}

bool _hasTicketInDate(DateTime date) {
  return filteredShifts.any(
    (shift) => _isSameDay(shift.serviceDate, date) && shift.ticketPasto,
  );
}

bool _hasConfortoInDate(DateTime date) {
  return filteredShifts.any(
    (shift) => _isSameDay(shift.serviceDate, date) && shift.genereDiConforto,
  );
}

bool _hasConfortoCdgInDate(DateTime date) {
  return filteredShifts.any(
    (shift) =>
        _isSameDay(shift.serviceDate, date) && shift.genereDiConfortoCdg,
  );
}

bool _hasWorkedShiftInDate(DateTime date) {
  return filteredShifts.any(
    (shift) => _isSameDay(shift.serviceDate, date) && !shift.hasAbsence,
  );
}

String? _absenceBadgeForDate(DateTime date) {
  final dayShifts = filteredShifts
      .where((shift) => _isSameDay(shift.serviceDate, date))
      .toList();

  if (dayShifts.isEmpty) return null;

  bool hasCongedoOrdinario = false;
  bool hasMalattia = false;
  bool hasRiposo = false;
  bool hasFestivo = false;
  bool hasGenericAbsence = false;

  for (final shift in dayShifts) {
    final rawAbsence = shift.absence.trim();
    final absence = rawAbsence.toLowerCase();

    if (rawAbsence.isEmpty || absence == 'nessuna') continue;

    if (absence == 'ferie' ||
        absence == 'congedo ordinario' ||
        absence == 'c.o.' ||
        absence == 'c.o') {
      hasCongedoOrdinario = true;
    } else if (absence == 'malattia' ||
        absence == 'c.s.' ||
        absence == 'c.s' ||
        absence == 'mal') {
      hasMalattia = true;
    } else if (absence == 'riposo' || absence == 'rip') {
      hasRiposo = true;
    } else if (absence == 'festivo' ||
        absence == 'festa' ||
        absence == 'fest') {
      hasFestivo = true;
    } else {
      hasGenericAbsence = true;
    }
  }

  if (hasCongedoOrdinario) return 'C.O.';
  if (hasMalattia) return 'C.S.';
  if (hasRiposo) return 'RIP';
  if (hasFestivo) return 'FEST';
  if (hasGenericAbsence) return 'ASS.';

  return null;
}

String? _extractSpmnLabelFromShift(Shift shift) {
  if (shift.hasAbsence) return null;

  final code = shift.spmnPresetCode.trim().toLowerCase();

  switch (code) {
    case 'sera':
      return 'SERA';

    case 'pomeriggio':
      return 'POM';

    case 'mattina':
      return 'MAT';

    case 'notte':
      return 'NOTTE';

    case 'riposo':
      return 'RIP';

    case 'aggiornamento':
      return 'AGG';

    case 'smontante':
      return 'SM';

    default:
      return null;
  }
}

String? _nextSpmnLabel(String current) {
  switch (current) {
    case 'SERA':
      return 'POM';
    case 'POM':
      return 'MAT';
    case 'MAT':
      return 'NOTTE';
    case 'NOTTE':
      return 'RIP';
    case 'RIP':
      return 'SERA';
    case 'AGG':
      return 'SERA';
    default:
      return null;
  }
}

String _resolvePredictedSpmnLabelForDate({
  required String baseNextLabel,
  required int daysAfterAnchor,
  required DateTime targetDate,
}) {
  String current = baseNextLabel;

  for (int i = 0; i < daysAfterAnchor; i++) {
    current = _nextSpmnLabel(current) ?? current;
  }

  if (current == 'RIP' && targetDate.weekday == DateTime.tuesday) {
    return 'AGG';
  }

  return current;
}

Map<String, String> _buildPredictedSpmnCalendarMap() {
  if (widget.activeDepartment != Department.polfer &&
    widget.activeDepartment != Department.questura &&
    widget.activeDepartment != Department.polstrada) {
  return {};
}
  if (shifts.isEmpty) return {};

  final spmnSource = shifts
      .where(
        (shift) =>
            !shift.hasAbsence && _extractSpmnLabelFromShift(shift) != null,
      )
      .toList()
    ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));

  if (spmnSource.isEmpty) return {};

  final anchorShift = spmnSource.last;
  final anchorLabel = _extractSpmnLabelFromShift(anchorShift);
  if (anchorLabel == null) return {};

  final nextLabel = _nextSpmnLabel(anchorLabel);
  if (nextLabel == null) return {};

  final predictionMap = <String, String>{};
  final anchorDate = _normalizeDate(anchorShift.serviceDate);

  for (int offset = 1; offset <= 70; offset++) {
    final targetDate = anchorDate.add(Duration(days: offset));
    final key = _calendarKey(targetDate);

    final dayHasAnyRecord = shifts.any(
      (shift) => _isSameDay(shift.serviceDate, targetDate),
    );

    if (dayHasAnyRecord) continue;

    predictionMap[key] = _resolvePredictedSpmnLabelForDate(
      baseNextLabel: nextLabel,
      daysAfterAnchor: offset - 1,
      targetDate: targetDate,
    );
  }

  return predictionMap;
}

String _calendarKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String? _nextSpmnPresetCode(String currentCode, DateTime nextServiceDate) {
  switch (currentCode) {
    case 'sera':
      return 'pomeriggio';
    case 'pomeriggio':
      return 'mattina';
    case 'mattina':
      return 'notte';
    case 'notte':
      return 'riposo';
    case 'riposo':
      return nextServiceDate.weekday == DateTime.tuesday
          ? 'aggiornamento'
          : 'sera';
    case 'aggiornamento':
      return 'sera';
    default:
      return null;
  }
}

String? _suggestedSpmnPresetCodeForDate(DateTime targetDate) {
  if (widget.activeDepartment != Department.polfer &&
    widget.activeDepartment != Department.questura &&
    widget.activeDepartment != Department.polstrada) {
  return null;
}

  final normalizedTarget = _normalizeDate(targetDate);

  final previousSpmnShifts = shifts.where((shift) {
    final code = shift.spmnPresetCode.trim().toLowerCase();
    return code.isNotEmpty && shift.serviceDate.isBefore(normalizedTarget);
  }).toList()
    ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));

  if (previousSpmnShifts.isEmpty) return null;

  final anchor = previousSpmnShifts.last;
  String? currentCode = anchor.spmnPresetCode.trim().toLowerCase();

  if (currentCode.isEmpty) return null;

  DateTime cursor = _normalizeDate(anchor.serviceDate);

  while (cursor.isBefore(normalizedTarget)) {
    final nextDay = cursor.add(const Duration(days: 1));
    currentCode = _nextSpmnPresetCode(currentCode!, nextDay);
    if (currentCode == null || currentCode.isEmpty) return null;
    cursor = nextDay;
  }

  return currentCode;
}

List<MonthCalendarDayData> get calendarDays {
  final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final startWeekday = firstDayOfMonth.weekday;
  final gridStart = firstDayOfMonth.subtract(Duration(days: startWeekday - 1));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final predictedSpmnMap = _buildPredictedSpmnCalendarMap();

  return List.generate(42, (index) {
    final date = gridStart.add(Duration(days: index));
    final isInCurrentMonth = date.month == selectedMonth.month;
    final dayKey = _calendarKey(date);

    return MonthCalendarDayData(
      date: date,
      isInCurrentMonth: isInCurrentMonth,
      amount: isInCurrentMonth ? _dailyTotal(date) : 0.0,
      isSelected: _isSameDay(date, selectedDay),
      isToday: _isSameDay(date, today),
      absenceBadge: isInCurrentMonth ? _absenceBadgeForDate(date) : null,
      hasTicket: _hasTicketInDate(date),
      hasConforto: _hasConfortoInDate(date),
      hasConfortoCdg: _hasConfortoCdgInDate(date),
      predictedSpmnLabel: isInCurrentMonth ? predictedSpmnMap[dayKey] : null,
      hasWorkedShift: isInCurrentMonth ? _hasWorkedShiftInDate(date) : false,
    );
  });
}

PayslipProjectionResult get payslipProjection {
  return _projectionService.projectPayslip(
    payslipMonth: selectedPayslipMonth,
    allShifts: shifts,
    payProfile: payProfile,
    department: widget.activeDepartment,
    basketPayments: basketPayments,
    overtimeBasketAdjustments: overtimeBasketAdjustments,
    rfiBasketPayments: rfiBasketPayments,
  );
}

PrecisionStatus get payslipPrecisionStatus {
  return _projectionService.calculatePrecision(allShifts: shifts);
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
    (sum, shift) => sum + _salaryOnlyAmount(shift),
  );

  final effectiveTaxRate =
      payProfile.effectiveTaxRate.isFinite && payProfile.effectiveTaxRate >= 0
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

  Future<void> openAddShift() async {
    final suggestedPresetCode = _suggestedSpmnPresetCodeForDate(selectedDay);

    final newShift = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddShiftPage(
          onAdd: (shift) => Navigator.of(context).pop(shift),
          rates: payProfile,
          initialDate: selectedDay,
          activeDepartment: widget.activeDepartment,
          initialSuggestedSpmnPresetCode: suggestedPresetCode,
        ),
      ),
    );

    if (newShift != null && newShift is Shift) {
      await addShift(newShift);
    } else if (newShift != null && newShift is List<Shift>) {
      setState(() {
        shifts.addAll(newShift);
        shifts.sort((a, b) => b.start.compareTo(a.start));
        if (newShift.isNotEmpty) {
          final first = newShift.first;
          selectedMonth = DateTime(first.serviceDate.year, first.serviceDate.month);
          selectedDay = _normalizeDate(first.serviceDate);
        }
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
          activeDepartment: widget.activeDepartment,
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
        builder: (context) => CalibratePayslipsPage(
          activeDepartment: widget.activeDepartment,
        ),
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
                        final isSelected = month.year == selectedMonth.year &&
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
                              ? DutyPayPalette.primary.withValues(alpha: 0.10)
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
    String _formatShiftTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatShiftDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);

    if (duration.inMinutes <= 0) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  String _buildShiftTimeRangeLabel(Shift shift) {
    if (shift.absence != 'Nessuna') {
      final serviceDay = shift.serviceDate.day.toString().padLeft(2, '0');
      final serviceMonth = shift.serviceDate.month.toString().padLeft(2, '0');
      final serviceYear = shift.serviceDate.year.toString();
      return '$serviceDay/$serviceMonth/$serviceYear';
    }

    final serviceDay = shift.serviceDate.day.toString().padLeft(2, '0');
    final serviceMonth = shift.serviceDate.month.toString().padLeft(2, '0');
    final serviceYear = shift.serviceDate.year.toString();

    final startText = _formatShiftTime(shift.start);
    final endText = _formatShiftTime(shift.end);
    final durationText = _formatShiftDuration(shift.start, shift.end);

    if (durationText.isEmpty) {
      return '$serviceDay/$serviceMonth/$serviceYear • $startText → $endText';
    }

    return '$serviceDay/$serviceMonth/$serviceYear • $startText → $endText ($durationText)';
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

  String _monthNoteKey(DateTime month) {
    final y = month.year.toString();
    final m = month.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Future<void> _openMonthNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(monthNotesStorageKey);

    Map<String, dynamic> notesMap = {};
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          notesMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final key = _monthNoteKey(selectedMonth);
    String draftText = (notesMap[key] ?? '').toString();

    final saved = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Note ${_formatMonthYear(selectedMonth)}'),
              content: StatefulBuilder(
                builder: (context, setModalState) {
                  return TextFormField(
                    initialValue: draftText,
                    minLines: 6,
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi qui note utili per questo mese...',
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        draftText = value;
                      });
                    },
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Chiudi'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salva'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (saved == true) {
      final text = draftText.trim();

      if (text.isEmpty) {
        notesMap.remove(key);
      } else {
        notesMap[key] = text;
      }

      await prefs.setString(monthNotesStorageKey, jsonEncode(notesMap));

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota mensile salvata')),
      );
    }
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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

  Future<void> _openCompensativeBasketAdjustmentDialog() async {
  final hoursController = TextEditingController();
  final noteController = TextEditingController();

  bool isPositive = true;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text(
              'Correzione basket compensativo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hoursController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Ore',
                    hintText: 'Es. 2.0',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<bool>(
                  value: isPositive,
                  decoration: const InputDecoration(
                    labelText: 'Tipo correzione',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Aggiungi ore'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Sottrai ore'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setModalState(() {
                      isPositive = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo della correzione',
                    hintText: 'Nota obbligatoria',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () async {
                  final parsedHours =
                      double.tryParse(
                        hoursController.text.replaceAll(',', '.'),
                      ) ??
                      0.0;

                  final note = noteController.text.trim();

                  if (parsedHours <= 0 || note.isEmpty) {
                    return;
                  }

                  await _addCompensativeBasketAdjustment(
                    hours: parsedHours,
                    isPositive: isPositive,
                    note: note,
                    movementDate: DateTime.now(),
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openOvertimeBasketAdjustmentDialog() async {
  final hoursController = TextEditingController();
  final noteController = TextEditingController();

  bool isPositive = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text(
              'Correzione basket straordinari',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hoursController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Ore',
                    hintText: 'Es. 34.0',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<bool>(
                  value: isPositive,
                  decoration: const InputDecoration(
                    labelText: 'Tipo correzione',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Aggiungi ore'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Sottrai ore'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() {
                      isPositive = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo della correzione',
                    hintText: 'Nota obbligatoria',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () async {
                  final parsedHours = double.tryParse(
                        hoursController.text.replaceAll(',', '.'),
                      ) ??
                      0.0;

                  final note = noteController.text.trim();

                  if (parsedHours <= 0 || note.isEmpty) return;

                  await _addOvertimeBasketAdjustment(
                    hours: parsedHours,
                    isPositive: isPositive,
                    note: note,
                    movementDate: DateTime.now(),
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget _buildShiftCard(
    Shift shift, {
    DailyShiftComputation? computation,
  }) {
    final shiftIndex = shifts.indexOf(shift);
    final orderPublicAmount = shift.getOrderPublicAmount(payProfile);
    final effectiveComputation =
        computation ?? _buildSingleShiftComputation(shift);

    final totalAmount = effectiveComputation.totalAmount;
    final extraAmount = effectiveComputation.extraAmount;
    final breakdown = effectiveComputation.breakdown;

    final hasAbsence = shift.hasAbsence;
    final isExternal = shift.externalService;
    final hasOrderPublic =
        shift.effectiveOrderPublicLabel.trim().toLowerCase() != 'nessuno';
    Future<void> confirmDelete() async {
      final shouldDelete = await showDialog<bool>(
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

      if (shouldDelete && shiftIndex >= 0) {
        await removeShift(shiftIndex);
      }
    }

    return GestureDetector(
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
              color: Colors.black.withValues(alpha: 0.16),
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
                const SizedBox(width: 10),
                IconButton(
                  onPressed: confirmDelete,
                  tooltip: 'Elimina turno',
                  style: IconButton.styleFrom(
                    backgroundColor: DutyPayPalette.danger.withValues(alpha: 0.10),
                    side: BorderSide(
                      color: DutyPayPalette.danger.withValues(alpha: 0.28),
                    ),
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: DutyPayPalette.danger,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
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
              _buildShiftTimeRangeLabel(shift),
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
                    value: effectiveComputation.overtimeHours > 0
                        ? '${effectiveComputation.overtimeHours.toStringAsFixed(1)}h'
                        : 'Nessuno',
                    icon: Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statTile(
                    label: 'Valore servizio',
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
                      'Dettaglio servizio',
                      style: TextStyle(
                        fontSize: 13,
                        color: DutyPayPalette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Valori stimati del servizio',
                      style: TextStyle(
                        fontSize: 12.2,
                        color: DutyPayPalette.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...breakdown.map((item) {
                      final label = item['label'] as String;
                      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                      return _buildBreakdownRow(label, amount);
                    }),
                  ],
                ),
              ),
            ],
            if (orderPublicAmount > 0 && extraAmount >= 0)
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Future<void> _addCompensativeBasketAdjustment({
  required double hours,
  required bool isPositive,
  required String note,
  required DateTime movementDate,
}) async {
  final updated =
      _manageCompensativeBasketAdjustmentsUseCase.addAdjustment(
    movements: manualCompensativeBasketMovements,
    hours: hours,
    isPositive: isPositive,
    note: note,
    movementDate: movementDate,
  );

  if (updated.length == manualCompensativeBasketMovements.length) {
    return;
  }

  setState(() {
    manualCompensativeBasketMovements
      ..clear()
      ..addAll(updated);
  });

  await _saveCompensativeBasketMovements();
}

Future<void> _addOvertimeBasketAdjustment({
  required double hours,
  required bool isPositive,
  required String note,
  required DateTime movementDate,
}) async {
  final trimmedNote = note.trim();
  if (hours <= 0 || trimmedNote.isEmpty) return;

  final signedHours = isPositive ? hours : -hours;

  final adjustment = OvertimeBasketAdjustment(
    id: 'overtime_adjustment_${movementDate.toIso8601String()}_${overtimeBasketAdjustments.length}',
    month: DateTime(movementDate.year, movementDate.month),
    hours: signedHours,
    note: trimmedNote,
    createdAt: movementDate,
  );

  setState(() {
    overtimeBasketAdjustments.add(adjustment);
    overtimeBasketAdjustments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  });

  await _saveOvertimeBasketAdjustments();
}

Future<void> _deleteCompensativeBasketAdjustment(String movementId) async {
  final updated =
      _manageCompensativeBasketAdjustmentsUseCase.deleteAdjustment(
    movements: manualCompensativeBasketMovements,
    movementId: movementId,
  );

  setState(() {
    manualCompensativeBasketMovements
      ..clear()
      ..addAll(updated);
  });

  await _saveCompensativeBasketMovements();
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
          color: Colors.black.withValues(alpha: 0.24),
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
        Text(
          'Reparto attivo: ${_activeDepartmentLabel()}',
          style: const TextStyle(
            fontSize: 14.5,
            color: DutyPayPalette.info,
            fontWeight: FontWeight.w700,
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
                value: _formatCurrency(selectedDayGross),
                valueColor: DutyPayPalette.primary,
                icon: Icons.today_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statTile(
                label: 'Settimana',
                value: _formatCurrency(weekTotalGross),
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
                value: _formatCurrency(averagePerWorkedDayGross),
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
    color: DutyPayPalette.primary.withValues(alpha: 0.09),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: DutyPayPalette.primary.withValues(alpha: 0.22),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Netto stimato',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: DutyPayPalette.primary,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _statTile(
              label: 'Giornaliero',
              value: _formatCurrency(selectedDayNet),
              valueColor: DutyPayPalette.primary,
              icon: Icons.today_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statTile(
              label: 'Mensile',
              value: _formatCurrency(totalMonthNet),
              valueColor: DutyPayPalette.primary,
              icon: Icons.account_balance_wallet_rounded,
            ),
          ),
        ],
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
                    await DataBackupService.exportData(
  departmentId: _storageScope,
  shifts: shifts,
  profile: payProfile,
  basketPayments: basketPayments,
  rfiBasketPayments: rfiBasketPayments,
  overtimeBasketAdjustments: overtimeBasketAdjustments,
  compensativeBasketMovements: manualCompensativeBasketMovements,
);

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
                    await DataBackupService.importData(
  shiftsStorageKey: shiftsStorageKey,
  payProfileStorageKey: payProfileStorageKey,
  basketPaymentsStorageKey: basketPaymentsStorageKey,
  rfiBasketPaymentsStorageKey: rfiBasketPaymentsStorageKey,
  overtimeBasketAdjustmentsStorageKey:
      overtimeBasketAdjustmentsStorageKey,
  compensativeBasketMovementsStorageKey:
      compensativeBasketMovementsStorageKey,
);
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
        const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: _confirmAndClearAllData,
    icon: const Icon(Icons.delete_outline_rounded),
    label: const Text('Cancella tutti i dati'),
  ),
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
    final dayResult = _buildDailyShiftResultForDate(selectedDay);
    final dayComputations = dayResult.computations;
    final selectedDayTotal = _totalPayableFromDailyResult(dayResult);
    final selectedDayRfiBasket = dayResult.rfiBasketAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: DutyPayPalette.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DutyPayPalette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
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
          Column(
            children: [
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
              if (widget.activeDepartment == Department.polfer) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        label: 'Basket RFI giorno',
                        value: _formatCurrency(selectedDayRfiBasket),
                        valueColor: DutyPayPalette.info,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
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
              child: Text(
                searchQuery.trim().isEmpty
                    ? 'Nessun turno per questo giorno.'
                    : 'Nessun turno trovato per questa ricerca nel giorno selezionato.',
                style: const TextStyle(
                  color: DutyPayPalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...selectedDayShifts.map(
              (shift) => _buildShiftCard(
                shift,
                computation: dayComputations[shift],
              ),
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
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cerca servizio, OP, assenza o note',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
              if (searchQuery.trim().isNotEmpty) ...[
  const SizedBox(height: 14),
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DutyPayPalette.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DutyPayPalette.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risultati ricerca ${DateTime.now().year}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (yearlySearchResults.isEmpty)
          const Text(
            'Nessun risultato trovato nell’anno in corso.',
            style: TextStyle(
              color: DutyPayPalette.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ...yearlySearchResults.map(
            (shift) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedMonth = DateTime(
                      shift.serviceDate.year,
                      shift.serviceDate.month,
                    );
                    selectedDay = _normalizeDate(shift.serviceDate);
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DutyPayPalette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DutyPayPalette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shift.description.isEmpty
                                  ? 'Turno senza descrizione'
                                  : shift.description,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatShiftDate(shift),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: DutyPayPalette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: DutyPayPalette.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  ),
],
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
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: MonthCalendarCard(
                  month: selectedMonth,
                  days: calendarDays,
                  ticketPastoCount: monthlyTicketPastoCount,
                  genereDiConfortoCount: monthlyGenereDiConfortoCount,
                  ticketPastoTotal: monthlyTicketPastoTotal,
                  genereDiConfortoTotal: monthlyGenereDiConfortoTotal,
                  totalOvertimeHours: monthlyOvertimeHours,
                  onOpenMonthNotes: _openMonthNotes,
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
  onAddOvertimeBasketAdjustment: _openOvertimeBasketAdjustmentDialog,
  onAddRfiBasketPayment:
      widget.activeDepartment == Department.polfer
          ? addRfiBasketPayment
          : null,
  precision: payslipPrecisionStatus,
  compensativeBasketEarnedHours: compensativeBasketEarnedHours,
  compensativeBasketRecoveredHours: compensativeBasketRecoveredHours,
  compensativeBasketResidualHours: compensativeBasketResidualHours,
  compensativeBasketMovements: compensativeBasketMovements,
  onAddCompensativeBasketAdjustment:
      _openCompensativeBasketAdjustmentDialog,
  onDeleteCompensativeBasketAdjustment:
      _deleteCompensativeBasketAdjustment,
);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildTurnsPage(),
      _buildPayslipPage(),
      const BreakPage(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('DutyPay'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'Cambia reparto',
              onPressed: () async {
                final selected = await Navigator.push<Department>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepartmentSelectionPage(
                      initialDepartment: widget.activeDepartment,
                      onSelected: (department) async {
                        Navigator.of(context).pop(department);
                      },
                    ),
                  ),
                );

                if (selected != null) {
                  await widget.onDepartmentChanged(selected);
                }
              },
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ),
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
              NavigationDestination(
                icon: Icon(Icons.coffee_rounded),
                label: 'Break',
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