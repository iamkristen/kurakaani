import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kurakaani/constants/constants.dart';

class HomeProvider {
  final FirebaseFirestore firestore;

  HomeProvider({required this.firestore});

  Future<void> updateDataFirestore(
      String collectionPath, String path, Map<String, String> dataneedupdate) {
    return firestore
        .collection(collectionPath)
        .doc(path)
        .update(dataneedupdate);
  }

  Stream<QuerySnapshot> getStreamFirestore(
      String search, String pathCollection, int limit) {
    if (search.isNotEmpty) {
      return firestore
          .collection(pathCollection)
          .limit(limit)
          .where(FirestoreConstants.nickname,
              isGreaterThanOrEqualTo: search.toUpperCase())
          .snapshots();
    } else {
      return firestore
          .collection(FirestoreConstants.pathUserCollection)
          .limit(limit)
          .snapshots();
    }
  }
}
