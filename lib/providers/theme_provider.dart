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
    cardColor: ColorConstants.darkAppBarColor,
    scaffoldBackgroundColor: ColorConstants.darkScaffoldColor,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: ColorConstants.darkPrimaryColor,
      brightness: Brightness.dark,
      secondary: Colors.grey,
      onPrimary: Colors.black,
    ),
    appBarTheme: AppBarTheme(backgroundColor: ColorConstants.darkAppBarColor),
    iconTheme: const IconThemeData(color: ColorConstants.darkPrimaryColor),
    textTheme: const TextTheme(
        headline1: TextStyle(color: ColorConstants.darkPrimaryText),
        bodyText2: TextStyle(color: ColorConstants.darkSecondaryText)),
  );
  static final lightTheme = ThemeData(
    cardColor: Colors.white,
    primaryColor: ColorConstants.primaryColor,
    scaffoldBackgroundColor: ColorConstants.scaffoldColor,
    colorScheme: const ColorScheme.light().copyWith(
      primary: ColorConstants.primaryColor,
      onSecondary: ColorConstants.primaryText,
      brightness: Brightness.light,
      secondary: ColorConstants.greyColor2,
    ),
    splashColor: ColorConstants.primaryColor,
    appBarTheme: const AppBarTheme(backgroundColor: ColorConstants.appBarColor),
    iconTheme: const IconThemeData(color: ColorConstants.primaryColor),
    textTheme: const TextTheme(
        headline1: TextStyle(color: ColorConstants.primaryColor),
        bodyText2: TextStyle(color: ColorConstants.secondaryText)),
  );
}
