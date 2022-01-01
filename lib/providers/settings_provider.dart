import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  SettingsProvider(
      {required this.prefs, required this.firestore, required this.storage});

  String? getprefs(String key) {
    return prefs.getString(key);
  }

  Future<bool> setPrefs(String key, String value) async {
    return await prefs.setString(key, value);
  }

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = storage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);

    return uploadTask;
  }

  Future<void> updateDataFirestore(
      String collectionPath, String path, Map<String, String> dataNeedUpdate) {
    return firestore
        .collection(collectionPath)
        .doc(path)
        .update(dataNeedUpdate);
  }
}
