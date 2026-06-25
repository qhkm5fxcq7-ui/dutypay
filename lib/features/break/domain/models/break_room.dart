enum BreakRoomStatus {
  waiting,
  running,
  completed;

  static BreakRoomStatus fromValue(String? value) {
    return BreakRoomStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BreakRoomStatus.waiting,
    );
  }
}

class BreakRoom {
  final String id;
  final String roomCode;
  final String title;
  final String createdBy;
  final DateTime createdAt;
  final BreakRoomStatus status;
  final int participantsCount;
  final String? selectedPayerId;
  final String? roundSeed;
  final String? resultId;
  final String? resultText;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const BreakRoom({
    required this.id,
    required this.roomCode,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    this.status = BreakRoomStatus.waiting,
    this.participantsCount = 0,
    this.selectedPayerId,
    this.roundSeed,
    this.resultId,
    this.resultText,
    this.startedAt,
    this.completedAt,
  });

  BreakRoom copyWith({
    String? id,
    String? roomCode,
    String? title,
    String? createdBy,
    DateTime? createdAt,
    BreakRoomStatus? status,
    int? participantsCount,
    String? selectedPayerId,
    String? roundSeed,
    String? resultId,
    String? resultText,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return BreakRoom(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      participantsCount: participantsCount ?? this.participantsCount,
      selectedPayerId: selectedPayerId ?? this.selectedPayerId,
      roundSeed: roundSeed ?? this.roundSeed,
      resultId: resultId ?? this.resultId,
      resultText: resultText ?? this.resultText,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomCode': roomCode,
      'title': title,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'participantsCount': participantsCount,
      'selectedPayerId': selectedPayerId,
      'roundSeed': roundSeed,
      'resultId': resultId,
      'resultText': resultText,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory BreakRoom.fromMap(Map<String, dynamic> map) {
    return BreakRoom(
      id: map['id'] as String? ?? '',
      roomCode: map['roomCode'] as String? ?? '',
      title: map['title'] as String? ?? 'Chi paga il caffè',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      status: BreakRoomStatus.fromValue(map['status'] as String?),
      participantsCount: map['participantsCount'] as int? ?? 0,
      selectedPayerId: map['selectedPayerId'] as String?,
      roundSeed: map['roundSeed'] as String?,
      resultId: map['resultId'] as String?,
      resultText: map['resultText'] as String?,
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseDate(map['completedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);

    return null;
  }
}
