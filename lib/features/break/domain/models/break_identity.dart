class BreakIdentity {
  final String deviceId;
  final String nickname;
  final String avatarSeed;

  const BreakIdentity({
    required this.deviceId,
    required this.nickname,
    required this.avatarSeed,
  });

  bool get hasNickname => nickname.trim().isNotEmpty;

  BreakIdentity copyWith({
    String? deviceId,
    String? nickname,
    String? avatarSeed,
  }) {
    return BreakIdentity(
      deviceId: deviceId ?? this.deviceId,
      nickname: nickname ?? this.nickname,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'nickname': nickname,
      'avatarSeed': avatarSeed,
    };
  }

  factory BreakIdentity.fromMap(Map<String, dynamic> map) {
    return BreakIdentity(
      deviceId: map['deviceId'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      avatarSeed: map['avatarSeed'] as String? ?? '',
    );
  }
}
