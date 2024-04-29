import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kurakaani/constants/app_constants.dart';
import 'package:kurakaani/constants/color_constants.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/providers/settings_provider.dart';
import 'package:kurakaani/screens/home_screen.dart';
import 'package:kurakaani/screens/reset_screen.dart';
import 'package:kurakaani/screens/verify_screen.dart';
import 'package:kurakaani/utils/utilities.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

enum Loading {
  initial,
  runnung,
  done,
  error,
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController nickName = TextEditingController();
  TextEditingController aboutMe = TextEditingController();
  TextEditingController password = TextEditingController();
  String? imgUrl;
  String? userId;
  String? res;
  KurakaaniAuthProvider? authProvider;
  SettingsProvider? settingsProvider;
  bool _obscureText = true;
  bool isLogin = true;
  File? avtarImageFile;
  bool isLoading = false;
  Loading _loading = Loading.initial;
  bool isUpload = false;

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
    return Future.value(false);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err);
    });
    if (file != null) {
      setState(() {
        avtarImageFile = File(file.path);
      });
    }
  }

  void handleSignUp() async {
    closeKeyboard();
    setState(() {
      _loading = Loading.runnung;
    });
    res = await authProvider!.signUp(
        nickName.text, aboutMe.text, email.text, password.text, avtarImageFile);
    if (res != "Success") {
      setState(() {
        _loading = Loading.initial;
      });
      errorSnackbar(res!);
    } else {
      setState(() {
        _loading = Loading.done;
      });
      successSnackbar("Your account is registered successfully.");

      handleSignIn();
    }
  }

  void closeKeyboard() {
    if (Utilities.isKeyboardShowing()) {
      Utilities.closeKeyboard(context);
    }
  }

  void handleSignIn() async {
    setState(() {
      isLoading = true;
    });
    res = await authProvider!.login(email.text, password.text);
    if (res == "Success") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else if (res == "not-verified") {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyScreen(
                    email: email.text,
                  )));
    } else {
      errorSnackbar(res!);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<KurakaaniAuthProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);

    switch (authProvider!.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "SignIn Failed");
        break;
      case Status.authenticateCancel:
        Fluttertoast.showToast(msg: "SignIn cancelled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "SignIn Success");
        break;
      default:
        break;
    }

    return GestureDetector(
      onTap: () => closeKeyboard(),
      child: SafeArea(
        child: Scaffold(
          body: WillPopScope(
            onWillPop: onBackPress,
            child: Center(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1000),
                  child: isLogin ? loginWidget() : signupWidget(),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputFeild(IconData prefixIcon, BuildContext context,
      TextEditingController controller, String hintText, String label) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(15),
          labelText: label,
          hintText: hintText,
          hintStyle: const TextStyle(fontStyle: FontStyle.italic),
          prefixIcon: Icon(
            prefixIcon,
            size: 30,
          ),
          filled: true,
          fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(35.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(35.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(35.0),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordFeild(
    IconData prefixIcon,
    BuildContext context,
    TextEditingController controller,
    String hintText,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        obscureText: _obscureText,
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(15),
          labelText: label,
          hintText: hintText,
          hintStyle: const TextStyle(fontStyle: FontStyle.italic),
          prefixIcon: Icon(
            prefixIcon,
            size: 30,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            icon: Icon(
              _obscureText
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 30,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(35.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(35.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(35.0),
          ),
        ),
      ),
    );
  }

  Widget buildButton(VoidCallback callback, {required Widget child}) {
    return ElevatedButton(
      onPressed: callback,
      child: child,
      style: ElevatedButton.styleFrom(
        elevation: 5,
        minimumSize: const Size(130, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget loginWidget() {
    return Container(
        key: const Key("login"),
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Colors.grey.withOpacity(.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 20,
                offset: const Offset(0, 15),
              )
            ],
            borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Column(children: [
            buildInputFeild(Icons.email_rounded, context, email,
                "iamkristen220@gmail.com", "Email"),
            buildPasswordFeild(
              Icons.lock_rounded,
              context,
              password,
              "********",
              "Password",
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ResetScreen()));
              },
              child: Text(
                "Forgot Password?",
                style: Theme.of(context)
                    .textTheme
                    .headline2!
                    .copyWith(fontSize: 15),
              ),
            ),
            buildButton(
              () {
                handleSignIn();
              },
              child: isLoading
                  ? CircularProgressIndicator(
                      color: Theme.of(context).cardColor,
                    )
                  : Text(
                      "SignIn",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2!
                          .copyWith(fontSize: 18),
                    ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text.rich(
              TextSpan(
                  text: "Don't have an account? ",
                  style: Theme.of(context)
                      .textTheme
                      .headline2!
                      .copyWith(fontSize: 15),
                  children: [
                    TextSpan(
                      text: "SignUp",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          closeKeyboard();
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                    ),
                  ]),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(children: [
                const Expanded(
                  child: Divider(
                    thickness: .8,
                  ),
                ),
                Text(
                  " or signIn with ",
                  style: Theme.of(context)
                      .textTheme
                      .headline2!
                      .copyWith(fontSize: 14),
                ),
                const Expanded(
                  child: Divider(
                    thickness: .8,
                  ),
                ),
              ]),
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                loginProvider(context, FontAwesomeIcons.google, () async {
                  bool isSuccess = await authProvider!.handleSignIn();
                  if (isSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  }
                })
              ],
            ),
          ]),
        ));
  }

  Widget signupWidget() {
    return Container(
      key: const Key("signup"),
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Colors.grey.withOpacity(.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 20,
              offset: const Offset(0, 15),
            )
          ],
          borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(children: [
          InkWell(
              onTap: getImage,
              child: avtarImageFile == null
                  ? CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 45,
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 60,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 50,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).cardColor,
                        radius: 47,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundImage: FileImage(avtarImageFile!),
                        ),
                      ),
                    )),
          buildInputFeild(FontAwesomeIcons.userTie, context, nickName,
              "Kristen", "NickName"),
          buildInputFeild(FontAwesomeIcons.solidIdBadge, context, aboutMe,
              "I am a developer", "About Me"),
          buildInputFeild(FontAwesomeIcons.solidEnvelope, context, email,
              "iamkristen220@gmail.com", "Email"),
          buildPasswordFeild(
            FontAwesomeIcons.lock,
            context,
            password,
            "*********",
            "Password",
          ),
          buildButton(
            () {
              handleSignUp();
            },
            child: _loading != Loading.initial
                ? _loading == Loading.runnung
                    ? CircularProgressIndicator(
                        color: Theme.of(context).cardColor,
                      )
                    : Icon(
                        Icons.check,
                        size: 40,
                        color: Theme.of(context).cardColor,
                      )
                : Text(
                    "Register",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2!
                        .copyWith(fontSize: 18),
                  ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text.rich(
            TextSpan(
                text: "Already have an account? ",
                style: Theme.of(context)
                    .textTheme
                    .headline2!
                    .copyWith(fontSize: 15),
                children: [
                  TextSpan(
                    text: "SignIn",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        closeKeyboard();
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                  ),
                ]),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(children: [
              const Expanded(
                child: Divider(
                  thickness: .8,
                ),
              ),
              Text(
                " or signIn with ",
                style: Theme.of(context)
                    .textTheme
                    .headline2!
                    .copyWith(fontSize: 14),
              ),
              const Expanded(
                child: Divider(
                  thickness: .8,
                ),
              ),
            ]),
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loginProvider(context, FontAwesomeIcons.google, () async {
                bool isSuccess = await authProvider!.handleSignIn();
                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                }
              })
            ],
          ),
        ]),
      ),
    );
  }

  Container loginProvider(
      BuildContext context, IconData icon, VoidCallback callback) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: ColorConstants.greyColor2),
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(45),
          // shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ]),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 35,
          ),
          onPressed: callback,
        ),
      ),
    );
  }

  void errorSnackbar(String value) {
    SnackBar snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
          ),
          const SizedBox(
            width: 10,
          ),
          Text(value)
        ],
      ),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void successSnackbar(String value) {
    SnackBar snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check,
            color: Colors.white,
          ),
          const SizedBox(
            width: 10,
          ),
          Text(value)
        ],
      ),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
