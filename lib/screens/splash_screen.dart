import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kurakaani/constants/app_constants.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/screens/home_screen.dart';
import 'package:kurakaani/screens/login_screen.dart';
import 'package:kurakaani/widgets/progress.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      checkSignedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            Images.splash,
            height: MediaQuery.of(context).size.height * 0.5,
          ),
          Text(
            AppConstants.appTitle,
            style: Theme.of(context).textTheme.headline1!.copyWith(
                  fontFamily: 'signatra',
                  letterSpacing: 2.5,
                ),
          ),
          circularProgress(),
        ],
      ),
    );
  }
}
