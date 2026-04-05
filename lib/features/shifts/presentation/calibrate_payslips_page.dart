import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/department.dart';
import 'models/shift.dart' as shift_model;
import 'models/user_pay_profile.dart';
import 'quick_add_shift_page.dart';
import 'services/duty_pay_engine.dart';
import 'services/payslip_parser_service.dart';
import 'services/shift_rate_calculator.dart';
import 'services/shift_value_calculator.dart';

class CalibratePayslipsPage extends StatefulWidget {
  const CalibratePayslipsPage({
    super.key,
    required this.activeDepartment,
  });

  final Department activeDepartment;

  @override
  State<CalibratePayslipsPage> createState() => _CalibratePayslipsPageState();
}

class _CalibratePayslipsPageState extends State<CalibratePayslipsPage> {
  static const String _legacyPdfPathsKey = 'dutypay_pdf_paths_v1';
  static const String _legacyShiftsKey = 'dutypay_shifts';
  static const String _legacyRatesKey = 'dutypay_saved_rates_v1';
  static const String _legacyPayProfileKey = 'dutypay_pay_profile';

  String get _storageScope => widget.activeDepartment.id;

  String get _prefsPdfPathsKey => 'dutypay_pdf_paths_v1_$_storageScope';
  String get _prefsShiftsKey => 'dutypay_shifts_$_storageScope';
  String get _prefsRatesKey => 'dutypay_saved_rates_v1_$_storageScope';
  String get _prefsPayProfileKey => 'dutypay_pay_profile_$_storageScope';

  bool get _isRepartoMobileScope =>
      widget.activeDepartment == Department.repartoMobile;

  final PayslipParserService _parserService = const PayslipParserService();
  final DutyPayEngine _dutyPayEngine = const DutyPayEngine();
  final ShiftRateCalculator _shiftRateCalculator = const ShiftRateCalculator();

  final TextEditingController _monthlyOvertimeLimitController =
      TextEditingController();

  final List<String?> selectedPdfPaths = [null, null, null];
  final List<String?> selectedPdfNames = [null, null, null];
  final List<int?> selectedPdfBytes = [null, null, null];

  final List<PayslipParsedData?> parsedPayslips = [null, null, null];
  final List<String?> extractionErrors = [null, null, null];
  final List<bool> isExtracting = [false, false, false];

  final List<shift_model.Shift> shifts = [];

  UserPayProfile? calibratedProfile;
  DutyPayEngineSnapshot? engineSnapshot;
  ShiftDerivedRates? derivedRates;

  bool isPicking = false;
  bool isRestoring = true;
  double extraIncome = 0;

  @override
  void initState() {
    super.initState();
    _restorePersistedData();
  }

  @override
  void dispose() {
    _monthlyOvertimeLimitController.dispose();
    super.dispose();
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

  Future<void> _restorePersistedData() async {
    try {
      await _loadSavedShifts();
      await _loadSavedProfile();
      await _loadSavedRates();
      await _loadSavedPdfSelectionsMetadataOnly();

      if (!mounted) return;

      setState(() {
        for (int i = 0; i < extractionErrors.length; i++) {
          extractionErrors[i] = null;
        }

        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: derivedRates,
        );

        isRestoring = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isRestoring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il ripristino dati: $e'),
        ),
      );
    }
  }

