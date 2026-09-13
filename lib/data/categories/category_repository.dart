import '../../core/config/supabase_client.dart';
import '../../domain/entities/category.dart';

class CategoryRepository {
  Future<List<Category>> getAll() async {
    final rows = await supabase.from('categories').select().order('name');
    return rows.map((row) => Category.fromJson(row)).toList();
  }

  Future<List<Category>> getByType(String type) async {
    final rows = await supabase
        .from('categories')
        .select()
        .eq('type', type)
        .order('name');
    return rows.map((row) => Category.fromJson(row)).toList();
  }

  Future<void> create(Category category) async {
    await supabase.from('categories').insert({
      'name': category.name,
      'type': category.type,
      'icon': category.icon,
    });
  }
}