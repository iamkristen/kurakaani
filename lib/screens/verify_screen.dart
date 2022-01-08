import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/models/chat_user.dart';
import 'package:kurakaani/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({Key? key, required this.email}) : super(key: key);
  final String email;

  @override
  _VerifyScreenState createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? user;
  Timer? timer;
  bool isVerify = false;

  @override
  void initState() {
    super.initState();
    user = auth.currentUser;
    user!.sendEmailVerification();
    timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkEmailVerified();
    });
  }

  Future<void> checkEmailVerified() async {
    user = auth.currentUser!;
    await user!.reload();
    if (user!.emailVerified) {
      timer!.cancel();
      await setData();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      // print(user!.uid);
    }
  }

  Future<void> setData() async {
    User currentUser = auth.currentUser!;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // user = auth.currentUser;
    QuerySnapshot snapshot = await firestore
        .collection(FirestoreConstants.pathUserCollection)
        .where(FirestoreConstants.id, isEqualTo: currentUser.uid)
        .get();
    List<DocumentSnapshot> document = snapshot.docs;
    DocumentSnapshot documentSnapshot = document[0];
    ChatUser user = ChatUser.fromDocuments(documentSnapshot);
    await prefs.setString(FirestoreConstants.id, user.id);
    await prefs.setString(FirestoreConstants.nickname, user.nickName);
    await prefs.setString(FirestoreConstants.photoUrl, user.photoUrl);

    await prefs.setString(FirestoreConstants.phoneNumber, user.phoneNumber);
    await prefs.setString(FirestoreConstants.aboutMe, user.aboutMe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              "Welcome to Kurakaani",
              style: Theme.of(context).textTheme.headline1!.copyWith(
                  fontSize: 50, fontFamily: "signatra", letterSpacing: 1.5),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Align(
            alignment: Alignment.center,
            child: SvgPicture.asset(
              "assets/images/email_verify.svg",
              width: MediaQuery.of(context).size.width * 0.75,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thanks for registering an account with kurakaani! I hope you will enjoy chatting with random people from all over the world.",
                  style: Theme.of(context).textTheme.headline2!.copyWith(
                        fontSize: 14,
                      ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Before we get started, we'll need to verify your email.",
                  style: Theme.of(context).textTheme.headline2!.copyWith(
                        fontSize: 14,
                      ),
                ),
                const SizedBox(
                  height: 10,
                ),
                RichText(
                  text: TextSpan(
                      text: "An email has been sent to ",
                      style: Theme.of(context).textTheme.headline2!.copyWith(
                            fontSize: 14,
                          ),
                      children: [
                        TextSpan(
                          text: "${widget.email} ",
                          style: Theme.of(context)
                              .textTheme
                              .headline2!
                              .copyWith(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "please verify.",
                          style:
                              Theme.of(context).textTheme.headline2!.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                      ]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }
}
