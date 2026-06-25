import '../../domain/constants/break_constants.dart';
import '../../domain/models/break_room.dart';

class BreakRoomDto {
  final String id;
  final String roomCode;
  final String title;
  final String createdBy;
  final DateTime createdAt;
  final String status;
  final int participantsCount;
  final int maxParticipants;
  final String? selectedPayerId;
  final String? roundSeed;
  final String? resultId;
  final String? resultText;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const BreakRoomDto({
    required this.id,
    required this.roomCode,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    required this.participantsCount,
    required this.maxParticipants,
    this.selectedPayerId,
    this.roundSeed,
    this.resultId,
    this.resultText,
    this.startedAt,
    this.completedAt,
  });

  factory BreakRoomDto.fromDomain(BreakRoom room) {
    return BreakRoomDto(
      id: room.id,
      roomCode: room.roomCode,
      title: room.title,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      status: room.status.name,
      participantsCount: room.participantsCount,
      maxParticipants: room.maxParticipants,
      selectedPayerId: room.selectedPayerId,
      roundSeed: room.roundSeed,
      resultId: room.resultId,
      resultText: room.resultText,
      startedAt: room.startedAt,
      completedAt: room.completedAt,
    );
  }

  BreakRoom toDomain() {
    return BreakRoom(
      id: id,
      roomCode: roomCode,
      title: title,
      createdBy: createdBy,
      createdAt: createdAt,
      status: BreakRoomStatus.fromValue(status),
      participantsCount: participantsCount,
      maxParticipants: maxParticipants,
      selectedPayerId: selectedPayerId,
      roundSeed: roundSeed,
      resultId: resultId,
      resultText: resultText,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  factory BreakRoomDto.fromFirestore(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return BreakRoomDto(
      id: id,
      roomCode: map['roomCode'] as String? ?? '',
      title: map['title'] as String? ?? BreakConstants.defaultRoomTitle,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      status: map['status'] as String? ?? BreakRoomStatus.waiting.name,
      participantsCount: map['participantsCount'] as int? ?? 0,
      maxParticipants: map['maxParticipants'] as int? ??
          BreakConstants.defaultMaxParticipants,
      selectedPayerId: map['selectedPayerId'] as String?,
      roundSeed: map['roundSeed'] as String?,
      resultId: map['resultId'] as String?,
      resultText: map['resultText'] as String?,
      startedAt: _readDate(map['startedAt']),
      completedAt: _readDate(map['completedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'roomCode': roomCode,
      'title': title,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'status': status,
      'participantsCount': participantsCount,
      'maxParticipants': maxParticipants,
      'selectedPayerId': selectedPayerId,
      'roundSeed': roundSeed,
      'resultId': resultId,
      'resultText': resultText,
      'startedAt': startedAt,
      'completedAt': completedAt,
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
