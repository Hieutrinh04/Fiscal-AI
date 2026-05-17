import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = [Locale('vi'), Locale('en')];

  String t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['vi']![key] ?? key;

  // ─── COMMON ──────────────────────────────────────────────────────────────
  String get save => t('save');
  String get cancel => t('cancel');
  String get delete => t('delete');
  String get edit => t('edit');
  String get add => t('add');
  String get close => t('close');
  String get confirm => t('confirm');
  String get yes => t('yes');
  String get no => t('no');
  String get loading => t('loading');
  String get error => t('error');
  String get success => t('success');
  String get income => t('income');
  String get expense => t('expense');
  String get transfer => t('transfer');
  String get all => t('all');
  String get search => t('search');
  String get update => t('update');
  String get viewAll => t('viewAll');
  String get noData => t('noData');
  String get today => t('today');
  String get amount => t('amount');
  String get note => t('note');
  String get date => t('date');
  String get name => t('name');
  String get wallet => t('wallet');

  // ─── NAVIGATION ──────────────────────────────────────────────────────────
  String get navHome => t('navHome');
  String get navWallet => t('navWallet');
  String get navStatistics => t('navStatistics');
  String get navSettings => t('navSettings');

  // ─── HOME ────────────────────────────────────────────────────────────────
  String get hello => t('hello');
  String get currentBalance => t('currentBalance');
  String get quickActions => t('quickActions');
  String get addTransaction => t('addTransaction');
  String get statistics => t('statistics');
  String get goals => t('goals');
  String get aiChat => t('aiChat');
  String get recentTransactions => t('recentTransactions');
  String get sharedFunds => t('sharedFunds');
  String get noTransactions => t('noTransactions');
  String get noFunds => t('noFunds');
  String get aiInsight => t('aiInsight');
  String get aiInsightFallback => t('aiInsightFallback');
  String get noGoalYet => t('noGoalYet');
  String get noFundYet => t('noFundYet');
  String get createGoalNow => t('createGoalNow');
  String get createFundNow => t('createFundNow');
  String get members => t('members');

  // ─── SETTINGS ────────────────────────────────────────────────────────────
  String get settings => t('settings');
  String get account => t('account');
  String get preferences => t('preferences');
  String get other => t('other');
  String get personalInfo => t('personalInfo');
  String get manageWallets => t('manageWallets');
  String get linkBank => t('linkBank');
  String get friends => t('friends');
  String get darkMode => t('darkMode');
  String get darkModeOn => t('darkModeOn');
  String get darkModeOff => t('darkModeOff');
  String get language => t('language');
  String get notifications => t('notifications');
  String get notifSubtitle => t('notifSubtitle');
  String get security => t('security');
  String get securitySubtitle => t('securitySubtitle');
  String get help => t('help');
  String get helpSubtitle => t('helpSubtitle');
  String get about => t('about');
  String get aboutSubtitle => t('aboutSubtitle');
  String get logout => t('logout');
  String get logoutConfirmTitle => t('logoutConfirmTitle');
  String get logoutConfirmMsg => t('logoutConfirmMsg');
  String get editProfile => t('editProfile');
  String get fullName => t('fullName');
  String get phone => t('phone');
  String get saveChanges => t('saveChanges');
  String get manageWalletsSubtitle => t('manageWalletsSubtitle');
  String get linkBankSubtitle => t('linkBankSubtitle');
  String get friendsSubtitle => t('friendsSubtitle');
  String get sharedFundsSubtitle => t('sharedFundsSubtitle');
  String get languageVietnamese => t('languageVietnamese');
  String get languageEnglish => t('languageEnglish');
  String get selectLanguage => t('selectLanguage');

  // ─── AUTH ─────────────────────────────────────────────────────────────────
  String get login => t('login');
  String get register => t('register');
  String get email => t('email');
  String get password => t('password');
  String get confirmPassword => t('confirmPassword');
  String get forgotPassword => t('forgotPassword');
  String get forgotPasswordTitle => t('forgotPasswordTitle');
  String get forgotPasswordSubtitle => t('forgotPasswordSubtitle');
  String get sendResetLink => t('sendResetLink');
  String get resetPassword => t('resetPassword');
  String get setNewPassword => t('setNewPassword');
  String get newPassword => t('newPassword');
  String get confirmNewPassword => t('confirmNewPassword');
  String get loginWithGoogle => t('loginWithGoogle');
  String get alreadyHaveAccount => t('alreadyHaveAccount');
  String get dontHaveAccount => t('dontHaveAccount');
  String get appTagline => t('appTagline');
  String get appTitle => t('appTitle');
  String get enterEmail => t('enterEmail');
  String get enterPassword => t('enterPassword');
  String get enterFullName => t('enterFullName');
  String get enterConfirmPassword => t('enterConfirmPassword');
  String get loginBtn => t('loginBtn');
  String get registerBtn => t('registerBtn');

  // ─── WALLET ──────────────────────────────────────────────────────────────
  String get wallets => t('wallets');
  String get totalBalance => t('totalBalance');
  String get addWallet => t('addWallet');
  String get editWallet => t('editWallet');
  String get deleteWallet => t('deleteWallet');
  String get walletName => t('walletName');
  String get initialBalance => t('initialBalance');
  String get transferMoney => t('transferMoney');
  String get deleteWalletConfirm => t('deleteWalletConfirm');
  String get noWalletYet => t('noWalletYet');
  String get selectWallet => t('selectWallet');
  String get from => t('from');
  String get to => t('to');
  String get selectEmoji => t('selectEmoji');
  String get enterWalletName => t('enterWalletName');
  String get enterAmount => t('enterAmount');
  String get editTransaction => t('editTransaction');
  String get deleteTransaction => t('deleteTransaction');
  String get deleteTransactionConfirm => t('deleteTransactionConfirm');
  String get noTransactionInWallet => t('noTransactionInWallet');
  String get walletType => t('walletType');

  // ─── ADD TRANSACTION ─────────────────────────────────────────────────────
  String get addTransactionTitle => t('addTransactionTitle');
  String get editTransactionTitle => t('editTransactionTitle');
  String get updateExpense => t('updateExpense');
  String get updateIncome => t('updateIncome');
  String get addExpense => t('addExpense');
  String get addIncomeBtn => t('addIncomeBtn');
  String get category => t('category');
  String get selectDate => t('selectDate');
  String get aiSuggestion => t('aiSuggestion');
  String get enterNote => t('enterNote');
  String get enterAmountHint => t('enterAmountHint');

  // ─── STATISTICS ──────────────────────────────────────────────────────────
  String get statisticsTitle => t('statisticsTitle');
  String get weekly => t('weekly');
  String get monthly => t('monthly');
  String get yearly => t('yearly');
  String get noExpenseData => t('noExpenseData');
  String get noIncomeData => t('noIncomeData');
  String get totalExpense => t('totalExpense');
  String get totalIncome => t('totalIncome');
  String get distribution => t('distribution');
  String get period => t('period');
  String get expenseTab => t('expenseTab');
  String get incomeTab => t('incomeTab');
  String get months6 => t('months6');

  // ─── EXPENSE SCREEN ──────────────────────────────────────────────────────
  String get expenseTitle => t('expenseTitle');
  String get noExpenses => t('noExpenses');
  String get noIncomes => t('noIncomes');
  String get expensePie => t('expensePie');
  String get incomePie => t('incomePie');
  String get expense6months => t('expense6months');
  String get income6months => t('income6months');
  String get noTransactionOnDay => t('noTransactionOnDay');

  // ─── GOALS ───────────────────────────────────────────────────────────────
  String get goalsTitle => t('goalsTitle');
  String get addGoal => t('addGoal');
  String get editGoal => t('editGoal');
  String get deleteGoal => t('deleteGoal');
  String get goalName => t('goalName');
  String get targetAmount => t('targetAmount');
  String get monthlyContribution => t('monthlyContribution');
  String get deadline => t('deadline');
  String get financialFreedom => t('financialFreedom');
  String get deposit => t('deposit');
  String get noGoals => t('noGoals');
  String get createGoal => t('createGoal');
  String get saveGoalChanges => t('saveGoalChanges');
  String get goalProgress => t('goalProgress');
  String get depositGoal => t('depositGoal');
  String get depositAmount => t('depositAmount');
  String get deleteGoalConfirm => t('deleteGoalConfirm');
  String get goalNameHint => t('goalNameHint');
  String get targetAmountHint => t('targetAmountHint');
  String get monthlyHint => t('monthlyHint');
  String get deadlineHint => t('deadlineHint');
  String get goalAchieved => t('goalAchieved');

  // ─── AI CHAT ─────────────────────────────────────────────────────────────
  String get aiAssistant => t('aiAssistant');
  String get aiOnline => t('aiOnline');
  String get chatHistory => t('chatHistory');
  String get deleteHistory => t('deleteHistory');
  String get copyChat => t('copyChat');
  String get sendMessage => t('sendMessage');
  String get chatInputHint => t('chatInputHint');
  String get noChatHistory => t('noChatHistory');
  String get chatHistoryTitle => t('chatHistoryTitle');
  String get suggestedQuestions => t('suggestedQuestions');

  // ─── FUND ─────────────────────────────────────────────────────────────────
  String get sharedFund => t('sharedFund');
  String get createFund => t('createFund');
  String get contribute => t('contribute');
  String get fundProgress => t('fundProgress');
  String get fundMembers => t('fundMembers');
  String get fundTarget => t('fundTarget');
  String get fundExceeded => t('fundExceeded');
  String get fundCompleted => t('fundCompleted');
  String get noFundsYet => t('noFundsYet');

  // ─── FRIENDS ─────────────────────────────────────────────────────────────
  String get friendsTitle => t('friendsTitle');
  String get addFriend => t('addFriend');
  String get pending => t('pending');
  String get accepted => t('accepted');
  String get sent => t('sent');
  String get accept => t('accept');
  String get reject => t('reject');
  String get noFriends => t('noFriends');

  // ─── BANK ─────────────────────────────────────────────────────────────────
  String get bankTitle => t('bankTitle');
  String get bankVerified => t('bankVerified');
  String get bankNoTransactions => t('bankNoTransactions');

  // ─── SECURITY ────────────────────────────────────────────────────────────
  String get securityTitle => t('securityTitle');
  String get changePassword => t('changePassword');
  String get twoFactor => t('twoFactor');
  String get currentPassword => t('currentPassword');
  String get newPasswordLabel => t('newPasswordLabel');

  // ─── HELP ────────────────────────────────────────────────────────────────
  String get helpTitle => t('helpTitle');
  String get faq => t('faq');
  String get sendFeedback => t('sendFeedback');
  String get feedbackHint => t('feedbackHint');
  String get sendBtn => t('sendBtn');

  // ─── ABOUT ───────────────────────────────────────────────────────────────
  String get aboutTitle => t('aboutTitle');
  String get appVersion => t('appVersion');
  String get developer => t('developer');
  String get privacyPolicy => t('privacyPolicy');
  String get termsOfService => t('termsOfService');
  String get rateApp => t('rateApp');
  String get shareApp => t('shareApp');

  // ════════════════════════════════════════════════════════════════════════
  // STRING TABLES
  // ════════════════════════════════════════════════════════════════════════
  static const Map<String, Map<String, String>> _strings = {
    // ──────────────────────── VIETNAMESE ─────────────────────────────────
    'vi': {
      // common
      'save': 'Lưu',
      'cancel': 'Hủy',
      'delete': 'Xóa',
      'edit': 'Chỉnh sửa',
      'add': 'Thêm',
      'close': 'Đóng',
      'confirm': 'Xác nhận',
      'yes': 'Có',
      'no': 'Không',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'transfer': 'Chuyển tiền',
      'all': 'Tất cả',
      'search': 'Tìm kiếm',
      'update': 'Cập nhật',
      'viewAll': 'Xem tất cả',
      'noData': 'Chưa có dữ liệu',
      'today': 'Hôm nay',
      'amount': 'Số tiền',
      'note': 'Ghi chú',
      'date': 'Ngày',
      'name': 'Tên',
      'wallet': 'Ví',
      // navigation
      'navHome': 'Trang chủ',
      'navWallet': 'Ví tiền',
      'navStatistics': 'Thống kê',
      'navSettings': 'Cài đặt',
      // home
      'hello': 'Xin chào',
      'currentBalance': 'Số dư hiện tại',
      'quickActions': 'Thao tác nhanh',
      'addTransaction': 'Thêm giao dịch',
      'statistics': 'Thống kê',
      'goals': 'Mục tiêu',
      'aiChat': 'Trợ lý AI',
      'recentTransactions': 'Giao dịch gần đây',
      'sharedFunds': 'Quỹ chung',
      'noTransactions': 'Chưa có giao dịch',
      'noFunds': 'Chưa có quỹ chung',
      'aiInsight': 'AI Insight',
      'aiInsightFallback': 'Hãy tiếp tục ghi lại chi tiêu để AI phân tích và đưa ra gợi ý tài chính phù hợp cho bạn.',
      'noGoalYet': 'Chưa có mục tiêu',
      'noFundYet': 'Chưa có quỹ chung',
      'createGoalNow': 'Tạo mục tiêu ngay →',
      'createFundNow': 'Tạo quỹ ngay →',
      'members': 'thành viên',
      // settings
      'settings': 'Cài đặt',
      'account': 'TÀI KHOẢN',
      'preferences': 'TÙY CHỈNH',
      'other': 'KHÁC',
      'personalInfo': 'Thông tin cá nhân',
      'manageWallets': 'Quản lý ví',
      'linkBank': 'Liên kết ngân hàng',
      'friends': 'Bạn bè',
      'darkMode': 'Chế độ tối',
      'darkModeOn': 'Đang bật',
      'darkModeOff': 'Đang tắt',
      'language': 'Ngôn ngữ',
      'notifications': 'Thông báo',
      'notifSubtitle': 'Thông báo chi tiêu, nhắc nhở',
      'security': 'Bảo mật',
      'securitySubtitle': 'Mật khẩu, xác thực 2 lớp',
      'help': 'Trợ giúp',
      'helpSubtitle': 'FAQ, phản hồi',
      'about': 'Giới thiệu',
      'aboutSubtitle': 'Phiên bản ứng dụng, chính sách',
      'logout': 'Đăng xuất',
      'logoutConfirmTitle': 'Đăng xuất',
      'logoutConfirmMsg': 'Bạn có chắc muốn đăng xuất không?',
      'editProfile': 'Chỉnh sửa hồ sơ',
      'fullName': 'Họ và tên',
      'phone': 'Số điện thoại',
      'saveChanges': 'Lưu thay đổi',
      'manageWalletsSubtitle': 'Tài khoản ngân hàng, ví điện tử',
      'linkBankSubtitle': 'Đồng bộ giao dịch tự động',
      'friendsSubtitle': 'Quản lý bạn bè, chia sẻ quỹ',
      'sharedFundsSubtitle': 'Quỹ nhóm, tiết kiệm cùng nhau',
      'languageVietnamese': 'Tiếng Việt',
      'languageEnglish': 'English',
      'selectLanguage': 'Chọn ngôn ngữ',
      // auth
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'email': 'Email',
      'password': 'Mật khẩu',
      'confirmPassword': 'Xác nhận mật khẩu',
      'forgotPassword': 'Quên mật khẩu?',
      'forgotPasswordTitle': 'Quên mật khẩu',
      'forgotPasswordSubtitle': 'Nhập email để nhận liên kết đặt lại mật khẩu.',
      'sendResetLink': 'Gửi liên kết đặt lại mật khẩu',
      'resetPassword': 'Đặt lại mật khẩu',
      'setNewPassword': 'Đặt mật khẩu mới',
      'newPassword': 'Mật khẩu mới',
      'confirmNewPassword': 'Xác nhận mật khẩu mới',
      'loginWithGoogle': 'Đăng nhập với Google',
      'alreadyHaveAccount': 'Đã có tài khoản? Đăng nhập',
      'dontHaveAccount': 'Chưa có tài khoản? Đăng ký',
      'appTagline': 'Theo dõi chi tiêu, AI phân loại tự động',
      'appTitle': 'Trợ Lý Tài Chính AI Cá Nhân',
      'enterEmail': 'Nhập email của bạn',
      'enterPassword': 'Nhập mật khẩu',
      'enterFullName': 'Nhập họ và tên',
      'enterConfirmPassword': 'Nhập lại mật khẩu',
      'loginBtn': 'Đăng nhập',
      'registerBtn': 'Đăng ký',
      // wallet
      'wallets': 'Ví tiền',
      'totalBalance': 'Tổng số dư',
      'addWallet': 'Thêm ví mới',
      'editWallet': 'Chỉnh sửa ví',
      'deleteWallet': 'Xoá ví',
      'walletName': 'Tên ví',
      'initialBalance': 'Số dư ban đầu',
      'transferMoney': 'Chuyển tiền',
      'deleteWalletConfirm': 'Bạn có chắc muốn xoá ví này không?',
      'noWalletYet': 'Chưa có ví nào',
      'selectWallet': 'Chọn ví',
      'from': 'Từ ví',
      'to': 'Đến ví',
      'selectEmoji': 'Chọn emoji',
      'enterWalletName': 'Nhập tên ví',
      'enterAmount': 'Nhập số tiền',
      'editTransaction': 'Chỉnh sửa giao dịch',
      'deleteTransaction': 'Xoá giao dịch',
      'deleteTransactionConfirm': 'Bạn có chắc muốn xoá giao dịch này?',
      'noTransactionInWallet': 'Chưa có giao dịch',
      'walletType': 'Loại ví',
      // add transaction
      'addTransactionTitle': 'Thêm giao dịch',
      'editTransactionTitle': 'Chỉnh sửa giao dịch',
      'updateExpense': 'Cập nhật chi tiêu',
      'updateIncome': 'Cập nhật thu nhập',
      'addExpense': 'Thêm chi tiêu',
      'addIncomeBtn': 'Thêm thu nhập',
      'category': 'Danh mục',
      'selectDate': 'Chọn ngày',
      'aiSuggestion': 'AI gợi ý',
      'enterNote': 'Nhập ghi chú...',
      'enterAmountHint': 'Nhập số tiền',
      // statistics
      'statisticsTitle': 'Thống kê',
      'weekly': 'Tuần',
      'monthly': 'Tháng',
      'yearly': 'Năm',
      'noExpenseData': 'Chưa có dữ liệu chi tiêu',
      'noIncomeData': 'Chưa có dữ liệu thu nhập',
      'totalExpense': 'Tổng chi',
      'totalIncome': 'Tổng thu',
      'distribution': 'Phân bổ',
      'period': 'Kỳ',
      'expenseTab': 'Chi tiêu',
      'incomeTab': 'Thu nhập',
      'months6': '6 tháng gần nhất',
      // expense screen
      'expenseTitle': 'Thống kê',
      'noExpenses': 'Chưa có chi tiêu nào',
      'noIncomes': 'Chưa có thu nhập nào',
      'expensePie': 'Phân bổ chi tiêu',
      'incomePie': 'Phân bổ thu nhập',
      'expense6months': 'Chi tiêu 6 tháng gần nhất',
      'income6months': 'Thu nhập 6 tháng gần nhất',
      'noTransactionOnDay': 'Không có giao dịch',
      // goals
      'goalsTitle': 'Mục tiêu tài chính',
      'addGoal': 'Thêm mục tiêu mới',
      'editGoal': 'Chỉnh sửa mục tiêu',
      'deleteGoal': 'Xoá mục tiêu',
      'goalName': 'Tên mục tiêu',
      'targetAmount': 'Số tiền mục tiêu',
      'monthlyContribution': 'Tiết kiệm mỗi tháng',
      'deadline': 'Hạn chót',
      'financialFreedom': 'Tiến độ tự do tài chính',
      'deposit': 'Nạp tiền',
      'noGoals': 'Chưa có mục tiêu nào',
      'createGoal': 'Tạo mục tiêu',
      'saveGoalChanges': 'Lưu thay đổi',
      'goalProgress': 'Tiến độ',
      'depositGoal': 'Góp tiền',
      'depositAmount': 'Số tiền góp',
      'deleteGoalConfirm': 'Bạn có chắc muốn xoá mục tiêu này?',
      'goalNameHint': 'Tên mục tiêu (VD: Mua xe)',
      'targetAmountHint': 'Số tiền mục tiêu (₫)',
      'monthlyHint': 'Tiết kiệm mỗi tháng (₫)',
      'deadlineHint': 'Hạn chót (VD: 2026-12-31)',
      'goalAchieved': 'Đã đạt mục tiêu! 🎉',
      // ai chat
      'aiAssistant': 'Fiscal AI',
      'aiOnline': '● Đang hoạt động',
      'chatHistory': 'Lịch sử chat',
      'deleteHistory': 'Xoá lịch sử',
      'copyChat': 'Sao chép nội dung',
      'sendMessage': 'Gửi',
      'chatInputHint': 'Nhập tin nhắn...',
      'noChatHistory': 'Chưa có lịch sử trò chuyện',
      'chatHistoryTitle': 'Lịch sử trò chuyện',
      'suggestedQuestions': 'Câu hỏi gợi ý',
      // fund
      'sharedFund': 'Quỹ chung',
      'createFund': 'Tạo quỹ mới',
      'contribute': 'Góp tiền',
      'fundProgress': 'Tiến độ',
      'fundMembers': 'Thành viên',
      'fundTarget': 'Mục tiêu',
      'fundExceeded': 'Vượt mục tiêu 🎉',
      'fundCompleted': 'Đã hoàn thành',
      'noFundsYet': 'Chưa có quỹ nào',
      // friends
      'friendsTitle': 'Bạn bè',
      'addFriend': 'Thêm bạn',
      'pending': 'Chờ xác nhận',
      'accepted': 'Bạn bè',
      'sent': 'Đã gửi',
      'accept': 'Chấp nhận',
      'reject': 'Từ chối',
      'noFriends': 'Chưa có bạn bè',
      // bank
      'bankTitle': 'Giao dịch ngân hàng',
      'bankVerified': 'Đã xác minh',
      'bankNoTransactions': 'Chưa có giao dịch',
      // security
      'securityTitle': 'Bảo mật',
      'changePassword': 'Đổi mật khẩu',
      'twoFactor': 'Xác thực 2 lớp',
      'currentPassword': 'Mật khẩu hiện tại',
      'newPasswordLabel': 'Mật khẩu mới',
      // help
      'helpTitle': 'Trợ giúp',
      'faq': 'Câu hỏi thường gặp',
      'sendFeedback': 'Gửi phản hồi',
      'feedbackHint': 'Nhập phản hồi của bạn...',
      'sendBtn': 'Gửi phản hồi',
      // about
      'aboutTitle': 'Giới thiệu',
      'appVersion': 'Phiên bản ứng dụng',
      'developer': 'Nhà phát triển',
      'privacyPolicy': 'Chính sách bảo mật',
      'termsOfService': 'Điều khoản dịch vụ',
      'rateApp': 'Đánh giá ứng dụng',
      'shareApp': 'Chia sẻ ứng dụng',
    },

    // ──────────────────────── ENGLISH ─────────────────────────────────────
    'en': {
      // common
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      'all': 'All',
      'search': 'Search',
      'update': 'Update',
      'viewAll': 'View all',
      'noData': 'No data yet',
      'today': 'Today',
      'amount': 'Amount',
      'note': 'Note',
      'date': 'Date',
      'name': 'Name',
      'wallet': 'Wallet',
      // navigation
      'navHome': 'Home',
      'navWallet': 'Wallet',
      'navStatistics': 'Statistics',
      'navSettings': 'Settings',
      // home
      'hello': 'Hello',
      'currentBalance': 'Current Balance',
      'quickActions': 'Quick Actions',
      'addTransaction': 'Add Transaction',
      'statistics': 'Statistics',
      'goals': 'Goals',
      'aiChat': 'AI Assistant',
      'recentTransactions': 'Recent Transactions',
      'sharedFunds': 'Shared Funds',
      'noTransactions': 'No transactions yet',
      'noFunds': 'No shared funds',
      'aiInsight': 'AI Insight',
      'aiInsightFallback': 'Keep recording your expenses so AI can analyze and provide personalized financial suggestions.',
      'noGoalYet': 'No goals yet',
      'noFundYet': 'No shared funds yet',
      'createGoalNow': 'Create a goal now →',
      'createFundNow': 'Create a fund now →',
      'members': 'members',
      // settings
      'settings': 'Settings',
      'account': 'ACCOUNT',
      'preferences': 'PREFERENCES',
      'other': 'OTHER',
      'personalInfo': 'Personal Information',
      'manageWallets': 'Manage Wallets',
      'linkBank': 'Link Bank',
      'friends': 'Friends',
      'darkMode': 'Dark Mode',
      'darkModeOn': 'On',
      'darkModeOff': 'Off',
      'language': 'Language',
      'notifications': 'Notifications',
      'notifSubtitle': 'Expense alerts, reminders',
      'security': 'Security',
      'securitySubtitle': 'Password, two-factor auth',
      'help': 'Help',
      'helpSubtitle': 'FAQ, feedback',
      'about': 'About',
      'aboutSubtitle': 'App version, policies',
      'logout': 'Logout',
      'logoutConfirmTitle': 'Logout',
      'logoutConfirmMsg': 'Are you sure you want to logout?',
      'editProfile': 'Edit Profile',
      'fullName': 'Full Name',
      'phone': 'Phone Number',
      'saveChanges': 'Save Changes',
      'manageWalletsSubtitle': 'Bank accounts, e-wallets',
      'linkBankSubtitle': 'Auto-sync transactions',
      'friendsSubtitle': 'Manage friends, share funds',
      'sharedFundsSubtitle': 'Group funds, save together',
      'languageVietnamese': 'Tiếng Việt',
      'languageEnglish': 'English',
      'selectLanguage': 'Select Language',
      // auth
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot password?',
      'forgotPasswordTitle': 'Forgot Password',
      'forgotPasswordSubtitle': 'Enter your email to receive a password reset link.',
      'sendResetLink': 'Send Reset Link',
      'resetPassword': 'Reset Password',
      'setNewPassword': 'Set New Password',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Confirm New Password',
      'loginWithGoogle': 'Sign in with Google',
      'alreadyHaveAccount': 'Already have an account? Login',
      'dontHaveAccount': "Don't have an account? Register",
      'appTagline': 'Track expenses, AI auto-categorizes',
      'appTitle': 'Personal AI Financial Assistant',
      'enterEmail': 'Enter your email',
      'enterPassword': 'Enter your password',
      'enterFullName': 'Enter your full name',
      'enterConfirmPassword': 'Re-enter password',
      'loginBtn': 'Login',
      'registerBtn': 'Register',
      // wallet
      'wallets': 'Wallets',
      'totalBalance': 'Total Balance',
      'addWallet': 'Add Wallet',
      'editWallet': 'Edit Wallet',
      'deleteWallet': 'Delete Wallet',
      'walletName': 'Wallet Name',
      'initialBalance': 'Initial Balance',
      'transferMoney': 'Transfer Money',
      'deleteWalletConfirm': 'Are you sure you want to delete this wallet?',
      'noWalletYet': 'No wallets yet',
      'selectWallet': 'Select Wallet',
      'from': 'From',
      'to': 'To',
      'selectEmoji': 'Select Emoji',
      'enterWalletName': 'Enter wallet name',
      'enterAmount': 'Enter amount',
      'editTransaction': 'Edit Transaction',
      'deleteTransaction': 'Delete Transaction',
      'deleteTransactionConfirm': 'Are you sure you want to delete this transaction?',
      'noTransactionInWallet': 'No transactions yet',
      'walletType': 'Wallet Type',
      // add transaction
      'addTransactionTitle': 'Add Transaction',
      'editTransactionTitle': 'Edit Transaction',
      'updateExpense': 'Update Expense',
      'updateIncome': 'Update Income',
      'addExpense': 'Add Expense',
      'addIncomeBtn': 'Add Income',
      'category': 'Category',
      'selectDate': 'Select Date',
      'aiSuggestion': 'AI suggestion',
      'enterNote': 'Enter a note...',
      'enterAmountHint': 'Enter amount',
      // statistics
      'statisticsTitle': 'Statistics',
      'weekly': 'Week',
      'monthly': 'Month',
      'yearly': 'Year',
      'noExpenseData': 'No expense data',
      'noIncomeData': 'No income data',
      'totalExpense': 'Total Expense',
      'totalIncome': 'Total Income',
      'distribution': 'Distribution',
      'period': 'Period',
      'expenseTab': 'Expense',
      'incomeTab': 'Income',
      'months6': 'Last 6 months',
      // expense screen
      'expenseTitle': 'Statistics',
      'noExpenses': 'No expenses yet',
      'noIncomes': 'No incomes yet',
      'expensePie': 'Expense Distribution',
      'incomePie': 'Income Distribution',
      'expense6months': 'Expenses last 6 months',
      'income6months': 'Income last 6 months',
      'noTransactionOnDay': 'No transactions',
      // goals
      'goalsTitle': 'Financial Goals',
      'addGoal': 'Add New Goal',
      'editGoal': 'Edit Goal',
      'deleteGoal': 'Delete Goal',
      'goalName': 'Goal Name',
      'targetAmount': 'Target Amount',
      'monthlyContribution': 'Monthly Savings',
      'deadline': 'Deadline',
      'financialFreedom': 'Financial Freedom Progress',
      'deposit': 'Deposit',
      'noGoals': 'No goals yet',
      'createGoal': 'Create Goal',
      'saveGoalChanges': 'Save Changes',
      'goalProgress': 'Progress',
      'depositGoal': 'Contribute',
      'depositAmount': 'Contribution Amount',
      'deleteGoalConfirm': 'Are you sure you want to delete this goal?',
      'goalNameHint': 'Goal name (e.g. Buy a car)',
      'targetAmountHint': 'Target amount (₫)',
      'monthlyHint': 'Monthly savings (₫)',
      'deadlineHint': 'Deadline (e.g. 2026-12-31)',
      'goalAchieved': 'Goal achieved! 🎉',
      // ai chat
      'aiAssistant': 'Fiscal AI',
      'aiOnline': '● Online',
      'chatHistory': 'Chat History',
      'deleteHistory': 'Delete History',
      'copyChat': 'Copy Content',
      'sendMessage': 'Send',
      'chatInputHint': 'Type a message...',
      'noChatHistory': 'No chat history yet',
      'chatHistoryTitle': 'Conversation History',
      'suggestedQuestions': 'Suggested Questions',
      // fund
      'sharedFund': 'Shared Funds',
      'createFund': 'Create Fund',
      'contribute': 'Contribute',
      'fundProgress': 'Progress',
      'fundMembers': 'Members',
      'fundTarget': 'Target',
      'fundExceeded': 'Goal exceeded 🎉',
      'fundCompleted': 'Completed',
      'noFundsYet': 'No funds yet',
      // friends
      'friendsTitle': 'Friends',
      'addFriend': 'Add Friend',
      'pending': 'Pending',
      'accepted': 'Friends',
      'sent': 'Sent',
      'accept': 'Accept',
      'reject': 'Decline',
      'noFriends': 'No friends yet',
      // bank
      'bankTitle': 'Bank Transactions',
      'bankVerified': 'Verified',
      'bankNoTransactions': 'No transactions',
      // security
      'securityTitle': 'Security',
      'changePassword': 'Change Password',
      'twoFactor': 'Two-factor Authentication',
      'currentPassword': 'Current Password',
      'newPasswordLabel': 'New Password',
      // help
      'helpTitle': 'Help',
      'faq': 'Frequently Asked Questions',
      'sendFeedback': 'Send Feedback',
      'feedbackHint': 'Enter your feedback...',
      'sendBtn': 'Send Feedback',
      // about
      'aboutTitle': 'About',
      'appVersion': 'App Version',
      'developer': 'Developer',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'rateApp': 'Rate App',
      'shareApp': 'Share App',
    },
  };
}

// ─── DELEGATE ────────────────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ─── EXTENSION for easy access ────────────────────────────────────────────────
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
