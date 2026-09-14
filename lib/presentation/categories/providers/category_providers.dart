import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/category.dart';
import '../../repository_providers.dart';

part 'category_providers.g.dart';

@riverpod
Future<List<Category>> categories(Ref ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
}

@riverpod
Future<List<Category>> categoriesByType(Ref ref, String type) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getByType(type);
}

Future<void> createCategory(WidgetRef ref, Category category) async {
  final repo = ref.read(categoryRepositoryProvider);
  await repo.create(category);
  ref.invalidate(categoriesProvider);
}
