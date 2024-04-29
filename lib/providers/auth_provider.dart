import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

class KurakaaniAuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final SharedPreferences prefs;
  Status _status = Status.uninitialized;

  KurakaaniAuthProvider(
      {required this.googleSignIn,
      required this.firebaseAuth,
      required this.firestore,
      required this.storage,
      required this.prefs});

  Status get status => _status;

  Future<String> signUp(String nickName, String aboutMe, String email,
      String password, File? photo) async {
    String res = "Some error occured";
    bool isValid = photo != null &&
        nickName.isNotEmpty &&
        aboutMe.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty;
    try {
      if (isValid == true) {
        UserCredential credential =
            await firebaseAuth.createUserWithEmailAndPassword(
                email: email.trim(), password: password.trim());
        String photoUrl = await uploadPhotoToStorage(
            FirestoreConstants.pathProfilePic, photo);
        if (credential.user != null) {
          firestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(credential.user!.uid)
              .set({
            FirestoreConstants.email: credential.user!.email,
            FirestoreConstants.id: credential.user!.uid,
            FirestoreConstants.photoUrl: photoUrl,
            FirestoreConstants.aboutMe: aboutMe,
            FirestoreConstants.nickname: nickName,
            "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null,
          });
          res = "Success";
        }
      } else {
        res = "All fields are required*";
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == "invalid-email") {
        res = "The email is badly formatted";
      } else if (err.code == "weak-password") {
        res = "password should be atleast 6 character";
      } else if (err.code == "email-already-in-use") {
        res = "Email already in use";
      } else if (err.code == "network-request-failed") {
        res = "Network Error";
      } else {
        res = err.toString();
      }
    }
    return res;
  }

  Future<String> login(String email, String password) async {
    String res = "Error occured";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential credential =
            await firebaseAuth.signInWithEmailAndPassword(
                email: email.trim(), password: password.trim());

        if (credential.user!.emailVerified) {
          QuerySnapshot snapshot = await firestore
              .collection(FirestoreConstants.pathUserCollection)
              .where(FirestoreConstants.id, isEqualTo: credential.user!.uid)
              .get();
          List<DocumentSnapshot> document = snapshot.docs;
          DocumentSnapshot documentSnapshot = document[0];
          ChatUser user = ChatUser.fromDocuments(documentSnapshot);
          await prefs.setString(FirestoreConstants.id, user.id);
          await prefs.setString(FirestoreConstants.nickname, user.nickName);
          await prefs.setString(FirestoreConstants.photoUrl, user.photoUrl);

          await prefs.setString(
              FirestoreConstants.phoneNumber, user.phoneNumber);
          await prefs.setString(FirestoreConstants.aboutMe, user.aboutMe);
          res = "Success";
        } else {
          res = "not-verified";
        }
      } else {
        res = "All fields are required*";
      }
    } on FirebaseAuthException catch (err) {
      if (err.code == "network-request-failed") {
        res = "Network Error";
      } else if (err.code == "wrong-password") {
        res = "Password Incorrect";
      } else if (err.code == "user-not-found") {
        res = "User not exists";
      } else if (err.code == "user-disabled") {
        res = "Account temporarily suspended!";
      } else {
        res = err.toString();
      }
    }
    return res;
  }

  Future<String> uploadPhotoToStorage(String profilePath, File? file) async {
    Reference ref =
        storage.ref().child(profilePath).child(firebaseAuth.currentUser!.uid);
    TaskSnapshot uploadTask = await ref.putFile(file!);
    String url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  Future<String> resetPassword(String email) async {
    String res = "Provide email";
    if (email.trim().isNotEmpty) {
      try {
        await firebaseAuth.sendPasswordResetEmail(email: email.trim());
        res = "success";
      } on FirebaseAuthException catch (err) {
        if (err.code == "invalid-email") {
          res = "The email is badly formatted";
        } else if (err.code == "user-not-found") {
          res = "User not exists";
        } else if (err.code == "user-disabled") {
          res = "Account temporarily suspended!";
        } else if (err.code == "network-request-failed") {
          res = "Network Error";
        } else {
          res = err.toString();
        }
      }
    }
    return res;
  }

//for UserId
  String? getUserFirebaseId() {
    return prefs.getString(FirestoreConstants.id);
  }
//Firebase Login with Google

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = await googleSignIn.isSignedIn();
    if (firebaseAuth.currentUser != null) {
      isLoggedIn = firebaseAuth.currentUser!.uid.isNotEmpty;
    }
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
            FirestoreConstants.email: firebaseUser.email ?? " ",
            FirestoreConstants.photoUrl: firebaseUser.photoURL,
            FirestoreConstants.aboutMe: "",
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
          await prefs.setString(FirestoreConstants.aboutMe, "");
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
    if (await googleSignIn.isSignedIn()) {
      _status = Status.uninitialized;
      await firebaseAuth.signOut();
      await googleSignIn.disconnect();
      await googleSignIn.signOut();
      prefs.setString(FirestoreConstants.id, "");
    } else {
      await FirebaseAuth.instance.signOut();
      prefs.setString(FirestoreConstants.id, "");
    }
  }
}
