import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialType == 'income' ? 1 : 0;
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

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIcon = 'restaurant';
    final currentType = _selectedTabIndex == 0 ? 'expense' : 'income';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.darkCardBorder),
          ),
          title: Text(
            'New ${currentType == 'expense' ? 'Expense' : 'Income'} Category',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category Name',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Groceries, Investment',
                  hintStyle: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.darkCardBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.darkCardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.darkCardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Icon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
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
                      onTap: () => setDialogState(() => selectedIcon = item['name'] as String),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? AppColors.primary.withValues(alpha: 0.25) : AppColors.darkCardBg,
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.darkCardBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSel ? AppColors.primaryLight : AppColors.darkTextSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newCat = Category(
                  id: '',
                  name: name,
                  type: currentType,
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
                'Save',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final currentType = _selectedTabIndex == 0 ? 'expense' : 'income';
    final categoriesAsync = ref.watch(categoriesByTypeProvider(currentType));

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.darkCardBg,
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                    const Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddCategoryDialog,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.add_rounded, size: 20, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Switcher (Expense vs Income)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Expense',
                          isActive: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Income',
                          isActive: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Grid / List
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.category_outlined, size: 48, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No $currentType categories found',
                              style: const TextStyle(color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _showAddCategoryDialog,
                              icon: const Icon(Icons.add, color: AppColors.primaryLight),
                              label: const Text('Add Now', style: TextStyle(color: AppColors.primaryLight)),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.3,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return GestureDetector(
                          onTap: () {
                            if (widget.pickerMode && widget.onSelect != null) {
                              widget.onSelect!(cat);
                              Navigator.pop(context);
                            }
                          },
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                  ),
                                  child: Icon(
                                    _getIconData(cat.icon),
                                    size: 18,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.red))),
                ),
              ),
            ],
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
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.black : AppColors.darkTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
