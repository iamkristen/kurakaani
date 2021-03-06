import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kurakaani/Constants/firestore_constants.dart';

class ChatUser {
  String id;
  String photoUrl;
  String nickName;
  String aboutMe;
  String phoneNumber;

  ChatUser(
      {required this.id,
      required this.photoUrl,
      required this.nickName,
      required this.aboutMe,
      required this.phoneNumber});
  Map<String, String> toJson() {
    return {
      FirestoreConstants.nickname: nickName,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.phoneNumber: phoneNumber,
    };
  }

  factory ChatUser.fromDocuments(DocumentSnapshot doc) {
    String aboutMe = "";
    String photoUrl = "";
    String nickName = "";
    String phoneNumber = "";
    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      nickName = doc.get(FirestoreConstants.nickname);
    } catch (e) {}
    try {
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    } catch (e) {}
    return ChatUser(
        id: doc.id,
        photoUrl: photoUrl,
        nickName: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber);
  }
}
