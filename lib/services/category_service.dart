import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final _client = Supabase.instance.client;

  /// ================= GET ALL =================
  Future<List<Category>> getCategories() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final data = await _client
        .from('categories')
        .select()
        .or('user_id.eq.${user.id},is_system.eq.true')
        .order('name', ascending: true);

    return (data as List)
        .map((e) => Category.fromJson(e))
        .toList();
  }

  /// ================= CREATE =================
  Future<void> createCategory(Category category) async {
    await _client.from('categories').insert(category.toJson());
  }

  /// ================= UPDATE =================
  Future<void> updateCategory(Category category) async {
    await _client
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  /// ================= DELETE =================
  Future<void> deleteCategory(String categoryId) async {
    await _client
        .from('categories')
        .delete()
        .eq('id', categoryId);
  }
}