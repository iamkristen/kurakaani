import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/models/chat_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status {
  uninitialized,
  authenticating,
  authenticated,
  authenticateError,
  authenticateCancel,
}

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SharedPreferences prefs;
  Status _status = Status.uninitialized;

  AuthProvider(
      {required this.googleSignIn,
      required this.firebaseAuth,
      required this.firestore,
      required this.prefs});

  Status get status => _status;

  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn &&
        prefs.getString(FirestoreConstants.id)!.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      User? firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;

      if (firebaseUser != null) {
        final QuerySnapshot snapshot = await firestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
            .get();
        List<DocumentSnapshot> document = snapshot.docs;
        if (document.isEmpty) {
          firestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .set({
            FirestoreConstants.nickname: firebaseUser.displayName,
            FirestoreConstants.photoUrl: firebaseUser.photoURL,
            FirestoreConstants.id: firebaseUser.uid,
            "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null,
          });
          User? currentUser = firebaseUser;

          await prefs.setString(FirestoreConstants.id, currentUser.uid);
          await prefs.setString(
              FirestoreConstants.nickname, currentUser.displayName ?? "");
          await prefs.setString(
              FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
          await prefs.setString(
              FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? "");
        } else {
          DocumentSnapshot documentSnapshot = document[0];
          ChatUser user = ChatUser.fromDocuments(documentSnapshot);
          await prefs.setString(FirestoreConstants.id, user.id);
          await prefs.setString(FirestoreConstants.nickname, user.nickName);
          await prefs.setString(FirestoreConstants.photoUrl, user.photoUrl);
          await prefs.setString(
              FirestoreConstants.phoneNumber, user.phoneNumber);
          await prefs.setString(FirestoreConstants.aboutMe, user.aboutMe);
        }

        _status = Status.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    } else {
      _status = Status.authenticateCancel;
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
