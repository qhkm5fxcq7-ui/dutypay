import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/constants/break_constants.dart';
import '../../domain/models/break_identity.dart';

class LocalBreakIdentityDatasource {
  const LocalBreakIdentityDatasource();

  Future<BreakIdentity> getOrCreateIdentity() async {
    final prefs = await SharedPreferences.getInstance();

    var deviceId = prefs.getString(BreakConstants.localDeviceIdKey);
    var avatarSeed = prefs.getString(BreakConstants.localAvatarSeedKey);
    final nickname = prefs.getString(BreakConstants.localNicknameKey) ?? '';

    deviceId ??= _generateDeviceId();
    avatarSeed ??= _generateAvatarSeed();

    await prefs.setString(BreakConstants.localDeviceIdKey, deviceId);
    await prefs.setString(BreakConstants.localAvatarSeedKey, avatarSeed);

    return BreakIdentity(
      deviceId: deviceId,
      nickname: nickname,
      avatarSeed: avatarSeed,
    );
  }

  Future<BreakIdentity> saveNickname(String nickname) async {
    final current = await getOrCreateIdentity();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(BreakConstants.localNicknameKey, nickname);

    return current.copyWith(nickname: nickname);
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    return 'brk_$timestamp$entropy';
  }

  String _generateAvatarSeed() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
