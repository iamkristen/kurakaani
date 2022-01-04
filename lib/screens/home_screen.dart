import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kurakaani/constants/app_constants.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/main.dart';
import 'package:kurakaani/models/chat_user.dart';
import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/providers/home_provider.dart';
import 'package:kurakaani/providers/settings_provider.dart';
import 'package:kurakaani/screens/chat_screen.dart';
import 'package:kurakaani/screens/login_screen.dart';
import 'package:kurakaani/screens/settings_screen.dart';
import 'package:kurakaani/utils/debouncer.dart';
import 'package:kurakaani/utils/utilities.dart';
import 'package:kurakaani/widgets/loading_view.dart';
import 'package:kurakaani/widgets/progress.dart';
import 'package:kurakaani/widgets/theme_button.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  ScrollController listScrollController = ScrollController();
  StreamController<bool> btnClearController = StreamController<bool>();
  GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AuthProvider? authProvider;
  SettingsProvider? settingsProvider;
  HomeProvider? homeProvider;
  Debouncer searchDebouncer = Debouncer(millisecond: 300);
  int _limit = 20;
  final int _limitIncrement = 20;
  String? currentUserId;
  String? photoUrl;
  String? nickname;
  String? _textSearch;
  bool isLoading = false;
  FocusNode searchFocusNode = FocusNode();

  Drawer buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
              child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 56,
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  radius: 53,
                  child: CircleAvatar(
                      backgroundColor: ColorConstants.greyColor2,
                      radius: 50,
                      backgroundImage: NetworkImage(settingsProvider!
                          .getprefs(FirestoreConstants.photoUrl)!),
                      onBackgroundImageError: (exception, stackTrace) {
                        const Icon(
                          Icons.account_circle,
                          size: 90,
                        );
                      }),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(nickname!),
            ],
          )),
          ListTile(
            tileColor: Colors.transparent,
            leading: Icon(
              Icons.color_lens_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: const Text(
              AppConstants.darkMode,
            ),
            trailing: const ThemeSwitch(),
          ),
          GestureDetector(
            onTap: () {
              handleSignOut();
            },
            child: ListTile(
              tileColor: Colors.transparent,
              leading: Icon(
                Icons.exit_to_app,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(AppConstants.logout),
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen())),
            child: ListTile(
              tileColor: Colors.transparent,
              leading: Icon(
                Icons.account_circle_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text(AppConstants.profile),
            ),
          ),
          Expanded(
            child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  height: 70,
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                            text: "Developed by ",
                            style: const TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: "Kristen",
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Fluttertoast.showToast(
                                      msg: 'iamkristen220@gmail.com'),
                              ),
                            ]),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text.rich(TextSpan(
                          text: "Powered by ",
                          style: const TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: "HostBala Technologies",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Fluttertoast.showToast(
                                    msg: 'www.hostbala.com'),
                            ),
                          ]))
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }

  openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.exit_to_app),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        AppConstants.exitApp,
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    AppConstants.alertExitApp,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 0);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.clear,
                          color: Colors.red,
                        ),
                        Text(
                          "Cancel",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 1);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.done,
                          color: Colors.green,
                        ),
                        Text(
                          "Yes",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Future<bool> onBackPress() {
    openDialog();
    // searchFocusNode.unfocus();
    return Future.value(false);
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  handleSignOut() async {
    await authProvider!.handleSignOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  changeIt(bool value) {
    setState(() {
      isDark = value;
    });
  }

  void registerNotification() {
    firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(message.notification!);
      }
      return;
    });

    firebaseMessaging.getToken().then((token) {
      if (token != null) {
        homeProvider!.updateDataFirestore(FirestoreConstants.pathUserCollection,
            currentUserId!, {'pushToken': token});
      }
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configureLocalNotification() {
    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('launcher_icon');
    IOSInitializationSettings iosInitializationSettings =
        const IOSInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);
    FlutterLocalNotificationsPlugin().initialize(initializationSettings);
  }

  void showNotification(RemoteNotification remoteNotification) async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails("com.hostbala.kurakaani", "KuraKaani",
            playSound: true,
            enableVibration: true,
            importance: Importance.high,
            priority: Priority.high);
    IOSNotificationDetails iosNotificationDetails =
        const IOSNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: iosNotificationDetails);
    await FlutterLocalNotificationsPlugin().show(0, remoteNotification.title,
        remoteNotification.body, notificationDetails,
        payload: null);
  }

  @override
  void initState() {
    authProvider = context.read<AuthProvider>();
    settingsProvider = context.read<SettingsProvider>();
    homeProvider = context.read<HomeProvider>();
    photoUrl = settingsProvider!.getprefs(FirestoreConstants.photoUrl);
    nickname = settingsProvider!.getprefs(FirestoreConstants.nickname);
    super.initState();
    if (authProvider!.getUserFirebaseId()!.isNotEmpty) {
      currentUserId = authProvider!.getUserFirebaseId();
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
    listScrollController.addListener(scrollListener);
    registerNotification();
    configureLocalNotification();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        searchFocusNode.unfocus();
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            AppConstants.appTitle,
            style: TextStyle(
                fontSize: 40, fontFamily: 'signatra', letterSpacing: 1.5),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  Fluttertoast.showToast(
                      msg: "Story Features is under development");
                },
                icon: const Icon(Icons.photo_camera)),
          ],
        ),
        drawer: buildDrawer(),
        body: WillPopScope(
          onWillPop: onBackPress,
          child: Stack(children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: TextFormField(
                    focusNode: searchFocusNode,
                    textInputAction: TextInputAction.search,
                    controller: searchController,
                    cursorColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        btnClearController.add(true);
                        setState(() {
                          _textSearch = value;
                        });
                      } else {
                        btnClearController.add(false);
                        setState(() {
                          _textSearch = "";
                        });
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 15.0),
                      hintText: AppConstants.search,
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(35.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(35.0),
                      ),
                    ),
                  ),
                ),
                StreamBuilder(
                    stream: btnClearController.stream,
                    builder: (context, snapshot) {
                      return snapshot.data == true
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(45),
                                color:
                                    ColorConstants.greyColor2.withOpacity(.4),
                              ),
                              child: IconButton(
                                  onPressed: () {
                                    btnClearController.add(false);
                                    searchController.clear();
                                    setState(() {
                                      _textSearch = "";
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 25,
                                  )),
                            )
                          : const SizedBox.shrink();
                    }),
                StreamBuilder<QuerySnapshot>(
                  stream: homeProvider!.getStreamFirestore(_textSearch ?? "",
                      FirestoreConstants.pathUserCollection, _limit),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.docs.isNotEmpty) {
                        return Expanded(
                          child: ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              controller: listScrollController,
                              itemBuilder: (context, index) {
                                return UserResult(
                                  document: snapshot.data!.docs[index],
                                  currentUserId: currentUserId!,
                                );
                              }),
                        );
                      } else {
                        return const Center(
                          child: Text("No User Found"),
                        );
                      }
                    } else {
                      return circularProgress();
                    }
                  },
                ),
              ],
            ),
            Positioned(
                child:
                    isLoading ? const LoadingView() : const SizedBox.shrink()),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    btnClearController.close();
  }
}

