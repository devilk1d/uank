import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../domain/entities/category.dart';
import '../../repository_providers.dart';

class StepStarterCategories extends ConsumerStatefulWidget {
  const StepStarterCategories({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<StepStarterCategories> createState() => _StepStarterCategoriesState();
}

class _StepStarterCategoriesState extends ConsumerState<StepStarterCategories> {
  final List<Map<String, dynamic>> _starterCategories = [
    {'name': 'Food & Dining', 'type': 'expense', 'icon': 'restaurant', 'selected': true, 'isCustom': false},
    {'name': 'Transportation', 'type': 'expense', 'icon': 'directions_car', 'selected': true, 'isCustom': false},
    {'name': 'Shopping', 'type': 'expense', 'icon': 'shopping_bag', 'selected': true, 'isCustom': false},
    {'name': 'Utilities & Bills', 'type': 'expense', 'icon': 'bolt', 'selected': true, 'isCustom': false},
    {'name': 'Entertainment', 'type': 'expense', 'icon': 'movie', 'selected': true, 'isCustom': false},
    {'name': 'Healthcare', 'type': 'expense', 'icon': 'medical_services', 'selected': true, 'isCustom': false},
    {'name': 'Groceries', 'type': 'expense', 'icon': 'shopping_basket', 'selected': true, 'isCustom': false},
    {'name': 'Salary', 'type': 'income', 'icon': 'payments', 'selected': true, 'isCustom': false},
    {'name': 'Investments', 'type': 'income', 'icon': 'savings', 'selected': true, 'isCustom': false},
    {'name': 'Freelance', 'type': 'income', 'icon': 'work', 'selected': true, 'isCustom': false},
  ];

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded, 'label': 'Food'},
    {'name': 'directions_car', 'icon': Icons.directions_car_rounded, 'label': 'Transport'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded, 'label': 'Shopping'},
    {'name': 'medical_services', 'icon': Icons.medical_services_rounded, 'label': 'Health'},
    {'name': 'bolt', 'icon': Icons.bolt_rounded, 'label': 'Utilities'},
    {'name': 'movie', 'icon': Icons.movie_rounded, 'label': 'Entertainment'},
    {'name': 'payments', 'icon': Icons.payments_rounded, 'label': 'Salary'},
    {'name': 'savings', 'icon': Icons.savings_rounded, 'label': 'Savings'},
    {'name': 'work', 'icon': Icons.work_rounded, 'label': 'Work'},
    {'name': 'fitness_center', 'icon': Icons.fitness_center_rounded, 'label': 'Fitness'},
    {'name': 'pets', 'icon': Icons.pets_rounded, 'label': 'Pets'},
    {'name': 'local_cafe', 'icon': Icons.local_cafe_rounded, 'label': 'Cafe'},
    {'name': 'school', 'icon': Icons.school_rounded, 'label': 'Education'},
    {'name': 'flight', 'icon': Icons.flight_rounded, 'label': 'Travel'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports_rounded, 'label': 'Gaming'},
    {'name': 'card_giftcard', 'icon': Icons.card_giftcard_rounded, 'label': 'Gifts'},
    {'name': 'home', 'icon': Icons.home_rounded, 'label': 'Home'},
  ];

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
      case 'shopping_basket':
        return Icons.shopping_basket_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'home':
        return Icons.home_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  bool _isSaving = false;

  void _showAddCustomCategorySheet({String defaultType = 'expense'}) {
    final nameController = TextEditingController();
    String selectedIcon = defaultType == 'expense' ? 'restaurant' : 'payments';
    String selectedType = defaultType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;
          final isDark = ctx.isDark;

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
                  Text(
                    'Add Custom Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: ctx.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type Switcher
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
                            onTap: () => setSheetState(() {
                              selectedType = 'expense';
                              if (selectedIcon == 'payments') selectedIcon = 'restaurant';
                            }),
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
                                  style: GoogleFonts.plusJakartaSans(
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
                            onTap: () => setSheetState(() {
                              selectedType = 'income';
                              if (selectedIcon == 'restaurant') selectedIcon = 'payments';
                            }),
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
                                  style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ctx.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.plusJakartaSans(
                      color: ctx.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Subscriptions, Pet Care, Freelance',
                      hintStyle: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ctx.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    width: double.maxFinite,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
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
                                  ? (isDark ? AppColors.primary.withValues(alpha: 0.25) : const Color(0xFF15803D).withValues(alpha: 0.12))
                                  : ctx.inputBg,
                              border: Border.all(
                                color: isSel
                                    ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                    : ctx.cardBorder,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSel ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D)) : ctx.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

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
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        setState(() {
                          _starterCategories.add({
                            'name': name,
                            'type': selectedType,
                            'icon': selectedIcon,
                            'selected': true,
                            'isCustom': true,
                          });
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Add Category',
                        style: GoogleFonts.plusJakartaSans(
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

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final selectedList = _starterCategories.where((c) => c['selected'] == true).toList();

      for (final item in selectedList) {
        await categoryRepo.create(
          Category(
            id: '',
            name: item['name'] as String,
            type: item['type'] as String,
            icon: item['icon'] as String,
          ),
        );
      }
      widget.onNext();
    } catch (_) {
      widget.onNext();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final cardBorder = context.cardBorder;

    final expenses = _starterCategories.where((c) => c['type'] == 'expense').toList();
    final incomes = _starterCategories.where((c) => c['type'] == 'income').toList();
    final totalSelected = _starterCategories.where((c) => c['selected'] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3 of 4',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? AppColors.primary : const Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Starter Categories',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the standard income and expense categories you would like to track, or add your own custom categories.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Expenses Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXPENSE CATEGORIES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddCustomCategorySheet(defaultType: 'expense'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Custom',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expenses.map((cat) {
                final isSelected = cat['selected'] as bool;
                final isCustom = cat['isCustom'] == true;
                return GestureDetector(
                  onTap: () {
                    setState(() => cat['selected'] = !isSelected);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF15803D).withValues(alpha: 0.12))
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                            : cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isSelected
                              ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _getIconData(cat['icon'] as String?),
                          size: 15,
                          color: isSelected
                              ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                                : textPrimary,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _starterCategories.remove(cat);
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Income Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INCOME CATEGORIES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => _showAddCustomCategorySheet(defaultType: 'income'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Custom',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: incomes.map((cat) {
                final isSelected = cat['selected'] as bool;
                final isCustom = cat['isCustom'] == true;
                return GestureDetector(
                  onTap: () {
                    setState(() => cat['selected'] = !isSelected);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF15803D).withValues(alpha: 0.12))
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                            : cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isSelected
                              ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _getIconData(cat['icon'] as String?),
                          size: 15,
                          color: isSelected
                              ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                                : textPrimary,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _starterCategories.remove(cat);
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 36),

          // Actions
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      totalSelected > 0 ? 'Apply $totalSelected Categories' : 'Continue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Skip for now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
