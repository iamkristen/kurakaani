import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
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
    Reference reference =
        storage.ref().child(FirestoreConstants.pathMessagePic).child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<File> compressImage(
      {required File image, int quality = 75, percentage = 30}) async {
    File file = await FlutterNativeImage.compressImage(image.path,
        quality: quality, percentage: percentage);
    return file;
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
        .collection(FirestoreConstants.pathChatroomsCollection)
        .doc(groupChatId)
        .collection(FirestoreConstants.pathChatCollection)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  Future sendMessage(String content, int type, String groupChatId,
      String currentUserId, String peerId) async {
    DocumentReference reference = firestore
        .collection(FirestoreConstants.pathChatroomsCollection)
        .doc(groupChatId)
        .collection(FirestoreConstants.pathChatCollection)
        .doc(Timestamp.now().millisecondsSinceEpoch.toString());

    firestore
        .collection(FirestoreConstants.pathChatroomsCollection)
        .doc(groupChatId)
        .set({
      "message": content,
      "lastMessageSendBy": currentUserId,
      "timestamp": DateTime.now(),
      "users": [currentUserId, peerId]
    });

    MsgChat msgChat = MsgChat(
        idFrom: currentUserId,
        idTo: peerId,
        timestamp: Timestamp.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: type);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(reference, msgChat.toJson());
    });
  }

  updateLastMessageSend(
      String chatRoomId, Map<String, dynamic> lastMessageInfo) {
    firestore
        .collection(FirestoreConstants.pathChatroomsCollection)
        .doc(chatRoomId)
        .update(lastMessageInfo);
  }
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}
