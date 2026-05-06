/// Keyword map để gợi ý danh mục instant (offline, không gọi AI).
/// Map từ keyword → tên danh mục (lowercased, không dấu khuyến khích).
/// Dùng khi user gõ mô tả giao dịch.
class CategoryKeywords {
  /// keyword → list tên danh mục có thể match (thứ tự ưu tiên)
  static const Map<String, List<String>> _map = {
    // 🚗 DI CHUYỂN
    'grab': ['di chuyển', 'đi lại', 'giao thông', 'xe'],
    'gojek': ['di chuyển', 'đi lại', 'giao thông'],
    'be': ['di chuyển', 'đi lại', 'giao thông'],
    'xanh sm': ['di chuyển', 'đi lại'],
    'xe ôm': ['di chuyển', 'đi lại', 'giao thông'],
    'taxi': ['di chuyển', 'đi lại', 'giao thông'],
    'xăng': ['di chuyển', 'xăng xe', 'giao thông'],
    'xăng xe': ['di chuyển', 'xăng xe', 'giao thông'],
    'đổ xăng': ['di chuyển', 'xăng xe'],
    'gửi xe': ['di chuyển', 'giao thông'],
    'vé xe': ['di chuyển', 'giao thông'],
    'vé tàu': ['di chuyển', 'du lịch'],
    'máy bay': ['du lịch', 'di chuyển'],
    'vé máy bay': ['du lịch', 'di chuyển'],

    // 🍜 ĂN UỐNG
    'phở': ['ăn uống', 'ăn', 'thực phẩm'],
    'bún': ['ăn uống', 'ăn'],
    'cơm': ['ăn uống', 'ăn'],
    'ăn': ['ăn uống', 'ăn'],
    'ăn sáng': ['ăn uống'],
    'ăn trưa': ['ăn uống'],
    'ăn tối': ['ăn uống'],
    'nhà hàng': ['ăn uống', 'ăn'],
    'quán': ['ăn uống'],
    'cafe': ['ăn uống', 'cà phê', 'giải trí'],
    'cà phê': ['ăn uống', 'cà phê'],
    'trà sữa': ['ăn uống', 'đồ uống'],
    'highland': ['ăn uống', 'cà phê'],
    'starbucks': ['ăn uống', 'cà phê'],
    'phúc long': ['ăn uống', 'cà phê'],
    'kfc': ['ăn uống'],
    'lotteria': ['ăn uống'],
    'mcdonald': ['ăn uống'],
    'pizza': ['ăn uống'],
    'lẩu': ['ăn uống'],
    'nướng': ['ăn uống'],
    'bia': ['ăn uống', 'giải trí'],
    'nhậu': ['ăn uống', 'giải trí'],
    'shopeefood': ['ăn uống'],
    'grabfood': ['ăn uống'],
    'baemin': ['ăn uống'],
    'now': ['ăn uống'],

    // 🛒 MUA SẮM
    'shopee': ['mua sắm', 'shopping'],
    'lazada': ['mua sắm', 'shopping'],
    'tiki': ['mua sắm', 'shopping'],
    'sendo': ['mua sắm', 'shopping'],
    'amazon': ['mua sắm'],
    'quần áo': ['mua sắm', 'thời trang'],
    'giày': ['mua sắm', 'thời trang'],
    'áo': ['mua sắm', 'thời trang'],
    'túi': ['mua sắm', 'thời trang'],
    'mỹ phẩm': ['mua sắm', 'làm đẹp'],
    'son': ['mua sắm', 'làm đẹp'],
    'kem': ['mua sắm', 'làm đẹp'],
    'siêu thị': ['mua sắm', 'thực phẩm', 'nhu yếu phẩm'],
    'vinmart': ['mua sắm', 'thực phẩm'],
    'winmart': ['mua sắm', 'thực phẩm'],
    'coopmart': ['mua sắm', 'thực phẩm'],
    'bách hóa xanh': ['mua sắm', 'thực phẩm'],
    'lotte mart': ['mua sắm'],
    'aeon': ['mua sắm'],
    'mega market': ['mua sắm'],

    // 🏠 NHÀ CỬA / HÓA ĐƠN
    'tiền nhà': ['nhà cửa', 'thuê nhà', 'hóa đơn'],
    'thuê nhà': ['nhà cửa', 'thuê nhà'],
    'tiền trọ': ['nhà cửa', 'thuê nhà'],
    'điện': ['hóa đơn', 'tiền điện', 'nhà cửa'],
    'tiền điện': ['hóa đơn', 'tiền điện'],
    'nước': ['hóa đơn', 'tiền nước', 'nhà cửa'],
    'tiền nước': ['hóa đơn', 'tiền nước'],
    'internet': ['hóa đơn', 'mạng'],
    'wifi': ['hóa đơn', 'mạng'],
    'mạng': ['hóa đơn', 'mạng'],
    'điện thoại': ['hóa đơn', 'mạng'],
    'cước': ['hóa đơn'],

    // 🎮 GIẢI TRÍ
    'netflix': ['giải trí', 'streaming'],
    'spotify': ['giải trí', 'streaming'],
    'youtube': ['giải trí', 'streaming'],
    'game': ['giải trí'],
    'steam': ['giải trí', 'game'],
    'xem phim': ['giải trí'],
    'rạp': ['giải trí'],
    'cgv': ['giải trí'],
    'lotte cinema': ['giải trí'],
    'karaoke': ['giải trí'],
    'du lịch': ['du lịch', 'giải trí'],
    'khách sạn': ['du lịch'],
    'booking': ['du lịch'],
    'airbnb': ['du lịch'],

    // 🏥 SỨC KHỎE
    'thuốc': ['sức khỏe', 'y tế'],
    'bệnh viện': ['sức khỏe', 'y tế'],
    'khám': ['sức khỏe', 'y tế'],
    'nha sĩ': ['sức khỏe', 'y tế'],
    'gym': ['sức khỏe', 'thể thao'],
    'phòng tập': ['sức khỏe', 'thể thao'],
    'yoga': ['sức khỏe', 'thể thao'],
    'massage': ['sức khỏe', 'làm đẹp'],
    'spa': ['làm đẹp', 'sức khỏe'],
    'cắt tóc': ['làm đẹp'],
    'nail': ['làm đẹp'],

    // 🎓 GIÁO DỤC
    'học phí': ['giáo dục', 'học tập'],
    'học': ['giáo dục', 'học tập'],
    'sách': ['giáo dục', 'học tập'],
    'khóa học': ['giáo dục', 'học tập'],
    'udemy': ['giáo dục'],
    'coursera': ['giáo dục'],

    // 💰 THU NHẬP
    'lương': ['lương', 'thu nhập', 'lương thưởng'],
    'thưởng': ['thưởng', 'thu nhập', 'lương thưởng'],
    'thưởng tết': ['thưởng', 'thu nhập'],
    'bonus': ['thưởng', 'thu nhập'],
    'freelance': ['freelance', 'thu nhập phụ', 'thu nhập'],
    'dự án': ['freelance', 'thu nhập phụ'],
    'bán hàng': ['kinh doanh', 'thu nhập'],
    'kinh doanh': ['kinh doanh', 'thu nhập'],
    'đầu tư': ['đầu tư', 'thu nhập'],
    'cổ tức': ['đầu tư', 'thu nhập'],
    'lãi': ['đầu tư', 'tiết kiệm'],
    'tiết kiệm': ['tiết kiệm', 'đầu tư'],
    'quà': ['quà tặng', 'thu nhập khác'],
    'lì xì': ['quà tặng', 'thu nhập khác'],
  };

  /// Tìm tên danh mục gợi ý từ text. Trả về list tên (priority order).
  static List<String> suggest(String text) {
    if (text.trim().isEmpty) return [];
    final lower = _normalize(text);

    // Ưu tiên keyword dài hơn match trước (vd "vé máy bay" > "vé")
    final sortedKeys = _map.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lower.contains(_normalize(key))) {
        return _map[key]!;
      }
    }
    return [];
  }

  /// Chuẩn hóa: lowercase + bỏ dấu tiếng Việt
  static String _normalize(String s) {
    s = s.toLowerCase();
    const from = 'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buffer = StringBuffer();
    for (final c in s.split('')) {
      final idx = from.indexOf(c);
      buffer.write(idx >= 0 ? to[idx] : c);
    }
    return buffer.toString();
  }

  /// Normalize public helper để code khác dùng được
  static String normalize(String s) => _normalize(s);
}
