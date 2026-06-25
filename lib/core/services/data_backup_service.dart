import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/shifts/application/models/compensative_basket_movement.dart';
import '../../features/shifts/domain/engine/models/basket_payment.dart';
import '../../features/shifts/domain/engine/models/overtime_basket_adjustment.dart';
import '../../features/shifts/domain/engine/models/rfi_basket_payment.dart';
import '../../features/shifts/presentation/models/shift.dart';
import '../../features/shifts/presentation/models/user_pay_profile.dart';

class DataBackupService {
  static Future<void> exportData({
    required String departmentId,
    required List<Shift> shifts,
    required UserPayProfile profile,
    required List<BasketPayment> basketPayments,
    required List<RfiBasketPayment> rfiBasketPayments,
    required List<OvertimeBasketAdjustment> overtimeBasketAdjustments,
    required List<CompensativeBasketMovement> compensativeBasketMovements,
  }) async {
    final data = <String, dynamic>{
      'version': 3,
      'departmentId': departmentId,
      'shifts': shifts.map((e) => e.toJson()).toList(),
      'profile': profile.toJson(),
      'basketPayments': basketPayments.map((e) => e.toJson()).toList(),
      'rfiBasketPayments': rfiBasketPayments.map((e) => e.toJson()).toList(),
      'overtimeBasketAdjustments':
          overtimeBasketAdjustments.map((e) => e.toJson()).toList(),
      'compensativeBasketMovements':
          compensativeBasketMovements.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva backup DutyPay',
      fileName: 'dutypay_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Platform.isIOS || Platform.isAndroid ? bytes : null,
    );

    if (outputPath == null || outputPath.isEmpty) return;

    if (!Platform.isIOS && !Platform.isAndroid) {
      final file = File(outputPath);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await file.writeAsBytes(bytes, flush: true);
    }
  }

  static Future<void> importData({
    required String shiftsStorageKey,
    required String payProfileStorageKey,
    required String basketPaymentsStorageKey,
    required String rfiBasketPaymentsStorageKey,
    required String overtimeBasketAdjustmentsStorageKey,
    required String compensativeBasketMovementsStorageKey,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Seleziona backup DutyPay',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final content = await _readPickedFileContent(picked);

    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw Exception('Formato backup non valido.');
    }

    final map = Map<String, dynamic>.from(decoded);
    final prefs = await SharedPreferences.getInstance();

    await _importShifts(prefs, shiftsStorageKey, map['shifts']);
    await _importProfile(prefs, payProfileStorageKey, map['profile']);

    await _importJsonList(
      prefs,
      basketPaymentsStorageKey,
      map['basketPayments'],
    );

    await _importJsonList(
      prefs,
      rfiBasketPaymentsStorageKey,
      map['rfiBasketPayments'],
    );

    await _importJsonList(
      prefs,
      overtimeBasketAdjustmentsStorageKey,
      map['overtimeBasketAdjustments'],
    );

    await _importJsonList(
      prefs,
      compensativeBasketMovementsStorageKey,
      map['compensativeBasketMovements'],
    );
  }

  static Future<String> _readPickedFileContent(PlatformFile picked) async {
    if (picked.bytes != null) {
      return utf8.decode(picked.bytes!);
    }

    final path = picked.path;
    if (path == null || path.isEmpty) {
      throw Exception('File selezionato non valido.');
    }

    final file = File(path);

    if (!await file.exists()) {
      throw Exception('Il file selezionato non esiste.');
    }

    return file.readAsString();
  }

  static Future<void> _importShifts(
    SharedPreferences prefs,
    String storageKey,
    dynamic rawShifts,
  ) async {
    if (rawShifts == null) {
      await prefs.setString(storageKey, '[]');
      return;
    }

    final normalized = _normalizeJsonList(rawShifts);
    await prefs.setString(storageKey, jsonEncode(normalized));
  }

  static Future<void> _importProfile(
    SharedPreferences prefs,
    String storageKey,
    dynamic rawProfile,
  ) async {
    if (rawProfile == null) {
      await prefs.remove(storageKey);
      return;
    }

    if (rawProfile is Map) {
      await prefs.setString(
        storageKey,
        jsonEncode(Map<String, dynamic>.from(rawProfile)),
      );
      return;
    }

    if (rawProfile is String) {
      try {
        final decoded = jsonDecode(rawProfile);
        if (decoded is Map) {
          await prefs.setString(
            storageKey,
            jsonEncode(Map<String, dynamic>.from(decoded)),
          );
          return;
        }
      } catch (_) {}
    }

    throw Exception('Formato profilo nel backup non valido.');
  }

  static Future<void> _importJsonList(
    SharedPreferences prefs,
    String storageKey,
    dynamic rawItems,
  ) async {
    if (rawItems == null) {
      await prefs.setString(storageKey, '[]');
      return;
    }

    final normalized = _normalizeJsonList(rawItems);
    await prefs.setString(storageKey, jsonEncode(normalized));
  }

  static List<Map<String, dynamic>> _normalizeJsonList(dynamic rawItems) {
    if (rawItems is List) {
      return rawItems
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          return decoded
              .where((item) => item is Map)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      } catch (_) {}
    }

    throw Exception('Formato lista backup non valido.');
  }
}
