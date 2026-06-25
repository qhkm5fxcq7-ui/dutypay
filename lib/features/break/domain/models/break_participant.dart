class BreakParticipant {
  final String id;
  final String roomId;
  final String displayName;
  final DateTime joinedAt;
  final bool isReady;
  final int lives;
  final bool eliminated;
  final int position;
  final String avatarSeed;
  final String deviceId;

  const BreakParticipant({
    required this.id,
    required this.roomId,
    required this.displayName,
    required this.joinedAt,
    this.isReady = false,
    this.lives = 1,
    this.eliminated = false,
    this.position = 0,
    required this.avatarSeed,
    required this.deviceId,
  });

  BreakParticipant copyWith({
    String? id,
    String? roomId,
    String? displayName,
    DateTime? joinedAt,
    bool? isReady,
    int? lives,
    bool? eliminated,
    int? position,
    String? avatarSeed,
    String? deviceId,
  }) {
    return BreakParticipant(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt ?? this.joinedAt,
      isReady: isReady ?? this.isReady,
      lives: lives ?? this.lives,
      eliminated: eliminated ?? this.eliminated,
      position: position ?? this.position,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'displayName': displayName,
      'joinedAt': joinedAt.toIso8601String(),
      'isReady': isReady,
      'lives': lives,
      'eliminated': eliminated,
      'position': position,
      'avatarSeed': avatarSeed,
      'deviceId': deviceId,
    };
  }

  factory BreakParticipant.fromMap(Map<String, dynamic> map) {
    return BreakParticipant(
      id: map['id'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      joinedAt: _parseDate(map['joinedAt']) ?? DateTime.now(),
      isReady: map['isReady'] as bool? ?? false,
      lives: map['lives'] as int? ?? 1,
      eliminated: map['eliminated'] as bool? ?? false,
      position: map['position'] as int? ?? 0,
      avatarSeed: map['avatarSeed'] as String? ?? '',
      deviceId: map['deviceId'] as String? ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);

    return null;
  }
}
