import '../../domain/models/break_participant.dart';

class BreakParticipantDto {
  final String id;
  final String deviceId;
  final String roomId;
  final String displayName;
  final DateTime joinedAt;
  final bool isReady;
  final int lives;
  final bool eliminated;
  final int position;
  final String avatarSeed;

  const BreakParticipantDto({
    required this.id,
    required this.deviceId,
    required this.roomId,
    required this.displayName,
    required this.joinedAt,
    required this.isReady,
    required this.lives,
    required this.eliminated,
    required this.position,
    required this.avatarSeed,
  });

  factory BreakParticipantDto.fromDomain(BreakParticipant participant) {
    return BreakParticipantDto(
      id: participant.id,
      deviceId: participant.deviceId,
      roomId: participant.roomId,
      displayName: participant.displayName,
      joinedAt: participant.joinedAt,
      isReady: participant.isReady,
      lives: participant.lives,
      eliminated: participant.eliminated,
      position: participant.position,
      avatarSeed: participant.avatarSeed,
    );
  }

  BreakParticipant toDomain() {
    return BreakParticipant(
      id: id,
      deviceId: deviceId,
      roomId: roomId,
      displayName: displayName,
      joinedAt: joinedAt,
      isReady: isReady,
      lives: lives,
      eliminated: eliminated,
      position: position,
      avatarSeed: avatarSeed,
    );
  }

  factory BreakParticipantDto.fromFirestore(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return BreakParticipantDto(
      id: id,
      deviceId: map['deviceId'] as String? ?? id,
      roomId: map['roomId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      joinedAt: _readDate(map['joinedAt']) ?? DateTime.now(),
      isReady: map['isReady'] as bool? ?? false,
      lives: map['lives'] as int? ?? 1,
      eliminated: map['eliminated'] as bool? ?? false,
      position: map['position'] as int? ?? 0,
      avatarSeed: map['avatarSeed'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'deviceId': deviceId,
      'roomId': roomId,
      'displayName': displayName,
      'joinedAt': joinedAt,
      'isReady': isReady,
      'lives': lives,
      'eliminated': eliminated,
      'position': position,
      'avatarSeed': avatarSeed,
    };
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final dynamicDate = value as dynamic;
    try {
      final date = dynamicDate.toDate();
      if (date is DateTime) return date;
    } catch (_) {}

    if (value is String) return DateTime.tryParse(value);

    return null;
  }
}
