import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_calendar_sheet.dart';
import '../../../core/widgets/app_confirmation_sheet.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/saving_goal.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/saving_goal_providers.dart';
import '../utils/saving_goal_ui_helpers.dart';

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
  String? _selectedAccountId;
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
    _selectedAccountId = g?.accountId;
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

  Color _parseHexColor(String hex) => SavingGoalUIHelper.parseColor(hex);

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
          accountId: _selectedAccountId,
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
        }
      } else {
        final updatedGoal = widget.goalToEdit!.copyWith(
          accountId: _selectedAccountId,
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
        }
      }
    } catch (_) {
      // Handled silently consistent with other forms
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await AppConfirmationSheet.show(
      context,
      title: 'Delete Goal',
      message: 'Are you sure you want to delete "${widget.goalToEdit?.name}"? All progress will be permanently lost.',
      confirmLabel: 'Delete Goal',
      icon: Icons.delete_outline_rounded,
    );

    if (confirm == true && widget.goalToEdit != null) {
      setState(() => _isLoading = true);
      try {
        await deleteSavingGoal(ref, widget.goalToEdit!.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (_) {
        // Handled silently consistent with other forms
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accountsAsync = ref.watch(accountsProvider);
    final accountsList = accountsAsync.asData?.value ?? [];
    final isEdit = widget.goalToEdit != null;
    final isIdr = _currency == 'IDR';
    final symbol = isIdr ? 'Rp' : 'RM';

    return Container(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + bottomInset),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: context.cardBorder, width: 1.5),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.4),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
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
              Text(
                'Goal Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Emergency Fund, Trip to Tokyo, New Laptop',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: context.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                      width: 1.2,
                    ),
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
                        Text(
                          'Target Amount',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _targetAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            prefixText: '$symbol ',
                            prefixStyle: TextStyle(color: context.accentLinkColor, fontSize: 14, fontWeight: FontWeight.w700),
                            hintText: '0',
                            hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                            filled: true,
                            fillColor: context.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.isDark ? AppColors.primary : const Color(0xFF15803D), width: 1.2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter target amount';
                            if (CurrencyInputFormatter.parse(v) <= 0) return 'Must be > 0';
                            return null;
                          },
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
                        Text(
                          'Currency',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.cardBorder),
                          ),
                          child: Row(
                            children: [
                              _buildCurrencyTab('IDR', accountsList),
                              _buildCurrencyTab('MYR', accountsList),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Linked Account Dropdown (Filtered by selected currency)
              accountsAsync.when(
                data: (accounts) {
                  final displayAccounts = accounts.where((a) => a.currency == _currency).toList();
                  if (displayAccounts.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppDropdownFormField<String>(
                        key: ValueKey('account_dropdown_${_currency}_$_selectedAccountId'),
                        value: displayAccounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                        labelText: 'Link to Account (Optional)',
                        hintText: 'Select account for auto-sync',
                        sheetTitle: 'Select Linked Account',
                        items: displayAccounts.map((acc) {
                          return AppDropdownItem<String>(
                            value: acc.id,
                            label: '${acc.name} (${acc.currency})',
                            subtitle: 'Type: ${acc.type.toUpperCase()}',
                            icon: Icon(
                              acc.type == 'bank'
                                  ? Icons.account_balance_outlined
                                  : acc.type == 'ewallet'
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.payments_outlined,
                              size: 20,
                              color: context.accentIconColor,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAccountId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Current Saved Balance
              Text(
                'Starting / Current Balance',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _currentAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '$symbol ',
                  prefixStyle: const TextStyle(color: AppColors.teal, fontSize: 14, fontWeight: FontWeight.w700),
                  hintText: '0',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: context.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.cardBorder),
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
              Text(
                'Target Deadline (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 18, color: context.accentIconColor),
                          const SizedBox(width: 10),
                          Text(
                            _targetDate != null
                                ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                : 'Select target date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _targetDate != null ? context.textPrimary : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (_targetDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _targetDate = null),
                          child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, size: 18, color: context.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Icon Selector
              Text(
                'Choose Icon',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
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
                              : context.inputBg,
                          border: Border.all(
                            color: isSelected ? _parseHexColor(_selectedColor) : context.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected
                              ? SavingGoalUIHelper.getContrastColor(_parseHexColor(_selectedColor), context)
                              : context.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Color Accent Selector
              Text(
                'Theme Accent',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
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
                          color: isSelected ? (context.isDark ? Colors.white : Colors.black87) : Colors.transparent,
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
    );
  }

  Widget _buildCurrencyTab(String code, List<dynamic> accounts) {
    final isSelected = _currency == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currency = code;
            final match = accounts.where((a) => a.currency == code).firstOrNull;
            if (match != null) {
              _selectedAccountId = match.id;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            code,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.black : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
