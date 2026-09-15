import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_calendar_sheet.dart';
import '../../../domain/entities/saving_goal.dart';
import '../providers/saving_goal_providers.dart';

class AddSavingGoalSheet extends ConsumerStatefulWidget {
  final SavingGoal? goalToEdit;

  const AddSavingGoalSheet({super.key, this.goalToEdit});

  static Future<void> show(BuildContext context, {SavingGoal? goalToEdit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSavingGoalSheet(goalToEdit: goalToEdit),
    );
  }

  @override
  ConsumerState<AddSavingGoalSheet> createState() => _AddSavingGoalSheetState();
}

class _AddSavingGoalSheetState extends ConsumerState<AddSavingGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentAmountController;

  late String _currency;
  DateTime? _targetDate;
  late String _selectedIcon;
  late String _selectedColor;
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'savings', 'icon': Icons.savings_rounded},
    {'name': 'flight', 'icon': Icons.flight_takeoff_rounded},
    {'name': 'laptop', 'icon': Icons.laptop_mac_rounded},
    {'name': 'phone', 'icon': Icons.phone_iphone_rounded},
    {'name': 'car', 'icon': Icons.directions_car_rounded},
    {'name': 'home', 'icon': Icons.home_rounded},
    {'name': 'shopping', 'icon': Icons.shopping_bag_rounded},
    {'name': 'school', 'icon': Icons.school_rounded},
    {'name': 'fitness', 'icon': Icons.fitness_center_rounded},
    {'name': 'health', 'icon': Icons.favorite_rounded},
    {'name': 'vacation', 'icon': Icons.beach_access_rounded},
    {'name': 'celebration', 'icon': Icons.celebration_rounded},
  ];

  static const List<String> _availableColors = [
    '#CCFF00', // Lime
    '#14B8A6', // Teal
    '#38BDF8', // Sky Blue
    '#F97316', // Orange
    '#F43F5E', // Rose
    '#A855F7', // Purple
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goalToEdit;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? CurrencyInputFormatter.format(g.targetAmount) : '',
    );
    _currentAmountController = TextEditingController(
      text: g != null ? CurrencyInputFormatter.format(g.currentAmount) : '0',
    );
    _currency = g?.currency ?? 'IDR';
    _selectedIcon = g?.icon ?? 'savings';
    _selectedColor = g?.color ?? '#CCFF00';
    if (g?.targetDate != null && g!.targetDate!.isNotEmpty) {
      _targetDate = DateTime.tryParse(g.targetDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await AppDatePickerSheet.show(
      context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      title: 'Select Target Deadline',
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetAmount = CurrencyInputFormatter.parse(_targetAmountController.text);
    if (targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target amount must be greater than 0')),
      );
      return;
    }

    final currentAmount = CurrencyInputFormatter.parse(_currentAmountController.text);

    setState(() => _isLoading = true);
    try {
      final isCompleted = currentAmount >= targetAmount;
      final targetDateStr = _targetDate != null
          ? '${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}'
          : null;

      if (widget.goalToEdit == null) {
        final newGoal = SavingGoal(
          id: '',
          name: _nameController.text.trim(),
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          currency: _currency,
          targetDate: targetDateStr,
          icon: _selectedIcon,
          color: _selectedColor,
          isCompleted: isCompleted,
        );
        await createSavingGoal(ref, newGoal);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving Goal created successfully!'),
              backgroundColor: AppColors.teal,
            ),
          );
        }
      } else {
        final updatedGoal = widget.goalToEdit!.copyWith(
          name: _nameController.text.trim(),
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          currency: _currency,
          targetDate: targetDateStr,
          icon: _selectedIcon,
          color: _selectedColor,
          isCompleted: isCompleted,
        );
        await updateSavingGoal(ref, updatedGoal);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving Goal updated successfully!'),
              backgroundColor: AppColors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "${widget.goalToEdit?.name}"?',
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.goalToEdit != null) {
      setState(() => _isLoading = true);
      try {
        await deleteSavingGoal(ref, widget.goalToEdit!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted'), backgroundColor: AppColors.darkCardBg),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Color _parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.goalToEdit != null;
    final isIdr = _currency == 'IDR';
    final symbol = isIdr ? 'Rp' : 'RM';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
        decoration: BoxDecoration(
          color: const Color(0xFF141418).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title & Delete button (if edit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Saving Goal' : 'New Saving Goal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                        onPressed: _isLoading ? null : _delete,
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Goal Name
                const Text(
                  'Goal Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'e.g. Emergency Fund, Trip to Tokyo, New Laptop',
                    hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.darkCardBg,
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a goal name' : null,
                ),
                const SizedBox(height: 16),

                // Target Amount & Currency Switcher
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Amount',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _targetAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixText: '$symbol ',
                              prefixStyle: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
                              hintText: '0',
                              hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                              filled: true,
                              fillColor: AppColors.darkCardBg,
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
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter target amount' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Currency',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.darkCardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.darkCardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _currency = 'IDR'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _currency == 'IDR' ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'IDR',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _currency == 'IDR' ? Colors.black : AppColors.darkTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _currency = 'MYR'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _currency == 'MYR' ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'MYR',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _currency == 'MYR' ? Colors.black : AppColors.darkTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Initial / Current Amount
                const Text(
                  'Current Saved Amount (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _currentAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixText: '$symbol ',
                    prefixStyle: const TextStyle(color: AppColors.teal, fontSize: 14, fontWeight: FontWeight.w700),
                    hintText: '0',
                    hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.darkCardBg,
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
                      borderSide: const BorderSide(color: AppColors.teal, width: 1.2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Target Date (Deadline)
                const Text(
                  'Target Deadline (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primaryLight),
                            const SizedBox(width: 10),
                            Text(
                              _targetDate != null
                                  ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                  : 'Select target date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _targetDate != null ? Colors.white : AppColors.darkTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (_targetDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _targetDate = null),
                            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.darkTextSecondary),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.darkTextSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Icon Selector
                const Text(
                  'Choose Icon',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableIcons.map((item) {
                      final isSelected = item['name'] == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = item['name']),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? _parseHexColor(_selectedColor).withValues(alpha: 0.25)
                                : AppColors.darkCardBg,
                            border: Border.all(
                              color: isSelected ? _parseHexColor(_selectedColor) : AppColors.darkCardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 20,
                            color: isSelected ? _parseHexColor(_selectedColor) : AppColors.darkTextSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Color Accent Selector
                const Text(
                  'Theme Accent',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _availableColors.map((hex) {
                    final color = _parseHexColor(hex);
                    final isSelected = hex == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.check_rounded, size: 18, color: Colors.black),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Create Goal',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
