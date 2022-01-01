import 'package:flutter/material.dart';
import 'package:kurakaani/constants/color_constants.dart';
import 'package:kurakaani/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ThemeButton extends StatelessWidget {
  const ThemeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    return Switch.adaptive(
        value: themeProvider.isDarkMode,
        activeColor: Colors.white,
        inactiveThumbColor: ColorConstants.primaryColor,
        inactiveTrackColor: ColorConstants.primaryColor.withOpacity(.3),
        onChanged: (value) {
          final provider = Provider.of<ThemeProvider>(context, listen: false);
          provider.toggleTheme(value);
        });
  }
}
