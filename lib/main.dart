import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/setting/settings_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/transaction/add_transaction_screen.dart';
import 'screens/ai/ai_chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 INIT SUPABASE
  await Supabase.initialize(
    url: 'https://opwcjrmxzovfgqjrfhrg.supabase.co',
    anonKey: 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt',
  );

  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// 🔥 CHECK SESSION
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Wallet AI',
      debugShowCheckedModeBanner: false,

      /// 🔥 FIX SCALE UI
      builder: (context, child) {
        if (child == null) return const SizedBox();

        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor:
                mediaQuery.textScaleFactor.clamp(0.9, 1.1),
          ),
          child: child,
        );
      },

      /// ================= THEME =================
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2F80ED),
        ),
        scaffoldBackgroundColor: const Color(0xffF3F4F6),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff2F80ED),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff2F80ED),
        ),

        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Colors.white,
          elevation: 8,
        ),
      ),

      /// 🔥 AUTO LOGIN FLOW
      initialRoute: session == null ? '/login' : '/home',

      /// ================= ROUTES =================
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainScreen(),
        '/ai-chat': (_) => const AIChatScreen(),
        '/add-transaction': (_) =>
            const AddTransactionScreen(),
        '/settings': (_) => const SettingScreen(),
      },

      /// 🔥 FALLBACK
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text("Page not found")),
        ),
      ),
    );
  }
}