class UserResult extends StatelessWidget {
  const UserResult(
      {Key? key, required this.document, required this.currentUserId})
      : super(key: key);

  final QueryDocumentSnapshot document;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    ChatUser chatUser = ChatUser.fromDocuments(document);
    if (chatUser.id == currentUserId) {
      return const SizedBox.shrink();
    } else {}
    return GestureDetector(
      onTap: () {
        if (Utilities.isKeyboardShowing()) {
          Utilities.closeKeyboard(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                peerId: chatUser.id,
                peerAvtar: chatUser.photoUrl,
                peerNickname: chatUser.nickName,
                peerPhoneNumber: chatUser.phoneNumber,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                peerId: chatUser.id,
                peerAvtar: chatUser.photoUrl,
                peerNickname: chatUser.nickName,
                peerPhoneNumber: chatUser.phoneNumber,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          leading: chatUser.photoUrl.isNotEmpty
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 21,
                  child: CircleAvatar(
                    radius: 20,
                    onBackgroundImageError: (error, stackTrace) {
                      Icon(
                        Icons.account_circle,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      );
                    },
                    backgroundImage: NetworkImage(
                      chatUser.photoUrl,
                    ),
                  ),
                )
              : Icon(
                  Icons.account_circle,
                  size: 50,
                  color: Theme.of(context).primaryColor,
                ),
          title: Text(chatUser.nickName.toString(),
              maxLines: 1,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1!
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(
            chatUser.aboutMe.toString(),
            maxLines: 1,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
