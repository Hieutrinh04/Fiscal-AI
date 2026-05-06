class BankAccount {
  final String id;
  final String userId;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String accountName;
  final bool isVerified;
  final String? walletId;
  final DateTime createdAt;

  BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountName,
    this.isVerified = false,
    this.walletId,
    required this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      userId: json['user_id'],
      bankName: json['bank_name'],
      bankCode: json['bank_code'],
      accountNumber: json['account_number'],
      accountName: json['account_name'],
      isVerified: json['is_verified'] ?? false,
      walletId: json['wallet_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'bank_name': bankName,
        'bank_code': bankCode,
        'account_number': accountNumber,
        'account_name': accountName,
        'is_verified': isVerified,
        'wallet_id': walletId,
      };

  /// Danh sách ngân hàng Việt Nam phổ biến
  static const List<Map<String, String>> vietnamBanks = [
    {'code': 'VCB', 'name': 'Vietcombank'},
    {'code': 'TCB', 'name': 'Techcombank'},
    {'code': 'MB', 'name': 'MB Bank'},
    {'code': 'ACB', 'name': 'ACB'},
    {'code': 'VPB', 'name': 'VPBank'},
    {'code': 'TPB', 'name': 'TPBank'},
    {'code': 'STB', 'name': 'Sacombank'},
    {'code': 'BID', 'name': 'BIDV'},
    {'code': 'CTG', 'name': 'VietinBank'},
    {'code': 'AGR', 'name': 'Agribank'},
    {'code': 'MSB', 'name': 'MSB'},
    {'code': 'SHB', 'name': 'SHB'},
    {'code': 'EIB', 'name': 'Eximbank'},
    {'code': 'HDB', 'name': 'HDBank'},
    {'code': 'OCB', 'name': 'OCB'},
    {'code': 'LPB', 'name': 'LienVietPostBank'},
    {'code': 'NAB', 'name': 'Nam A Bank'},
  ];
}