  Future<int?> _readPdfBytesCount(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.length;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSavedPdfSelectionsMetadataOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPaths = await _readScopedStringList(
          prefs: prefs,
          scopedKey: _prefsPdfPathsKey,
          legacyKey: _legacyPdfPathsKey,
        ) ??
        [];

    for (int i = 0; i < 3; i++) {
      final path = i < savedPaths.length ? savedPaths[i] : null;

      if (path == null || path.trim().isEmpty) {
        selectedPdfPaths[i] = null;
        selectedPdfNames[i] = null;
        selectedPdfBytes[i] = null;
        continue;
      }

      try {
        final file = File(path);
        if (!await file.exists()) {
          selectedPdfPaths[i] = null;
          selectedPdfNames[i] = null;
          selectedPdfBytes[i] = null;
          continue;
        }

        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : path.split('/').last;
        final bytesCount = await _readPdfBytesCount(path);

        selectedPdfPaths[i] = path;
        selectedPdfNames[i] = fileName;
        selectedPdfBytes[i] = bytesCount;
      } catch (_) {
        selectedPdfPaths[i] = null;
        selectedPdfNames[i] = null;
        selectedPdfBytes[i] = null;
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _savePdfSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final values = selectedPdfPaths.map((e) => e ?? '').toList();
    await prefs.setStringList(_prefsPdfPathsKey, values);
  }

  Future<void> _loadSavedShifts() async {
    final prefs = await SharedPreferences.getInstance();
    shifts.clear();

    try {
      final rawJson = await _readScopedString(
        prefs: prefs,
        scopedKey: _prefsShiftsKey,
        legacyKey: _legacyShiftsKey,
      );

      if (rawJson != null && rawJson.trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);

        if (decoded is List) {
          for (final item in decoded) {
            try {
              if (item is Map<String, dynamic>) {
                shifts.add(shift_model.Shift.fromJson(item));
              } else if (item is Map) {
                shifts.add(shift_model.Shift.fromJson(Map<String, dynamic>.from(item)));
              }
            } catch (_) {}
          }

          shifts.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
          return;
        }
      }
    } catch (_) {
      // fallback legacy list sotto
    }

    try {
      final legacyList = await _readScopedStringList(
        prefs: prefs,
        scopedKey: _prefsShiftsKey,
        legacyKey: _legacyShiftsKey,
      );

      if (legacyList == null || legacyList.isEmpty) return;

      for (final item in legacyList) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map<String, dynamic>) {
            shifts.add(shift_model.Shift.fromJson(decoded));
          } else if (decoded is Map) {
            shifts.add(shift_model.Shift.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } catch (_) {}
      }

      shifts.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      await _saveShifts();
    } catch (_) {}
  }

  Future<void> _saveShifts() async {
    final prefs = await SharedPreferences.getInstance();
    shifts.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    final rawJson = jsonEncode(
      shifts.map((e) => e.toJson()).toList(),
    );

    await prefs.setString(_prefsShiftsKey, rawJson);
  }

  Future<void> _loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await _readScopedString(
      prefs: prefs,
      scopedKey: _prefsPayProfileKey,
      legacyKey: _legacyPayProfileKey,
    );

    if (raw == null || raw.trim().isEmpty) {
      _monthlyOvertimeLimitController.text =
          UserPayProfile.defaultProfile().monthlyOvertimePayableHoursLimit
              .toStringAsFixed(0);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _monthlyOvertimeLimitController.text =
            UserPayProfile.defaultProfile().monthlyOvertimePayableHoursLimit
                .toStringAsFixed(0);
        return;
      }

      calibratedProfile = UserPayProfile.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      _monthlyOvertimeLimitController.text =
          calibratedProfile!.monthlyOvertimePayableHoursLimit.toStringAsFixed(0);

