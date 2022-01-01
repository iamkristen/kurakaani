import 'package:flutter/material.dart';
import 'package:kurakaani/constants/color_constants.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;
  toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class Themes {
  static final darkTheme = ThemeData(
    primaryColor: ColorConstants.darkPrimaryColor,
    scaffoldBackgroundColor: ColorConstants.darkScaffoldColor,
    colorScheme: const ColorScheme.dark(),
    appBarTheme: AppBarTheme(backgroundColor: ColorConstants.darkAppBarColor),
    iconTheme: const IconThemeData(color: ColorConstants.darkPrimaryColor),
    textTheme: const TextTheme(
        headline1: TextStyle(color: ColorConstants.darkPrimaryText),
        bodyText2: TextStyle(color: ColorConstants.darkSecondaryText)),
  );
  static final lightTheme = ThemeData(
    primaryColor: ColorConstants.primaryColor,
    scaffoldBackgroundColor: ColorConstants.scaffoldColor,
    colorScheme: const ColorScheme.light(),
    appBarTheme: const AppBarTheme(backgroundColor: ColorConstants.appBarColor),
    iconTheme: const IconThemeData(color: ColorConstants.primaryColor),
    textTheme: const TextTheme(
        headline1: TextStyle(color: ColorConstants.primaryColor),
        bodyText2: TextStyle(color: ColorConstants.secondaryText)),
  );
}
