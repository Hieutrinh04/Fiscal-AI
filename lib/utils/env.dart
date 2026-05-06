class Env {
  // Gemini API
  static const String geminiApiKey = 'AIzaSyDDPBfoMC6Rl64PFwHyMJTWq0UKRKzYAXw';

  // Qwen API (OpenAI Compatible)
  static const String qwenApiKey = '';
  static const String qwenBaseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';

  // Supabase
  static const String supabaseUrl = 'https://opwcjrmxzovfgqrjfrhg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt';

  // SePay API
  // Lấy API key tại: https://my.sepay.vn/userapi
  static const String sepayApiKey = 'J9NLVL8PHZAEPMR1HWQV0UFVS3KNHTIRFX8YJUWGEWXEKECCSXBYFGS73ZIQMWRK';

  // SePay Proxy (Supabase Edge Function - tránh CORS trên web)
  static const String sepayProxyUrl = '$supabaseUrl/functions/v1/sepay-proxy';
}
