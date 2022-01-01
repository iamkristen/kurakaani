import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kurakaani/constants/constants.dart';

class MsgChat {
  final String idFrom;
  final String idTo;
  final String timestamp;
  final String content;
  final int type;

  MsgChat(
      {required this.idFrom,
      required this.idTo,
      required this.timestamp,
      required this.content,
      required this.type});

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.idTo: idTo,
      FirestoreConstants.timestamp: timestamp,
      FirestoreConstants.content: content,
      FirestoreConstants.type: type,
    };
  }

  factory MsgChat.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    int type = doc.get(FirestoreConstants.type);
    return MsgChat(
        idFrom: idFrom,
        idTo: idTo,
        timestamp: timestamp,
        content: content,
        type: type);
  }
}
