import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/utils/utilities.dart';
import 'package:provider/provider.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({Key? key}) : super(key: key);

  @override
  _ResetScreenState createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  TextEditingController email = TextEditingController();
  AuthProvider? authProvider;
  bool isLoading = false;
  bool isSuccess = false;

  Widget resetWidget() {
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
                offset: const Offset(0, 10),
              )
            ],
            borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            buildInputFeild(Icons.email_rounded, context, email,
                "iamkristen220@gmail.com", "Email"),
            buildButton(
              () => handleReset(),
              child: isLoading
                  ? CircularProgressIndicator(
                      color: Theme.of(context).cardColor,
                    )
                  : Text(
                      "Send request",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2!
                          .copyWith(fontSize: 18),
                    ),
            ),
          ]),
        ));
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

  Widget successWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          "assets/images/email_verify.svg",
          width: MediaQuery.of(context).size.width * 0.75,
        ),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
              text: "Reset Link has been sent to ",
              style: Theme.of(context).textTheme.headline2!.copyWith(
                    fontSize: 14,
                  ),
              children: [
                TextSpan(
                  text: email.text,
                  style: Theme.of(context)
                      .textTheme
                      .headline2!
                      .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                )
              ]),
        ),
        const SizedBox(
          height: 10,
        ),
        buildButton(() {
          Navigator.pop(context);
        }, child: const Text("Back"))
      ],
    );
  }

  void closeKeyboard() {
    if (Utilities.isKeyboardShowing()) {
      Utilities.closeKeyboard(context);
    }
  }

  handleReset() async {
    closeKeyboard();
    setState(() {
      isLoading = true;
    });
    String res = await authProvider!.resetPassword(email.text);
    if (res == "success") {
      setState(() {
        isLoading = false;
        isSuccess = true;
      });
    } else {
      errorSnackbar(res);
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Reset password",
          style: TextStyle(
              fontSize: 40, fontFamily: 'signatra', letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Center(child: isSuccess ? successWidget() : resetWidget()),
    );
  }
}
