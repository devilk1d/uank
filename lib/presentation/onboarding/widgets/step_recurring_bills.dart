import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/bill.dart';
import '../../repository_providers.dart';

class StepRecurringBills extends ConsumerStatefulWidget {
  const StepRecurringBills({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<StepRecurringBills> createState() => _StepRecurringBillsState();
}

class _StepRecurringBillsState extends ConsumerState<StepRecurringBills> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCurrency = 'IDR';
  int _dueDay = 15;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _quickBills = const [
    {'name': 'Internet & WiFi', 'amount': '350000', 'day': 10, 'currency': 'IDR'},
    {'name': 'Electricity', 'amount': '250000', 'day': 20, 'currency': 'IDR'},
    {'name': 'Streaming Subscription', 'amount': '186000', 'day': 1, 'currency': 'IDR'},
    {'name': 'Housing / Rent', 'amount': '1500000', 'day': 5, 'currency': 'IDR'},
    {'name': 'Mobile Plan (MY)', 'amount': '50', 'day': 15, 'currency': 'MYR'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickBill(Map<String, dynamic> item) {
    final rawAmount = num.tryParse(item['amount'] as String) ?? 0;
    setState(() {
      _nameController.text = item['name'] as String;
      _amountController.text = CurrencyInputFormatter.format(rawAmount);
      _dueDay = item['day'] as int;
      if (item.containsKey('currency')) {
        _selectedCurrency = item['currency'] as String;
      }
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final amount = CurrencyInputFormatter.parse(_amountController.text);

    if (name.isEmpty || amount <= 0) {
      widget.onNext();
      return;
    }

    setState(() => _isSaving = true);
    try {
      final accounts = await ref.read(accountRepositoryProvider).getAll();
      final matchingAccount = accounts.where((a) => a.currency == _selectedCurrency).firstOrNull;
      final primaryAccountId = matchingAccount?.id ?? (accounts.isNotEmpty ? accounts.first.id : null);

      final bill = Bill(
        id: '',
        name: name,
        amount: amount,
        currency: _selectedCurrency,
        dueDay: _dueDay,
        accountId: primaryAccountId,
        reminderDaysBefore: 2,
        isActive: true,
      );

      await ref.read(billRepositoryProvider).create(bill);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4 of 4',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? AppColors.primary : const Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Recurring Bills',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add recurring expenses like utilities, subscriptions, or rent so you never miss a due date.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Quick templates
          Text(
            'Quick Suggestions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickBills.map((item) {
              final isSelected = _nameController.text == item['name'];
              return GestureDetector(
                onTap: () => _applyQuickBill(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                          : cardBorder,
                    ),
                  ),
                  child: Text(
                    item['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Bill form card
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill / Subscription Name',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. WiFi Internet',
                    prefixIcon: Icon(Icons.receipt_long_rounded, color: textSecondary, size: 20),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Amount Input (flex 3)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Amount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 14, right: 8),
                                child: Center(
                                  widthFactor: 0.0,
                                  child: Text(
                                    _selectedCurrency == 'IDR' ? 'Rp' : 'RM',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.primary : const Color(0xFF15803D),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Currency Switcher (flex 2)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currency',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedCurrency = 'IDR'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedCurrency == 'IDR'
                                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'IDR',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedCurrency == 'IDR'
                                              ? (isDark ? Colors.black : Colors.white)
                                              : textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedCurrency = 'MYR'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedCurrency == 'MYR'
                                            ? (isDark ? AppColors.primary : const Color(0xFF15803D))
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'RM',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: _selectedCurrency == 'MYR'
                                              ? (isDark ? Colors.black : Colors.white)
                                              : textSecondary,
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
                const SizedBox(height: 18),

                // Due Day Custom Dropdown
                AppDropdownFormField<int>(
                  value: _dueDay,
                  labelText: 'Due Day of Month',
                  sheetTitle: 'Select Due Date',
                  enableSearch: true,
                  prefixIcon: Icon(Icons.calendar_month_rounded, size: 19, color: textSecondary),
                  items: List.generate(31, (i) => i + 1).map((d) {
                    return AppDropdownItem<int>(
                      value: d,
                      label: 'Day $d of the month',
                      subtitle: 'Repeats monthly on day $d',
                      icon: Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _dueDay = val);
                  },
                ),
              ],
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
                      'Save & Continue',
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
