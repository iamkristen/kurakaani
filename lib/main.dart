import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:kurakaani/Constants/app_constants.dart';

import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/providers/chat_provider.dart';
import 'package:kurakaani/providers/home_provider.dart';
import 'package:kurakaani/providers/settings_provider.dart';
import 'package:kurakaani/providers/theme_provider.dart';

import 'package:kurakaani/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool isDark = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
              googleSignIn: GoogleSignIn(),
              firebaseAuth: FirebaseAuth.instance,
              firestore: firestore,
              prefs: prefs),
        ),
        Provider(
            create: (_) => SettingsProvider(
                prefs: prefs, firestore: firestore, storage: storage)),
        Provider(create: (_) => HomeProvider(firestore: firestore)),
        Provider(
          create: (_) => ChatProvider(
              prefs: prefs, firestore: firestore, storage: storage),
        ),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: AppConstants.appTitle,
      themeMode: themeProvider.themeMode,
      theme: Themes.lightTheme,
      darkTheme: Themes.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
