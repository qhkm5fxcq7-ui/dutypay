import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBreakPaths {
  final FirebaseFirestore firestore;

  const FirestoreBreakPaths(this.firestore);

  CollectionReference<Map<String, dynamic>> get rooms {
    return firestore.collection('breakRooms');
  }

  CollectionReference<Map<String, dynamic>> get roomCodes {
    return firestore.collection('breakRoomCodes');
  }

  DocumentReference<Map<String, dynamic>> room(String roomId) {
    return rooms.doc(roomId);
  }

  DocumentReference<Map<String, dynamic>> roomCode(String roomCode) {
    return roomCodes.doc(roomCode);
  }

  CollectionReference<Map<String, dynamic>> participants(String roomId) {
    return room(roomId).collection('participants');
  }

  DocumentReference<Map<String, dynamic>> participant({
    required String roomId,
    required String deviceId,
  }) {
    return participants(roomId).doc(deviceId);
  }
}
