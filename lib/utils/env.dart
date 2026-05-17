class Env {
  // Gemini API
  // Lấy key tại: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyC0u7sXBpYEnLyTEWt_GOaIdV8YESo-F_s';

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
