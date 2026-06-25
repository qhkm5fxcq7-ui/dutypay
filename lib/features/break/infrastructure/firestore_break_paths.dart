import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBreakPaths {
  static const roomsCollection = 'breakRooms';
  static const roomCodesCollection = 'breakRoomCodes';
  static const participantsCollection = 'participants';

  static const fieldId = 'id';
  static const fieldRoomId = 'roomId';
  static const fieldRoomCode = 'roomCode';
  static const fieldTitle = 'title';
  static const fieldCreatedBy = 'createdBy';
  static const fieldCreatedAt = 'createdAt';
  static const fieldStatus = 'status';
  static const fieldParticipantsCount = 'participantsCount';
  static const fieldMaxParticipants = 'maxParticipants';
  static const fieldSelectedPayerId = 'selectedPayerId';
  static const fieldRoundSeed = 'roundSeed';
  static const fieldResultId = 'resultId';
  static const fieldResultText = 'resultText';
  static const fieldStartedAt = 'startedAt';
  static const fieldCompletedAt = 'completedAt';

  static const fieldDeviceId = 'deviceId';
  static const fieldDisplayName = 'displayName';
  static const fieldJoinedAt = 'joinedAt';
  static const fieldIsReady = 'isReady';
  static const fieldLives = 'lives';
  static const fieldEliminated = 'eliminated';
  static const fieldPosition = 'position';
  static const fieldAvatarSeed = 'avatarSeed';

  final FirebaseFirestore firestore;

  const FirestoreBreakPaths(this.firestore);

  CollectionReference<Map<String, dynamic>> get rooms {
    return firestore.collection(roomsCollection);
  }

  CollectionReference<Map<String, dynamic>> get roomCodes {
    return firestore.collection(roomCodesCollection);
  }

  DocumentReference<Map<String, dynamic>> room(String roomId) {
    return rooms.doc(roomId);
  }

  DocumentReference<Map<String, dynamic>> roomCode(String roomCode) {
    return roomCodes.doc(roomCode);
  }

  CollectionReference<Map<String, dynamic>> participants(String roomId) {
    return room(roomId).collection(participantsCollection);
  }

  DocumentReference<Map<String, dynamic>> participant({
    required String roomId,
    required String deviceId,
  }) {
    return participants(roomId).doc(deviceId);
  }
}
