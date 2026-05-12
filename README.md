<div align="center">

# 💰 Fiscal AI Wallet

**Ứng dụng quản lý tài chính cá nhân thông minh tích hợp AI**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![ChatGPT AI](https://img.shields.io/badge)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📖 Giới thiệu

**Fiscal AI Wallet** là ứng dụng quản lý tài chính cá nhân được xây dựng bằng Flutter, tích hợp trí tuệ nhân tạo (Google Gemini) để phân tích chi tiêu và đưa ra lời khuyên tài chính cá nhân hóa. Ứng dụng cho phép người dùng theo dõi thu/chi, đặt ngân sách, tạo mục tiêu tiết kiệm, liên kết tài khoản ngân hàng thực tế qua SePay và quản lý quỹ chung nhóm.

---

## ✨ Tính năng chính

| Tính năng | Mô tả |
|-----------|-------|
| 🔐 **Xác thực** | Đăng ký / Đăng nhập bảo mật qua Supabase Auth |
| 👛 **Quản lý Ví** | Tạo nhiều ví, theo dõi số dư, đồng bộ thời gian thực |
| 💳 **Giao dịch** | Ghi chép thu/chi, phân loại danh mục, lọc theo thời gian |
| 📊 **Thống kê** | Biểu đồ chi tiêu theo tuần / tháng / năm với điều hướng kỳ |
| 🎯 **Ngân sách** | Đặt hạn mức chi tiêu theo danh mục, cảnh báo vượt ngưỡng |
| 🏆 **Mục tiêu** | Tạo mục tiêu tiết kiệm, nạp tiền, theo dõi tiến độ |
| 🏦 **Liên kết ngân hàng** | Kết nối tài khoản MSB qua SePay, tự động đồng bộ giao dịch |
| 🤖 **AI Chat** | Trò chuyện với Gemini AI về tài chính, lưu lịch sử hội thoại |
| 💡 **AI Insights** | Tự động phân tích chi tiêu, đưa ra lời khuyên cá nhân hóa |
| 👥 **Quỹ chung** | Tạo quỹ nhóm, mời thành viên, quản lý đóng góp |
| 🔔 **Thông báo** | Cảnh báo số dư thấp, số dư âm, chi tiêu lớn |

---

## 🛠️ Công nghệ sử dụng

### Frontend
- **[Flutter](https://flutter.dev)** – Framework đa nền tảng (Android, iOS, Web)
- **[Provider](https://pub.dev/packages/provider)** – State management
- **[fl_chart](https://pub.dev/packages/fl_chart)** – Biểu đồ cột, pie chart với animation
- **[Google Fonts](https://pub.dev/packages/google_fonts)** – Typography (Inter)
- **[Iconsax](https://pub.dev/packages/iconsax)** – Bộ icon hiện đại

### Backend
- **[Supabase](https://supabase.com)** – PostgreSQL database, Auth, Realtime, Edge Functions
- **Supabase Edge Functions** (Deno/TypeScript) – Webhook xử lý giao dịch ngân hàng

### AI
- **[ChatGPT](https://ai.google.dev)** – Phân tích tài chính và chat AI

### Thanh toán
- **[SePay](https://sepay.vn)** – Cổng kết nối ngân hàng MSB, đồng bộ giao dịch qua VA/QR

---

## 🗂️ Cấu trúc dự án

```
lib/
├── main.dart                  # Entry point
├── models/                    # Data models
│   ├── transaction.dart
│   ├── wallet.dart
│   ├── budget.dart
│   ├── goal.dart
│   ├── shared_fund.dart
│   ├── ai_chat_message.dart
│   └── ...
├── providers/                 # State management (Provider pattern)
│   ├── transaction_provider.dart
│   ├── wallet_provider.dart
│   ├── ai_provider.dart
│   └── ...
├── services/                  # Supabase API calls
│   ├── transaction_service.dart
│   ├── ai_service.dart
│   ├── bank_service.dart
│   └── ...
├── screens/                   # UI Screens
│   ├── home/
│   ├── transaction/
│   ├── statistic/
│   ├── goal/
│   ├── fund/
│   ├── ai/
│   ├── bank/
│   └── ...
├── widgets/                   # Reusable widgets
├── utils/                     # Formatters, helpers
└── theme/                     # App theme

supabase/
└── functions/
    ├── sepay-webhook/         # Nhận webhook từ SePay
    └── sepay-proxy/           # Proxy gọi SePay API
```

---

## 🗄️ Cơ sở dữ liệu

Dự án sử dụng **Supabase (PostgreSQL)** với 13 bảng chính:

```
users            – Người dùng (Supabase Auth)
wallets          – Ví tiền
categories       – Danh mục giao dịch
transactions     – Giao dịch thu/chi
budgets          – Ngân sách theo danh mục
goals            – Mục tiêu tiết kiệm
bank_accounts    – Tài khoản ngân hàng liên kết
notifications    – Thông báo
ai_chat_history  – Lịch sử hội thoại AI
ai_insights      – Lời khuyên tài chính từ AI
shared_funds     – Quỹ chung nhóm
fund_members     – Thành viên quỹ
fund_transactions – Giao dịch trong quỹ
```

> Tất cả bảng đều bật **Row Level Security (RLS)** — mỗi người dùng chỉ truy cập được dữ liệu của chính mình.

Script khởi tạo database: [`supabase_migration.sql`](supabase_migration.sql)

---

## 🚀 Cài đặt và chạy dự án

### Yêu cầu
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Tài khoản [Supabase](https://supabase.com)
- API Key [Google Gemini](https://aistudio.google.com)
- Tài khoản [SePay](https://sepay.vn) *(tùy chọn – để liên kết ngân hàng)*

### 1. Clone repository

```bash
git clone https://github.com/<your-username>/fiscal-ai-wallet.git
cd fiscal-ai-wallet
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Supabase

Tạo file `lib/utils/supabase_config.dart` (hoặc cập nhật trong `main.dart`):

```dart
const supabaseUrl    = 'https://<your-project>.supabase.co';
const supabaseAnonKey = '<your-anon-key>';
```

### 4. Khởi tạo database

Chạy file [`supabase_migration.sql`](supabase_migration.sql) trong **Supabase SQL Editor** để tạo toàn bộ bảng và RLS policies.

### 5. Cấu hình Supabase Secrets

Trong **Supabase Dashboard → Settings → Edge Functions → Secrets**, thêm:

```
GEMINI_API_KEY      = <your-gemini-api-key>
SEPAY_API_KEY       = <your-sepay-api-key>      # Nếu dùng liên kết ngân hàng
SUPABASE_SERVICE_ROLE_KEY = <your-service-role-key>
```

### 6. Deploy Edge Functions

```bash
supabase functions deploy sepay-webhook
supabase functions deploy sepay-proxy
```

### 7. Chạy ứng dụng

```bash
# Mobile
flutter run

# Web
flutter run -d chrome
```

---

## 📱 Screenshots
<img width="566" height="963" alt="image" src="https://github.com/user-attachments/assets/028d2c33-2679-4242-beee-bb15e119e4fa" /> 
<img width="553" height="946" alt="image" src="https://github.com/user-attachments/assets/2e184cb1-8f1a-455b-9bf3-a5ef7d32b097" />
<img width="556" height="948" alt="image" src="https://github.com/user-attachments/assets/9bd838da-bfa5-414d-bf26-9c644a59609d" /> 
<img width="552" height="938" alt="image" src="https://github.com/user-attachments/assets/fab357b4-cc25-454a-9739-91186e2a17ec" />
<img width="542" height="936" alt="image" src="https://github.com/user-attachments/assets/31dd7ccf-f5a1-4d7d-b033-4638002492d7" /> 
<img width="552" height="939" alt="image" src="https://github.com/user-attachments/assets/162d7d7f-2969-4d0d-abf9-e27f18f5e568" />
<img width="557" height="944" alt="image" src="https://github.com/user-attachments/assets/d9efe3b9-b262-45c6-96c9-10c549fc471d" /> 
<img width="551" height="946" alt="image" src="https://github.com/user-attachments/assets/52f50e9c-deab-4fa5-904c-d5591c2d8d69" />
<img width="549" height="950" alt="image" src="https://github.com/user-attachments/assets/8892b73d-0fd3-480e-9e65-13e97acf8bcb" /> 
<img width="547" height="941" alt="image" src="https://github.com/user-attachments/assets/9c7b8f8b-7cae-4018-b484-31e7ec2be845" />
<img width="532" height="934" alt="image" src="https://github.com/user-attachments/assets/4bd455d4-999d-468a-af61-807f01449f76" /> 
<img width="541" height="945" alt="image" src="https://github.com/user-attachments/assets/608b359f-436e-48d0-8fa2-fe0bd5c854bf" />
<img width="541" height="950" alt="image" src="https://github.com/user-attachments/assets/55bda090-b04e-4eb3-b685-67cd4076e67a" /> 
<img width="548" height="940" alt="image" src="https://github.com/user-attachments/assets/39ac1af8-c7a8-4b3d-98bf-b86e5517d117" />
<img width="547" height="947" alt="image" src="https://github.com/user-attachments/assets/e55f5ecd-5824-4cb9-8640-6c839ae66783" />


---

## 📦 Các thư viện chính

| Package | Version | Mục đích |
|---------|---------|----------|
| `supabase_flutter` | ^2.12.2 | Kết nối Supabase |
| `provider` | ^6.1.5 | State management |
| `fl_chart` | ^0.68.0 | Biểu đồ thống kê |
| `google_generative_ai` | ^0.4.7 | Gemini AI API |
| `google_fonts` | ^8.0.2 | Typography |
| `iconsax` | ^0.0.8 | Icon set |
| `intl` | ^0.20.2 | Định dạng số, ngày tháng |
| `shared_preferences` | ^2.5.5 | Lưu cài đặt cục bộ |
| `http` | ^1.2.1 | HTTP requests |
| `uuid` | ^4.5.3 | Tạo UUID |

---

## 🔒 Bảo mật

- Toàn bộ API keys được lưu trong **Supabase Secrets**, không hardcode trong mã nguồn
- **Row Level Security (RLS)** được bật cho tất cả bảng
- `Service Role Key` chỉ được dùng trong Edge Functions, không bao giờ expose phía client
- File `.env` và keys đều được thêm vào `.gitignore`

---

## 🤝 Đóng góp

1. Fork repository
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit: `git commit -m "feat: mô tả thay đổi"`
4. Push: `git push origin feature/ten-tinh-nang`
5. Tạo Pull Request

---

## 📄 License

Dự án này được phân phối theo giấy phép [MIT](LICENSE).

---

<div align="center">
Made with ❤️ using Flutter & Supabase
</div>
