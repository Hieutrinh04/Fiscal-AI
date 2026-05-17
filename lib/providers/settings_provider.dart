import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;
  bool _isLoaded = false;
  Locale _locale = const Locale('vi');

  bool get notificationEnabled => _notificationEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get isLoaded => _isLoaded;
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  /// Load saved settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
    _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    final savedLang = prefs.getString('language_code') ?? 'vi';
    _locale = Locale(savedLang);
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

  /// Change language
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
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
          surface: const Color(0xff1E2A3A),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xff131C2B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff1A2438),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff2F80ED),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xff1A2438),
          elevation: 8,
        ),
        cardColor: const Color(0xff1E2A3A),
        dividerColor: Colors.white12,
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Color(0xff2F80ED),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xff2F80ED)
                : Colors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xff2F80ED).withValues(alpha: 0.4)
                : Colors.white12,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: Color(0xff1E2A3A),
          labelStyle: TextStyle(color: Color(0xff8A9BC0)),
          hintStyle: TextStyle(color: Color(0xff8A9BC0)),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xff1E2A3A),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xff1E2A3A),
        ),
      );
}
