import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet/main.dart';

void main() {
  testWidgets('App loads Register screen correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WalletApp());

    // Kiểm tra tiêu đề header
    expect(find.text("Trợ Lý Tài Chính AI Cá Nhân"), findsOneWidget);

    // Kiểm tra form register
    expect(find.text("Tạo tài khoản"), findsOneWidget);

    // Kiểm tra input
    expect(find.text("Họ và tên"), findsOneWidget);
    expect(find.text("Email"), findsOneWidget);
    expect(find.text("Mật khẩu"), findsOneWidget);

    // Kiểm tra button đăng ký
    expect(find.text("Đăng ký"), findsOneWidget);
  });
}
