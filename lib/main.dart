import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/bank_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/shared_fund_provider.dart';

import 'screens/setting/settings_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/login/reset_password_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/transaction/add_transaction_screen.dart';
import 'screens/ai/ai_chat_screen.dart' as ai;
import 'screens/bank/link_bank_screen.dart';
import 'screens/friend/friends_screen.dart';
import 'screens/fund/shared_funds_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Init Supabase với PKCE flow (chuẩn cho mobile).
  /// Deep link `com.example.wallet://login-callback?code=xxx` sẽ được
  /// supabase_flutter tự bắt qua AppLinks và fire `passwordRecovery`
  /// hoặc `signedIn` tương ứng.
  await Supabase.initialize(
    url: 'https://opwcjrmxzovfgqrjfrhg.supabase.co',
    anonKey: 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (ctx) => TransactionProvider()
            ..setNotificationProvider(ctx.read<NotificationProvider>())
            ..setSettingsProvider(ctx.read<SettingsProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => BankProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => SharedFundProvider()),
      ],
      child: const AppView(),
    );
  }
}

/// 🔥 TÁCH RIÊNG để rebuild khi auth thay đổi
class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isPasswordRecovery = false;
  late Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;

    /// 🔥 Lắng nghe auth events
    _authStream.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('[MAIN] auth event=$event, session=${session != null ? "có" : "không"}');

      /// Cập nhật AuthProvider
      final authProvider = context.read<AuthProvider>();
      authProvider.handleAuthStateChange(event, session);

      /// Routing dựa trên event.
      /// 🔥 Dùng pushAndRemoveUntil để XOÁ "Page not found" route mà Flutter
      /// tự đẩy vào khi Android intent-filter forward deep link URL
      /// (`com.example.wallet://login-callback?code=...`) thành initial route.
      if (event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isPasswordRecovery = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
            (route) => false,
          );
        });
      } else if (event == AuthChangeEvent.signedIn) {
        if (_isPasswordRecovery) return; // đang reset password → giữ nguyên
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        });
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => _isPasswordRecovery = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    /// 🔥 Ưu tiên passwordRecovery > session > login
    Widget home;
    if (_isPasswordRecovery) {
      home = const ResetPasswordScreen();
    } else if (session == null) {
      home = const LoginScreen();
    } else {
      home = const MainScreen();
    }

    return MaterialApp(
      title: 'Wallet AI',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      locale: context.watch<SettingsProvider>().locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      /// 🔥 FIX SCALE UI
      builder: (context, child) {
        if (child == null) return const SizedBox();

        final mediaQuery = MediaQuery.of(context);
        final scaleFactor = mediaQuery.textScaleFactor.clamp(0.9, 1.1);

        return MediaQuery(
          data: mediaQuery.copyWith(textScaleFactor: scaleFactor),
          child: child,
        );
      },

      /// ================= THEME =================
      theme: context.watch<SettingsProvider>().themeData,

      /// 🔥 AUTO LOGIN (dynamic)
      home: home,

      /// ================= ROUTES =================
      routes: {
        '/login': (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainScreen(),
        '/ai-chat': (_) => const ai.AIChatScreen(),
        '/add-transaction': (_) => const AddTransactionScreen(),
        '/settings': (_) => const SettingScreen(),
        '/link-bank': (_) => const LinkBankScreen(),
        '/friends': (_) => const FriendsScreen(),
        '/shared-funds': (_) => const SharedFundsScreen(),
      },

      /// 🔥 FALLBACK
      /// Khi Android deep link `com.example.wallet://login-callback?code=...`
      /// mở app, Flutter set initial route là `/login-callback?code=...`. Route
      /// này không tồn tại → rơi vào fallback. Hiện spinner trong lúc
      /// supabase_flutter exchange code (vài chục ms) rồi auth listener sẽ
      /// `pushAndRemoveUntil` sang màn đúng.
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}