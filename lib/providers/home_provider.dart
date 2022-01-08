import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeProvider {
  final FirebaseFirestore firestore;
  final SharedPreferences prefs;

  HomeProvider({required this.firestore, required this.prefs});

  Future<void> updateDataFirestore(
      String collectionPath, String path, Map<String, String> dataneedupdate) {
    return firestore
        .collection(collectionPath)
        .doc(path)
        .update(dataneedupdate);
  }

  Stream<QuerySnapshot> getChatRooms(String currentUserId) {
    return firestore
        .collection(FirestoreConstants.pathChatroomsCollection)
        .orderBy("timestamp", descending: true)
        .where("users", arrayContains: currentUserId)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String userId) {
    return firestore
        .collection(FirestoreConstants.pathUserCollection)
        .where(FirestoreConstants.id, isEqualTo: userId)
        .get();
  }

  Stream<QuerySnapshot> getStreamFirestore(
      String search, String pathCollection, int limit) {
    if (search.isNotEmpty) {
      return firestore
          .collection(pathCollection)
          .limit(limit)
          .where(FirestoreConstants.nickname, isEqualTo: search.toUpperCase())
          .snapshots();
    } else {
      return firestore
          .collection(FirestoreConstants.pathUserCollection)
          .limit(limit)
          .snapshots();
    }
  }
}
