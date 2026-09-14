import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_payment.dart';
import '../providers/bill_providers.dart';
import '../widgets/pay_bill_dialog.dart';
import 'add_bill_sheet.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final paymentsAsync = ref.watch(currentMonthBillPaymentsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Bills',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => AddBillSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              const SizedBox(height: 18),

              billsAsync.when(
                data: (bills) {
                  if (bills.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No bills registered yet.',
                              style: TextStyle(color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => AddBillSheet.show(context),
                              child: const Text('Create First Bill'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final payments = paymentsAsync.value ?? [];
                  final urgent = bills.first;
                  final others = bills.skip(1).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroBillCard(
                        bill: urgent,
                        payment: payments.where((p) => p.billId == urgent.id).firstOrNull,
                        onPay: () => PayBillDialog.show(context, urgent),
                      ),
                      if (others.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Other Bills',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...others.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BillItemCard(
                                bill: b,
                                payment: payments.where((p) => p.billId == b.id).firstOrNull,
                                onPay: () => PayBillDialog.show(context, b),
                              ),
                            )),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('$e', style: const TextStyle(color: AppColors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBillCard extends StatelessWidget {
  const _HeroBillCard({
    required this.bill,
    required this.payment,
    required this.onPay,
  });

  final Bill bill;
  final BillPayment? payment;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().day;
    final daysLeft = bill.dueDay - today;
    final isPaid = payment?.status == 'paid';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.darkCardBg,
        border: Border.all(
          color: isPaid ? AppColors.darkCardBorder : AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          if (!isPaid)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    bill.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : (daysLeft < 0 ? AppColors.red.withValues(alpha: 0.2) : Colors.black),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPaid
                        ? AppColors.primary
                        : (daysLeft < 0 ? AppColors.red : AppColors.darkCardBorder),
                  ),
                ),
                child: Text(
                  isPaid ? 'PAID' : (daysLeft < 0 ? 'OVERDUE' : 'Due: Day ${bill.dueDay}'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isPaid
                        ? AppColors.primary
                        : (daysLeft < 0 ? AppColors.red : AppColors.darkTextSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${bill.currency} ${_formatNumber(bill.amount)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPaid
                ? 'Paid for this month'
                : (daysLeft >= 0 ? '$daysLeft days left until due date' : 'Overdue by ${daysLeft.abs()} days'),
            style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
          ),
          if (!isPaid) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onPay,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Mark as Paid Now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(num val) {
    return val.toStringAsFixed(0);
  }
}

class _BillItemCard extends StatelessWidget {
  const _BillItemCard({
    required this.bill,
    required this.payment,
    required this.onPay,
  });

  final Bill bill;
  final BillPayment? payment;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final isPaid = payment?.status == 'paid';

    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bill.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Due: Day ${bill.dueDay} \u00b7 ${bill.currency} ${bill.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
              ),
            ],
          ),
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Paid \u2713',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
              ),
            )
          else
            GestureDetector(
              onTap: onPay,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Pay',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
