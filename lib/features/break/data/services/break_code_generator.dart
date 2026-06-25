import 'package:uuid/uuid.dart';

class BreakCodeGenerator {
  static const _uuid = Uuid();
  static const String _prefix = 'BRK';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String generateRoomCode() {
    final raw = _uuid.v4().replaceAll('-', '').toUpperCase();
    final buffer = StringBuffer();

    for (final char in raw.split('')) {
      if (_alphabet.contains(char)) {
        buffer.write(char);
      }

      if (buffer.length == 5) break;
    }

    return '$_prefix-${buffer.toString().padRight(5, 'X')}';
  }
}
