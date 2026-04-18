class Validators {
  // Email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Email không hợp lệ';
    return null;
  }

  // Password
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  // Confirm password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != password) return 'Mật khẩu không khớp';
    return null;
  }

  // Required
  static String? required(String? value, {String field = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) return '$field không được để trống';
    return null;
  }

  // Amount
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null) return 'Số tiền không hợp lệ';
    if (parsed <= 0) return 'Số tiền phải lớn hơn 0';
    return null;
  }

  // Wallet name
  static String? walletName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên ví';
    if (value.trim().length > 50) return 'Tên ví tối đa 50 ký tự';
    return null;
  }

  // Category name
  static String? categoryName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên danh mục';
    if (value.trim().length > 30) return 'Tên danh mục tối đa 30 ký tự';
    return null;
  }

  // Goal name
  static String? goalName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên mục tiêu';
    if (value.trim().length > 100) return 'Tên mục tiêu tối đa 100 ký tự';
    return null;
  }

  // Target date
  static String? targetDate(DateTime? value) {
    if (value == null) return 'Vui lòng chọn ngày mục tiêu';
    if (value.isBefore(DateTime.now())) return 'Ngày mục tiêu phải trong tương lai';
    return null;
  }

  // Display name
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên hiển thị';
    if (value.trim().length < 2) return 'Tên tối thiểu 2 ký tự';
    if (value.trim().length > 50) return 'Tên tối đa 50 ký tự';
    return null;
  }

  // Phone (Vietnam)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final regex = RegExp(r'^(0|\+84)[0-9]{9}$');
    if (!regex.hasMatch(value.trim())) return 'Số điện thoại không hợp lệ';
    return null;
  }
}
