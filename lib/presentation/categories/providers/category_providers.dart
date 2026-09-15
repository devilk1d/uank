import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/category.dart';
import '../../repository_providers.dart';

part 'category_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<Category>> categories(Ref ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
}

@Riverpod(keepAlive: true)
Future<List<Category>> categoriesByType(Ref ref, String type) async {
  final allCategories = await ref.watch(categoriesProvider.future);
  return allCategories.where((c) => c.type == type).toList();
}

Future<Category> createCategory(WidgetRef ref, Category category) async {
  final repo = ref.read(categoryRepositoryProvider);
  final created = await repo.create(category);
  ref.invalidate(categoriesProvider);
  return created;
}

Future<Category> updateCategory(WidgetRef ref, Category category) async {
  final repo = ref.read(categoryRepositoryProvider);
  final updated = await repo.update(category);
  ref.invalidate(categoriesProvider);
  return updated;
}

Future<void> deleteCategory(WidgetRef ref, String id, {String? type}) async {
  final repo = ref.read(categoryRepositoryProvider);
  await repo.delete(id);
  ref.invalidate(categoriesProvider);
}
