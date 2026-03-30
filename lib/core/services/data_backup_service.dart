import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataBackupService {
  static const String shiftsKey = 'dutypay_shifts';
  static const String profileKey = 'dutypay_pay_profile';

  static Future<void> exportData() async {
    final prefs = await SharedPreferences.getInstance();

    final shiftsJson = await _readShiftsJsonForExport(prefs);
    final profileJson = prefs.getString(profileKey);

    final data = <String, dynamic>{
      'version': 2,
      'shifts': _safeDecodeShifts(shiftsJson),
      'profile': _safeDecodeProfile(profileJson),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva backup DutyPay',
      fileName: 'dutypay_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (outputPath == null || outputPath.isEmpty) {
      return;
    }

    if (!Platform.isIOS && !Platform.isAndroid) {
      final file = File(outputPath);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await file.writeAsBytes(bytes, flush: true);
    }
  }

  static Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Seleziona backup DutyPay',
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;

    String content;

    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else {
      final path = picked.path;
      if (path == null || path.isEmpty) {
        throw Exception('File selezionato non valido.');
      }

      final file = File(path);

      if (!await file.exists()) {
        throw Exception('Il file selezionato non esiste.');
      }

      content = await file.readAsString();
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map) {
      throw Exception('Formato backup non valido.');
    }

    final map = Map<String, dynamic>.from(decoded as Map);
    final prefs = await SharedPreferences.getInstance();

    await _importShifts(prefs, map['shifts']);
    await _importProfile(prefs, map['profile']);
  }

  static Future<String> _readShiftsJsonForExport(SharedPreferences prefs) async {
    final newFormat = prefs.getString(shiftsKey);
    if (newFormat != null && newFormat.trim().isNotEmpty) {
      return newFormat;
    }

    final legacyList = prefs.getStringList(shiftsKey);
    if (legacyList == null || legacyList.isEmpty) {
      return '[]';
    }

    final parsed = <dynamic>[];
    for (final item in legacyList) {
      try {
        parsed.add(jsonDecode(item));
      } catch (_) {}
    }

    return jsonEncode(parsed);
  }

  static List<dynamic> _safeDecodeShifts(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return <dynamic>[];
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded;
      }
    } catch (_) {}

    return <dynamic>[];
  }

  static Map<String, dynamic>? _safeDecodeProfile(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded as Map);
      }
    } catch (_) {}

    return null;
  }

  static Future<void> _importShifts(
    SharedPreferences prefs,
    dynamic rawShifts,
  ) async {
    if (rawShifts == null) {
      await prefs.setString(shiftsKey, '[]');
      return;
    }

    if (rawShifts is List) {
      final normalized = rawShifts
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      await prefs.setString(shiftsKey, jsonEncode(normalized));
      return;
    }

    if (rawShifts is String) {
      try {
        final decoded = jsonDecode(rawShifts);
        if (decoded is List) {
          final normalized = decoded
              .where((item) => item is Map)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

          await prefs.setString(shiftsKey, jsonEncode(normalized));
          return;
        }
      } catch (_) {}
    }

    throw Exception('Formato turni nel backup non valido.');
  }

  static Future<void> _importProfile(
    SharedPreferences prefs,
    dynamic rawProfile,
  ) async {
    if (rawProfile == null) {
      await prefs.remove(profileKey);
      return;
    }

    if (rawProfile is Map) {
      await prefs.setString(
        profileKey,
        jsonEncode(Map<String, dynamic>.from(rawProfile as Map)),
      );
      return;
    }

    if (rawProfile is String) {
      try {
        final decoded = jsonDecode(rawProfile);
        if (decoded is Map) {
          await prefs.setString(
            profileKey,
            jsonEncode(Map<String, dynamic>.from(decoded as Map)),
          );
          return;
        }
      } catch (_) {}
    }

    throw Exception('Formato profilo nel backup non valido.');
  }
}