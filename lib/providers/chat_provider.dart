import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/models/message_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ChatProvider(
      {required this.prefs, required this.firestore, required this.storage});

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = storage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath,
      Map<String, dynamic> dataNeedToUpdate) {
    return firestore
        .collection(collectionPath)
        .doc(docPath)
        .update(dataNeedToUpdate);
  }

  Stream<QuerySnapshot> getChatSnapshot(String groupChatId, int limit) {
    return firestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  void sendMessage(String content, int type, String groupChatId,
      String currentUserId, String peerId) {
    DocumentReference reference = firestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(Timestamp.now().millisecondsSinceEpoch.toString());
    MsgChat msgChat = MsgChat(
        idFrom: currentUserId,
        idTo: peerId,
        timestamp: Timestamp.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: type);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(reference, msgChat.toJson());
    });
  }
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}