      engineSnapshot = _dutyPayEngine.buildSnapshot(calibratedProfile!);
    } catch (_) {
      calibratedProfile = null;
      engineSnapshot = null;
      _monthlyOvertimeLimitController.text =
          UserPayProfile.defaultProfile().monthlyOvertimePayableHoursLimit
              .toStringAsFixed(0);
    }
  }

  Future<void> _saveProfile(UserPayProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsPayProfileKey,
      jsonEncode(profile.toJson()),
    );
  }

  Future<void> _clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsPayProfileKey);
  }

  Future<void> _loadSavedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await _readScopedString(
      prefs: prefs,
      scopedKey: _prefsRatesKey,
      legacyKey: _legacyRatesKey,
    );

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      derivedRates = ShiftDerivedRates.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      derivedRates = null;
    }
  }

  Future<void> _saveRates(ShiftDerivedRates rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsRatesKey, jsonEncode(rates.toMap()));
  }

  Future<void> _clearRates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsRatesKey);
  }

  String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final isNegative = integer.startsWith('-');
    final digits = isNegative ? integer.substring(1) : integer;

    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }

    final formattedInt = buffer.toString().split('').reversed.join();
    return '${isNegative ? '-' : ''}$formattedInt,$decimal';
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(2)}%';
  }

  double _parseMonthlyOvertimeLimitInput() {
    final raw = _monthlyOvertimeLimitController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);

    if (parsed == null || parsed.isNaN || !parsed.isFinite || parsed < 0) {
      return 55.0;
    }

    return parsed;
  }

  Future<void> _saveMonthlyOvertimeLimit() async {
    final limit = _parseMonthlyOvertimeLimitInput();

    final baseProfile = calibratedProfile ?? UserPayProfile.defaultProfile();
    final updatedProfile = baseProfile.copyWith(
      monthlyOvertimePayableHoursLimit: limit,
    );

    await _saveProfile(updatedProfile);

    if (!mounted) return;

    setState(() {
      calibratedProfile = updatedProfile;
      engineSnapshot = _dutyPayEngine.buildSnapshot(updatedProfile);
      _monthlyOvertimeLimitController.text =
          limit == limit.roundToDouble()
              ? limit.toStringAsFixed(0)
              : limit.toStringAsFixed(1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Limite ore straordinario salvato: ${_monthlyOvertimeLimitController.text} h',
        ),
      ),
    );
  }

  Future<void> _extractAndParsePdf(
    int index,
    String filePath, {
    bool silent = false,
    bool clearDerivedBeforeParse = true,
  }) async {
    if (!mounted) return;

    setState(() {
      isExtracting[index] = true;
      parsedPayslips[index] = null;
      extractionErrors[index] = null;

      if (clearDerivedBeforeParse) {
        calibratedProfile = null;
        engineSnapshot = null;
        derivedRates = null;
      }
    });

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Il file selezionato non esiste più.');
      }

      final parsed = await _parserService.extractAndParsePdf(filePath);

      if (!mounted) return;

      setState(() {
        parsedPayslips[index] = parsed;
        extractionErrors[index] = null;
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cedolino ${index + 1} letto: ${parsed.monthLabel}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        parsedPayslips[index] = null;
        extractionErrors[index] = e.toString();
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore lettura PDF ${index + 1}: $e'),
          ),
        );
      }
    } finally {
      if (!mounted) return;

      setState(() {
        isExtracting[index] = false;
        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: derivedRates,
        );
      });
    }
  }

  Future<void> _rebuildProfileIfPossible() async {
    final validPayslips = parsedPayslips.whereType<PayslipParsedData>().toList();

    if (validPayslips.length < 2) {
      if (!mounted) return;

      setState(() {
        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: derivedRates,
        );
      });
      return;
    }

    try {
      final previousLimit =
          calibratedProfile?.monthlyOvertimePayableHoursLimit ??
              UserPayProfile.defaultProfile()
                  .monthlyOvertimePayableHoursLimit;

      final profile = _parserService
          .buildDynamicProfile(validPayslips)
          .copyWith(monthlyOvertimePayableHoursLimit: previousLimit);

      final snapshot = _dutyPayEngine.buildSnapshot(profile);
      final rates = _shiftRateCalculator.buildFromProfile(profile);

      if (!mounted) return;

      setState(() {
        calibratedProfile = profile;
        engineSnapshot = snapshot;
        derivedRates = rates;
        _monthlyOvertimeLimitController.text =
            profile.monthlyOvertimePayableHoursLimit == 0
                ? '0'
                : profile.monthlyOvertimePayableHoursLimit.roundToDouble() ==
                        profile.monthlyOvertimePayableHoursLimit
                    ? profile.monthlyOvertimePayableHoursLimit.toStringAsFixed(0)
                    : profile.monthlyOvertimePayableHoursLimit.toStringAsFixed(
                        1,
                      );
        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: rates,
        );
      });

      await _saveProfile(profile);
      await _saveRates(rates);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        calibratedProfile = null;
        engineSnapshot = null;
        derivedRates = null;
        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: null,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella ricostruzione del profilo: $e'),
        ),
      );
    }
  }

  Future<void> _setPdfAtIndex(
    int index,
    String rawPath,
    String fileName,
  ) async {
    final bytesCount = await _readPdfBytesCount(rawPath);

    if (!mounted) return;

    setState(() {
      selectedPdfPaths[index] = rawPath;
      selectedPdfNames[index] = fileName;
      selectedPdfBytes[index] = bytesCount;
      parsedPayslips[index] = null;
      extractionErrors[index] = null;
      calibratedProfile = null;
      engineSnapshot = null;
      derivedRates = null;
    });

    await _clearProfile();
    await _clearRates();
    await _savePdfSelections();
    await _extractAndParsePdf(index, rawPath);
    await _rebuildProfileIfPossible();
  }

  Future<void> pickPdf(int index) async {
    if (isPicking || isExtracting.any((e) => e)) return;

    setState(() {
      isPicking = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      final rawPath = pickedFile.path;

      if (rawPath == null || rawPath.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossibile leggere il percorso del file selezionato',
            ),
          ),
        );
        return;
      }

      final fileName = pickedFile.name;
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un file PDF')),
        );
        return;
      }

      await _setPdfAtIndex(index, rawPath, fileName);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore apertura file: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isPicking = false;
        });
      }
    }
  }

  Future<void> _openAddShiftPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickAddShiftPage(
          activeDepartment: widget.activeDepartment,
          rates: calibratedProfile ?? UserPayProfile.defaultProfile(),
          onAdd: (shift) => Navigator.of(context).pop(shift),
        ),
      ),
    );

    if (!mounted) return;

    if (result is shift_model.Shift){
      setState(() {
        shifts.add(result);
        shifts.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: derivedRates,
        );
      });
      await _saveShifts();
    } else if (result is List<shift_model.Shift>) {
      setState(() {
        shifts.addAll(result);
        shifts.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
        extraIncome = ShiftValueCalculator.calculateTotal(
          shifts,
          rates: derivedRates,
        );
      });
      await _saveShifts();
    }
  }

  Future<bool> _handleBackNavigation() async {
    if (!mounted) return true;
    Navigator.pop(context, true);
    return false;
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList({
    required String title,
    required List<PayslipEntry> entries,
    int maxItems = 6,
  }) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          '$title: nessuna voce rilevata',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    final visibleEntries = entries.take(maxItems).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          ...visibleEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${entry.displayTitle} — ${_formatMoney(entry.amount)}',
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ),
          if (entries.length > maxItems)
            Text(
              '+ ${entries.length - maxItems} altre voci',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildEngineComponentList(DutyPayEngineSnapshot snapshot) {
    if (snapshot.topOperationalComponents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Componenti operative medie: nessuna voce disponibile.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Componenti operative medie più rilevanti',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          ...snapshot.topOperationalComponents.map(
            (component) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${component.label} — ${_formatMoney(component.grossAmount)}',
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedCard(int index) {
    final parsed = parsedPayslips[index];
    if (parsed == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parsed.monthLabel,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 150,
                  child: _buildInfoChip('Grado rilevato', parsed.detectedGradeLabel),
                ),
                SizedBox(
                  width: 150,
                  child: _buildInfoChip(
                    'Base rilevata',
                    _formatMoney(parsed.detectedBaseSalary),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _buildInfoChip(
                    'Accessorie operative',
                    _formatMoney(parsed.detectedOperationalAccessoryTotal),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _buildInfoChip('Netto', _formatMoney(parsed.totaleNetto)),
                ),
                SizedBox(
                  width: 150,
                  child: _buildInfoChip(
                    'Trattenute reali',
                    _formatMoney(parsed.detectedRecurringDeductionsTotal),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _buildInfoChip(
                    'Aliquota effettiva',
                    _formatPercent(parsed.effectiveTaxRateForEngine),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildEntryList(
              title: 'Voci base e fisse utili al motore',
              entries: [
                ...parsed.baseSalaryEntries,
                ...parsed.fixedAllowanceEntries,
              ],
              maxItems: 8,
            ),
            const SizedBox(height: 10),
            _buildEntryList(
              title: 'Accessorie operative utili al motore',
              entries: parsed.operationalAccessoryEntries,
              maxItems: 8,
            ),
            const SizedBox(height: 10),
            _buildEntryList(
              title: 'Trattenute reali utili al motore',
              entries: parsed.realRecurringDeductionEntries,
              maxItems: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(int index) {
    final fileName = selectedPdfNames[index];
    final filePath = selectedPdfPaths[index];
    final fileBytes = selectedPdfBytes[index];
    final parsed = parsedPayslips[index];
    final error = extractionErrors[index];
    final extracting = isExtracting[index];
    final isLoaded = fileName != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLoaded ? const Color(0xFF22C55E) : Colors.white10,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            isLoaded ? Icons.check_circle_rounded : Icons.picture_as_pdf_rounded,
            size: 38,
            color: isLoaded ? const Color(0xFF22C55E) : Colors.white70,
          ),
          const SizedBox(height: 12),
          Text(
            isLoaded
                ? fileName
                : 'Nessun PDF selezionato per il cedolino ${index + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (filePath != null) ...[
            const SizedBox(height: 8),
            Text(
              filePath,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ],
          if (fileBytes != null) ...[
            const SizedBox(height: 6),
            Text(
              'Dimensione letta: $fileBytes bytes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (isPicking || extracting || isExtracting.any((e) => e))
                  ? null
                  : () => pickPdf(index),
              icon: Icon(
                extracting
                    ? Icons.hourglass_top_rounded
                    : Icons.upload_file_rounded,
              ),
              label: Text(
                extracting
                    ? 'Analisi cedolino in corso...'
                    : (isLoaded ? 'Sostituisci PDF' : 'Carica PDF'),
              ),
            ),
          ),
          if (extracting) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          if (error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.35)),
              ),
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFFB4B4),
                ),
              ),
            ),
          ],
          if (parsed != null) _buildParsedCard(index),
        ],
      ),
    );
  }

  Widget _buildOvertimeLimitCard() {
    final currentLimit =
        calibratedProfile?.monthlyOvertimePayableHoursLimit ??
            UserPayProfile.defaultProfile().monthlyOvertimePayableHoursLimit;

    if (_monthlyOvertimeLimitController.text.trim().isEmpty) {
      _monthlyOvertimeLimitController.text = currentLimit.toStringAsFixed(0);
    }

    return Container(
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
            'Impostazioni ufficio',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Imposta il limite massimo di ore straordinario liquidabili al mese. Cambia in base all’ufficio: ad esempio 55 al Reparto Mobile, 15 alla Squadra Mobile.',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _monthlyOvertimeLimitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Limite ore straordinario pagabili al mese',
              hintText: 'Es. 55',
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveMonthlyOvertimeLimit,
              icon: const Icon(Icons.save_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Salva impostazione'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = calibratedProfile;

    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171A21),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Profilo dinamico non ancora costruito. Carica almeno 2 cedolini letti correttamente.',
          style: TextStyle(fontSize: 15, color: Colors.white70),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22C55E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profilo dinamico calibrato',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: _buildInfoChip('Grado', profile.detectedGradeLabel),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Base media',
                  _formatMoney(profile.detectedBaseSalary),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Accessorie operative medie',
                  _formatMoney(profile.averageAccessoryPay),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Trattenute reali',
                  _formatMoney(profile.recurringDeductionsTotal),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Aliquota motore',
                  _formatPercent(profile.effectiveTaxRate),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Limite ore straordinario',
                  '${profile.monthlyOvertimePayableHoursLimit.toStringAsFixed(0)} h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cedolini usati: ${profile.sourceWindowLabel}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSnapshotCard() {
    final snapshot = engineSnapshot;

    if (snapshot == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171A21),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Snapshot motore non disponibile. Completa la calibrazione con almeno 2 cedolini.',
          style: TextStyle(fontSize: 15, color: Colors.white70),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22C55E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DutyPayEngine - primo snapshot',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Base lorda mensile',
                  _formatMoney(snapshot.baseGrossMonthly),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Accessorie medie',
                  _formatMoney(snapshot.averageOperationalAccessoriesGross),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Trattenute reali',
                  _formatMoney(snapshot.recurringRealDeductions),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Tassazione stimata',
                  _formatMoney(snapshot.estimatedTaxAmount),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Netto pre-trattenute',
                  _formatMoney(snapshot.estimatedNetBeforeRealDeductions),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Netto stimato finale',
                  _formatMoney(snapshot.estimatedNetAfterRealDeductions),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Netto medio osservato',
                  _formatMoney(snapshot.averageObservedNet),
                ),
              ),
              SizedBox(
                width: 170,
                child: _buildInfoChip(
                  'Scostamento medio',
                  _formatMoney(snapshot.averageDeltaFromObservedNet),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEngineComponentList(snapshot),
        ],
      ),
    );
  }

  Widget _buildDerivedRatesCard() {
    final rates = derivedRates;

    if (rates == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171A21),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Rate reali non ancora derivati. Servono almeno 2 cedolini calibrati.',
          style: TextStyle(fontSize: 15, color: Colors.white70),
        ),
      );
    }

    Widget rateBox(String label, double value, bool isReal) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReal ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatMoney(value),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _rateSupportLabel(label),
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isReal ? 'REALE' : 'STIMATO',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isReal
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22C55E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Rate reali derivati dai cedolini',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: _showRatesInfoSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF67B7FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Valori medi letti dai cedolini caricati. Tocca la i per capire come interpretarli.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                child: rateBox(
                  'Straordinario orario',
                  rates.straordinarioDiurnoOrario,
                  rates.isStraordinarioReal,
                ),
              ),
              SizedBox(
                width: 180,
                child: rateBox(
                  'Notturno',
                  rates.indennitaNotturnaPerTurno,
                  rates.isNotturnoReal,
                ),
              ),
              SizedBox(
                width: 180,
                child: rateBox(
                  'Festivo',
                  rates.indennitaFestivaPerTurno,
                  rates.isFestivoReal,
                ),
              ),
              SizedBox(
                width: 180,
                child: rateBox(
                  'OP in sede',
                  rates.ordinePubblicoInSedePerTurno,
                  rates.isOPReal,
                ),
              ),
              SizedBox(
                width: 180,
                child: rateBox(
                  'Servizio esterno',
                  rates.servizioEsternoPerTurno,
                  rates.isEsternoReal,
                ),
              ),
              const SizedBox(
                width: 180,
                child: _StaticRateBox(
                  label: 'OP fuori sede 1 turno',
                  value: '18,20',
                  subtitle: 'Importo medio netto',
                ),
              ),
              const SizedBox(
                width: 180,
                child: _StaticRateBox(
                  label: 'OP fuori sede intera',
                  value: '26,00',
                  subtitle: 'Importo medio netto',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelForOpType(shift_model.OpServiceType type) {
  switch (type) {
    case shift_model.OpServiceType.none:
      return 'Nessun OP';
    case shift_model.OpServiceType.inSede:
      return 'OP in sede';
    case shift_model.OpServiceType.fuoriSedeOneTurno:
      return 'OP fuori sede - 1 turno';
    case shift_model.OpServiceType.fuoriSedeIntera:
      return 'OP fuori sede - intera';
  }
}

  Widget _buildShiftListCard() {
    if (shifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171A21),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Nessun turno salvato per ora.',
          style: TextStyle(fontSize: 15, color: Colors.white70),
        ),
      );
    }

    return Container(
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
            'Turni salvati',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...List.generate(shifts.length, (index) {
            final shift = shifts[index];
            final value = ShiftValueCalculator.getShiftValue(
              shift,
              rates: derivedRates,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${shift.serviceDate.day.toString().padLeft(2, '0')}/${shift.serviceDate.month.toString().padLeft(2, '0')}/${shift.serviceDate.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ore: ${shift.workedHours.toStringAsFixed(1)} • OP: ${_labelForOpType(shift.opServiceType)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Str. diurno: ${shift.straordinarioDiurnoHours.toStringAsFixed(1)} • Str. nott/fest: ${shift.straordinarioNotturnoFestivoHours.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Notturni: ${shift.notturnoCount} • Festivi: ${shift.festivoCount} • Esterni: ${shift.servizioEsternoCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (shift.manualAmount != 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Extra manuale: € ${_formatMoney(shift.manualAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        if (shift.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            shift.note,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(
                        '€ ${_formatMoney(value)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () async {
                          setState(() {
                            shifts.removeAt(index);
                            extraIncome = ShiftValueCalculator.calculateTotal(
                              shifts,
                              rates: derivedRates,
                            );
                          });
                          await _saveShifts();
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShiftSimulatorCard() {
    return Container(
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
            'Simulatore turni',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Turni inseriti: ${shifts.length}',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Totale extra stimato: € ${_formatMoney(extraIncome)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRatesInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        Widget infoBlock({
          required String title,
          required String body,
        }) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5CE1A8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Come leggere questi valori',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'I valori mostrati rappresentano importi medi netti o maggiorazioni medie derivate dai cedolini caricati.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Non sono tariffe contrattuali ufficiali lorde: servono a mostrarti quanto emerge realmente dai cedolini usati per la calibrazione.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  infoBlock(
                    title: 'Straordinario orario',
                    body:
                        'È una media netta per ora ricavata dai cedolini. Può risultare più alta rispetto al valore lordo teorico perché riflette quanto emerge realmente in busta paga.',
                  ),
                  const SizedBox(height: 12),
                  infoBlock(
                    title: 'Notturno',
                    body:
                        'Non è una paga oraria completa. È la maggiorazione o indennità aggiuntiva legata alla componente notturna del servizio.',
                  ),
                  const SizedBox(height: 12),
                  infoBlock(
                    title: 'Festivo, OP e servizio esterno',
                    body:
                        'Questi importi rappresentano valori medi netti rilevati dai cedolini caricati e servono per costruire simulazioni più credibili.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Importante',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF67B7FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'I valori possono variare in base al mese, alla tassazione, al tipo di servizio e alla situazione personale. DutyPay li usa come riferimento operativo realistico, non come sostituzione del cedolino ufficiale.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _rateSupportLabel(String label) {
    switch (label) {
      case 'Straordinario orario':
        return 'Netto medio per ora';
      case 'Notturno':
        return 'Maggiorazione media';
      case 'Festivo':
        return 'Importo medio netto';
      case 'OP in sede':
        return 'Importo medio netto';
      case 'Servizio esterno':
        return 'Importo medio netto';
      case 'OP fuori sede 1 turno':
        return 'Importo medio netto';
      case 'OP fuori sede intera':
        return 'Importo medio netto';
      default:
        return 'Valore medio';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadedCount = selectedPdfNames.where((e) => e != null).length;
    final parsedCount = parsedPayslips.where((e) => e != null).length;

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calibrazione cedolini'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ),
        body: isRestoring
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 1,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calibrazione DutyPay',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Qui carichi i cedolini che permettono all’app di leggere i valori reali di straordinario e indennità.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Consigliato: carica 3 cedolini recenti. Dopo la calibrazione, la pagina Cedolino e il simulatore turni useranno questi dati per generare stime molto più affidabili.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171A21),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF67B7FF),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'I cedolini vengono usati solo per estrarre le voci utili al calcolo. Se sostituisci un PDF o ricarichi la calibrazione, DutyPay aggiorna i valori reali mostrati nell’app.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildOvertimeLimitCard(),
                  const SizedBox(height: 24),
                  _buildPdfCard(0),
                  const SizedBox(height: 14),
                  _buildPdfCard(1),
                  const SizedBox(height: 14),
                  _buildPdfCard(2),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                  const SizedBox(height: 18),
                  _buildEngineSnapshotCard(),
                  const SizedBox(height: 18),
                  _buildDerivedRatesCard(),
                  const SizedBox(height: 18),
                  _buildShiftSimulatorCard(),
                  const SizedBox(height: 18),
                  _buildShiftListCard(),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171A21),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'PDF selezionati: $loadedCount / 3\nCedolini strutturati: $parsedCount / 3',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddShiftPage,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _StaticRateBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _StaticRateBox({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF22C55E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'REALE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}