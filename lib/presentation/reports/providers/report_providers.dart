import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/reports/report_repository.dart';
import '../../repository_providers.dart';

part 'report_providers.g.dart';

@riverpod
Future<List<MonthlyExpenseCategory>> monthlyExpenses(Ref ref) {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getMonthlyExpenseByCategory();
}
