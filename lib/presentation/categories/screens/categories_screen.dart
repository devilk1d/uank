import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/app_confirmation_sheet.dart';
import '../../../domain/entities/category.dart';
import '../providers/category_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({
    super.key,
    this.pickerMode = false,
    this.initialType = 'expense',
    this.onSelect,
  });

  final bool pickerMode;
  final String initialType;
  final ValueChanged<Category>? onSelect;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late int _selectedTabIndex; // 0: expense, 1: income
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialType == 'income' ? 1 : 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final _iconOptions = const [
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded, 'label': 'Food'},
    {'name': 'directions_car', 'icon': Icons.directions_car_rounded, 'label': 'Transport'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded, 'label': 'Shopping'},
    {'name': 'medical_services', 'icon': Icons.medical_services_rounded, 'label': 'Health'},
    {'name': 'bolt', 'icon': Icons.bolt_rounded, 'label': 'Utilities'},
    {'name': 'movie', 'icon': Icons.movie_rounded, 'label': 'Entertainment'},
    {'name': 'payments', 'icon': Icons.payments_rounded, 'label': 'Salary / Income'},
    {'name': 'card_giftcard', 'icon': Icons.card_giftcard_rounded, 'label': 'Gifts'},
    {'name': 'savings', 'icon': Icons.savings_rounded, 'label': 'Investment'},
    {'name': 'more_horiz', 'icon': Icons.category_rounded, 'label': 'Other'},
  ];

  void _showAddCategorySheet() {
    final nameController = TextEditingController();
    String selectedIcon = 'restaurant';
    String selectedType = _selectedTabIndex == 0 ? 'expense' : 'income';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset + bottomPadding),
            decoration: BoxDecoration(
              color: ctx.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: ctx.cardBorder, width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    'New ${selectedType == 'expense' ? 'Expense' : 'Income'} Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: ctx.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type Switcher (Expense / Income)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ctx.inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ctx.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = 'expense'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'expense' ? AppColors.red : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selectedType == 'expense' ? Colors.white : ctx.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = 'income'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'income' ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selectedType == 'income' ? Colors.black : ctx.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Category Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ctx.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: ctx.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Groceries, Investment',
                      hintStyle: TextStyle(
                        color: ctx.textMuted,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: ctx.inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: ctx.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: ctx.cardBorder),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ctx.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _iconOptions.length,
                      itemBuilder: (_, i) {
                        final item = _iconOptions[i];
                        final isSel = selectedIcon == item['name'];
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedIcon = item['name'] as String),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel
                                  ? (ctx.isDark ? AppColors.primary.withValues(alpha: 0.25) : const Color(0xFF15803D).withValues(alpha: 0.12))
                                  : ctx.inputBg,
                              border: Border.all(
                                color: isSel
                                    ? (ctx.isDark ? AppColors.primary : const Color(0xFF15803D))
                                    : ctx.cardBorder,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSel ? (ctx.isDark ? AppColors.primaryLight : const Color(0xFF15803D)) : ctx.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final newCat = Category(
                          id: '',
                          name: name,
                          type: selectedType,
                          icon: selectedIcon,
                        );

                        final created = await createCategory(ref, newCat);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (widget.pickerMode && widget.onSelect != null && mounted) {
                          widget.onSelect!(created);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Save Category',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryActionSheet(Category category) {
    final isExpense = category.type == 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: ctx.cardBorder, width: 1.5),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Info
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isExpense ? AppColors.red : (ctx.isDark ? AppColors.primary : const Color(0xFF059669))).withValues(alpha: 0.15),
                    border: Border.all(
                      color: (isExpense ? AppColors.red : (ctx.isDark ? AppColors.primary : const Color(0xFF059669))).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _getIconData(category.icon),
                    size: 22,
                    color: isExpense ? AppColors.red : (ctx.isDark ? AppColors.primaryLight : const Color(0xFF059669)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ctx.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpense
                              ? AppColors.red.withValues(alpha: 0.15)
                              : (ctx.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpense ? 'Expense Category' : 'Income Category',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isExpense ? AppColors.red : (ctx.isDark ? AppColors.primary : const Color(0xFF15803D)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

              // Option: Edit Category
              _ActionOptionTile(
                icon: Icons.edit_rounded,
                iconBgColor: (ctx.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
                iconColor: ctx.isDark ? AppColors.primary : const Color(0xFF15803D),
                title: 'Edit Category',
                subtitle: 'Change name, type, or icon',
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditCategorySheet(category);
                },
              ),
              const SizedBox(height: 10),

              // Option: Delete Category
              _ActionOptionTile(
                icon: Icons.delete_outline_rounded,
                iconBgColor: AppColors.red.withValues(alpha: 0.15),
                iconColor: AppColors.red,
                title: 'Delete Category',
                subtitle: 'Permanently remove this category',
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteCategory(category);
                },
              ),
            ],
          ),
        ),
      );
  }

  void _showEditCategorySheet(Category category) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon ?? 'restaurant';
    String selectedType = category.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;

          return Container(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + bottomInset + bottomPadding),
            decoration: BoxDecoration(
              color: ctx.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: ctx.cardBorder, width: 1.5),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with Title & Delete Icon CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: ctx.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteCategory(category);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
                        tooltip: 'Delete Category',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Type Switcher (Expense / Income)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ctx.inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ctx.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = 'expense'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'expense' ? AppColors.red : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selectedType == 'expense' ? Colors.white : ctx.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedType = 'income'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'income' ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selectedType == 'income' ? Colors.black : ctx.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Category Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ctx.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: ctx.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Groceries, Investment',
                      hintStyle: TextStyle(
                        color: ctx.textMuted,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: ctx.inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: ctx.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: ctx.cardBorder),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ctx.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _iconOptions.length,
                      itemBuilder: (_, i) {
                        final item = _iconOptions[i];
                        final isSel = selectedIcon == item['name'];
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedIcon = item['name'] as String),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel
                                  ? (ctx.isDark ? AppColors.primary.withValues(alpha: 0.25) : const Color(0xFF15803D).withValues(alpha: 0.12))
                                  : ctx.inputBg,
                              border: Border.all(
                                color: isSel
                                    ? (ctx.isDark ? AppColors.primary : const Color(0xFF15803D))
                                    : ctx.cardBorder,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSel ? (ctx.isDark ? AppColors.primaryLight : const Color(0xFF15803D)) : ctx.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final updatedCat = category.copyWith(
                          name: name,
                          type: selectedType,
                          icon: selectedIcon,
                        );

                        try {
                          await updateCategory(ref, updatedCat);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Category "${updatedCat.name}" updated'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update category: $e'),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirm = await AppConfirmationSheet.show(
      context,
      title: 'Delete "${category.name}"?',
      message: 'Are you sure you want to delete this category? Any transactions linked to this category will have their category unassigned.',
      confirmLabel: 'Delete Category',
      confirmColor: AppColors.red,
    );

    if (confirm == true && mounted) {
      try {
        await deleteCategory(ref, category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete category: $e'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentType = _selectedTabIndex == 0 ? 'expense' : 'income';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER BAR
                  Padding(
                    padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 20, 16, isDesktop ? 28 : 20, 0),
                    child: isDesktop
                        ? Row(
                            children: [
                              if (Navigator.canPop(context)) ...[
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.cardBg,
                                      border: Border.all(color: context.cardBorder),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 15,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Text(
                                widget.pickerMode ? 'Select Category' : 'Categories',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Live category count pill
                              categoriesAsync.maybeWhen(
                                data: (allCats) {
                                  final count = allCats.where((c) => c.type == currentType).length;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: context.cardBorder),
                                    ),
                                    child: Text(
                                      '$count ${currentType == 'expense' ? 'Expenses' : 'Incomes'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  );
                                },
                                orElse: () => const SizedBox.shrink(),
                              ),
                              const Spacer(),

                              // Search Bar (Desktop)
                              Container(
                                width: 220,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.cardBorder),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(fontSize: 12, color: context.textPrimary),
                                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                  decoration: InputDecoration(
                                    hintText: 'Search categories...',
                                    hintStyle: TextStyle(fontSize: 12, color: context.textMuted),
                                    prefixIcon: Icon(Icons.search_rounded, size: 16, color: context.textMuted),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? GestureDetector(
                                            onTap: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                            child: Icon(Icons.close_rounded, size: 14, color: context.textMuted),
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Compact Segmented Tabs (Desktop)
                              Container(
                                width: 200,
                                height: 38,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _TabButton(
                                        label: 'Expenses',
                                        isActive: _selectedTabIndex == 0,
                                        activeColor: AppColors.red,
                                        onTap: () => setState(() => _selectedTabIndex = 0),
                                      ),
                                    ),
                                    Expanded(
                                      child: _TabButton(
                                        label: 'Income',
                                        isActive: _selectedTabIndex == 1,
                                        activeColor: AppColors.primary,
                                        onTap: () => setState(() => _selectedTabIndex = 1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Add Button (Desktop)
                              GestureDetector(
                                onTap: _showAddCategorySheet,
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 18, color: Colors.black),
                                      SizedBox(width: 6),
                                      Text(
                                        'New Category',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (Navigator.canPop(context)) ...[
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: context.cardBg,
                                              border: Border.all(color: context.cardBorder),
                                            ),
                                            child: Icon(
                                              Icons.arrow_back_ios_new_rounded,
                                              size: 16,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                      ],
                                      Text(
                                        widget.pickerMode ? 'Select Category' : 'Categories',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: _showAddCategorySheet,
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_rounded, size: 18, color: Colors.black),
                                          SizedBox(width: 4),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Mobile Segmented Tabs
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _TabButton(
                                        label: 'Expenses',
                                        isActive: _selectedTabIndex == 0,
                                        activeColor: AppColors.red,
                                        onTap: () => setState(() => _selectedTabIndex = 0),
                                      ),
                                    ),
                                    Expanded(
                                      child: _TabButton(
                                        label: 'Income',
                                        isActive: _selectedTabIndex == 1,
                                        activeColor: AppColors.primary,
                                        onTap: () => setState(() => _selectedTabIndex = 1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),

                  // 2. CATEGORIES GRID
                  Expanded(
                    child: RefreshIndicator(
                      color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                      backgroundColor: context.cardBg,
                      onRefresh: () async => ref.invalidate(categoriesProvider),
                      child: categoriesAsync.when(
                        data: (allCats) {
                          var categories = allCats.where((c) => c.type == currentType).toList();
                          if (_searchQuery.isNotEmpty) {
                            categories = categories
                                .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                .toList();
                          }

                          if (categories.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 80),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.category_outlined, size: 48, color: context.textMuted),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No categories match "$_searchQuery"'
                                            : 'No $currentType categories found',
                                        style: TextStyle(color: context.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: _showAddCategorySheet,
                                        icon: Icon(Icons.add, color: context.accentLinkColor),
                                        label: Text('Add Now', style: TextStyle(color: context.accentLinkColor)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          final crossAxisCount = isDesktop
                              ? (constraints.maxWidth > 1400 ? 5 : (constraints.maxWidth > 1100 ? 4 : 3))
                              : 2;

                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? 28 : 20,
                              12,
                              isDesktop ? 28 : 20,
                              isDesktop ? 48 : 100,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: isDesktop ? 14 : 12,
                              mainAxisSpacing: isDesktop ? 14 : 12,
                              mainAxisExtent: isDesktop ? 76 : null,
                              childAspectRatio: isDesktop ? 3.5 : 2.3,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isExpense = cat.type == 'expense';
                              final tintColor = isExpense
                                  ? AppColors.red
                                  : (context.isDark ? AppColors.primary : const Color(0xFF059669));

                              return GestureDetector(
                                onTap: () {
                                  if (widget.pickerMode && widget.onSelect != null) {
                                    widget.onSelect!(cat);
                                    Navigator.pop(context);
                                  } else {
                                    _showCategoryActionSheet(cat);
                                  }
                                },
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: tintColor.withValues(alpha: 0.14),
                                          border: Border.all(
                                            color: tintColor.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          _getIconData(cat.icon),
                                          size: 19,
                                          color: isExpense
                                              ? AppColors.red
                                              : (context.isDark ? AppColors.primaryLight : const Color(0xFF059669)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isExpense ? 'Expense' : 'Income',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                color: context.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isDesktop && !widget.pickerMode) ...[
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, size: 16, color: context.textMuted),
                                          tooltip: 'Edit',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          onPressed: () => _showEditCategorySheet(cat),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                                          tooltip: 'Delete',
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          onPressed: () => _confirmDeleteCategory(cat),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                          ),
                        ),
                        error: (e, _) => ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Text('$e', style: const TextStyle(color: AppColors.red)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    this.activeColor = AppColors.primary,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? (activeColor == AppColors.red ? Colors.white : Colors.black) : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionOptionTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
