import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/notification_provider.dart';

import 'screens/setting/settings_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/transaction/add_transaction_screen.dart';
import 'screens/ai/ai_chat_screen.dart' as ai;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 INIT SUPABASE
  await Supabase.initialize(
    url: 'https://opwcjrmxzovfgqrjfrhg.supabase.co',
    anonKey: 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt',
  );

  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const AppView(),
    );
  }
}

/// 🔥 TÁCH RIÊNG để rebuild khi auth thay đổi
class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Wallet AI',
      debugShowCheckedModeBanner: false,

      /// 🔥 FIX SCALE UI
      builder: (context, child) {
        if (child == null) return const SizedBox();

        final mediaQuery = MediaQuery.of(context);
        final scaleFactor = mediaQuery.textScaler
            .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: scaleFactor),
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

      /// 🔥 AUTO LOGIN (dynamic)
      home: session == null ? const LoginScreen() : const MainScreen(),

      /// ================= ROUTES =================
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainScreen(),
        '/ai-chat': (_) => const ai.AIChatScreen(),
        '/add-transaction': (_) => const AddTransactionScreen(),
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