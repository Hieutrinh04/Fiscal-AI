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

import 'package:flutter/foundation.dart' show kIsWeb;

/// 🔥 Flag: password recovery detected từ URL fragment
bool _isPasswordRecoveryStartup = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 BƯỚC 1: Check URL TRƯỚC khi Supabase xử lý
  /// Implicit flow: URL sẽ là http://localhost:3000#access_token=xxx&type=recovery
  /// Supabase.initialize() sẽ đọc fragment, tạo session, rồi xóa fragment khỏi URL
  /// Nên phải kiểm tra ở đây TRƯỚC
  if (kIsWeb) {
    final fragment = Uri.base.fragment;
    debugPrint('[MAIN] URL=${Uri.base}');
    debugPrint('[MAIN] Fragment=$fragment');
    if (fragment.contains('type=recovery')) {
      _isPasswordRecoveryStartup = true;
      debugPrint('[MAIN] ✅ Password recovery detected from URL fragment!');
    }
  }

  /// 🔥 BƯỚC 2: INIT SUPABASE với IMPLICIT flow
  /// Implicit flow cho phép nhận passwordRecovery event từ URL fragment
  /// (PKCE flow chỉ fire signedIn, KHÔNG fire passwordRecovery)
  await Supabase.initialize(
    url: 'https://opwcjrmxzovfgqrjfrhg.supabase.co',
    anonKey: 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
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

    /// 🔥 Cold start: kiểm tra flag từ main() (URL fragment chứa type=recovery)
    if (_isPasswordRecoveryStartup) {
      _isPasswordRecovery = true;
      debugPrint('[MAIN] Cold start → hiện ResetPasswordScreen');
    }

    _authStream = Supabase.instance.client.auth.onAuthStateChange;

    /// 🔥 Lắng nghe auth events
    _authStream.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('[MAIN] auth event=$event, session=${session != null ? "có" : "không"}');

      /// Cập nhật AuthProvider
      final authProvider = context.read<AuthProvider>();
      authProvider.handleAuthStateChange(event, session);

      /// Routing dựa trên event
      if (event == AuthChangeEvent.passwordRecovery) {
        /// 🔥 Implicit flow: Supabase fire passwordRecovery từ URL fragment
        setState(() => _isPasswordRecovery = true);
      } else if (event == AuthChangeEvent.signedIn) {
        if (!_isPasswordRecovery) {
          /// OAuth / đăng nhập thường → rebuild để chuyển sang home
          setState(() {});
        }
        /// Nếu _isPasswordRecovery = true → giữ nguyên ResetPasswordScreen
      } else if (event == AuthChangeEvent.signedOut) {
        /// 🔥 setState rebuild → build() thấy session == null → hiện LoginScreen
        /// Dùng pushAndRemoveUntil để xóa hết stack (dialog, screen cũ)
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
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text("Page not found")),
        ),
      ),
    );
  }
}