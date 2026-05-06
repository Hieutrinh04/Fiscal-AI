import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;
  bool _isLoaded = false;

  bool get notificationEnabled => _notificationEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get isLoaded => _isLoaded;

  /// Load saved settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
    _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  /// Toggle notification
  Future<void> setNotificationEnabled(bool value) async {
    _notificationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', value);
  }

  /// Toggle dark mode
  Future<void> setDarkModeEnabled(bool value) async {
    _darkModeEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', value);
  }

  /// Get current ThemeData
  ThemeData get themeData => _darkModeEnabled ? _darkTheme : _lightTheme;

  static ThemeData get _lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2F80ED)),
        scaffoldBackgroundColor: const Color(0xffF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff2F80ED),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff2F80ED),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Colors.white,
          elevation: 8,
        ),
      );

  static ThemeData get _darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2F80ED),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff16213E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff2F80ED),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xff16213E),
          elevation: 8,
        ),
        cardColor: const Color(0xff16213E),
        dividerColor: Colors.white24,
      );
}
