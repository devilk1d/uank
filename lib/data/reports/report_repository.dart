import '../../core/config/supabase_client.dart';

class MonthlyExpenseCategory {
  final String categoryName;
  final num totalIdr;

  MonthlyExpenseCategory({
    required this.categoryName,
    required this.totalIdr,
  });

  factory MonthlyExpenseCategory.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseCategory(
      categoryName: json['category_name'] as String? ?? 'Lainnya',
      totalIdr: json['total_idr'] as num? ?? 0,
    );
  }
}

class ReportRepository {
  /// Query VIEW `monthly_expense_by_category`
  Future<List<MonthlyExpenseCategory>> getMonthlyExpenseByCategory({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1).toIso8601String().split('T').first;

    final rows = await supabase
        .from('monthly_expense_by_category')
        .select()
        .gte('month', firstDay)
        .order('total_idr', ascending: false);

    return rows.map((r) => MonthlyExpenseCategory.fromJson(r)).toList();
  }
}
