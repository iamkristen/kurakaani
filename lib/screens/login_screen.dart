import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kurakaani/constants/app_constants.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/providers/settings_provider.dart';
import 'package:kurakaani/screens/home_screen.dart';
import 'package:kurakaani/widgets/progress.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
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
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(Images.loginHeader),
          const SizedBox(
            height: 10,
          ),
          GestureDetector(
            onTap: () async {
              bool isSuccess = await authProvider.handleSignIn();
              if (isSuccess) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              height: 50,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    Images.gLogo,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      AppConstants.signInWithGoogle,
                      style: Theme.of(context).textTheme.bodyText2!.copyWith(
                          letterSpacing: 1.3,
                          fontSize: 20,
                          fontFamily: "signatra"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          authProvider.status == Status.authenticating
              ? circularProgress()
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
