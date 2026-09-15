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

  Future<Category> create(Category category) async {
    final row = await supabase.from('categories').insert({
      'name': category.name,
      'type': category.type,
      'icon': category.icon,
    }).select().single();
    return Category.fromJson(row);
  }

  Future<Category> update(Category category) async {
    final row = await supabase
        .from('categories')
        .update({
          'name': category.name,
          'type': category.type,
          'icon': category.icon,
        })
        .eq('id', category.id)
        .select()
        .single();
    return Category.fromJson(row);
  }

  Future<void> delete(String id) async {
    // Unlink transactions to avoid foreign key violation
    await supabase.from('transactions').update({'category_id': null}).eq('category_id', id);
    await supabase.from('categories').delete().eq('id', id);
  }
}