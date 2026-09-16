import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/providers/account_providers.dart';
import '../../bills/providers/bill_providers.dart';
import '../../exchange_rates/providers/exchange_rate_providers.dart';
import '../../transfers/providers/transfer_providers.dart';
import '../models/app_notification_item.dart';

class ReadNotificationIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markAsRead(String id) {
    state = {...state, id};
  }

  void markAllAsRead(List<String> ids) {
    state = {...state, ...ids};
  }

  void clearRead() {
    state = {};
  }
}

final readNotificationIdsProvider =
    NotifierProvider<ReadNotificationIdsNotifier, Set<String>>(
  ReadNotificationIdsNotifier.new,
);

class SelectedNotificationCategoryNotifier extends Notifier<NotificationCategory> {
  @override
  NotificationCategory build() => NotificationCategory.all;

  void select(NotificationCategory category) => state = category;
}

final selectedNotificationCategoryProvider =
    NotifierProvider<SelectedNotificationCategoryNotifier, NotificationCategory>(
  SelectedNotificationCategoryNotifier.new,
);

final notificationsProvider = Provider<List<AppNotificationItem>>((ref) {
  final bills = ref.watch(billsProvider).asData?.value ?? [];
  final payments = ref.watch(currentMonthBillPaymentsProvider).asData?.value ?? [];
  final transfers = ref.watch(transfersProvider).asData?.value ?? [];
  final balances = ref.watch(accountBalancesProvider).asData?.value ?? [];
  final myrRate = ref.watch(latestRateProvider(fromCurrency: 'MYR', toCurrency: 'IDR')).asData?.value;
  final readIds = ref.watch(readNotificationIdsProvider);

  final List<AppNotificationItem> items = [];
  final now = DateTime.now();
  final currentDay = now.day;
  final paymentMap = {for (final p in payments) p.billId: p};

  // 1. BILLS NOTIFICATIONS
  for (final bill in bills.where((b) => b.isActive)) {
    final payment = paymentMap[bill.id];
    final isPaid = payment?.status == 'paid';
    final amountStr = bill.currency == 'MYR'
        ? 'RM ${_formatNum(bill.amount)}'
        : 'Rp ${_formatNum(bill.amount)}';

    if (isPaid) {
      final paidDate = payment?.paidDate ?? now;
      items.add(AppNotificationItem(
        id: 'bill_paid_${bill.id}_${now.month}_${now.year}',
        title: 'Tagihan Lunas: ${bill.name}',
        message: 'Tagihan $amountStr untuk bulan ini telah berhasil dibayar.',
        category: NotificationCategory.bills,
        type: NotificationType.paid,
        timestamp: DateTime(paidDate.year, paidDate.month, paidDate.day, 10, 0),
        isRead: readIds.contains('bill_paid_${bill.id}_${now.month}_${now.year}'),
        actionLabel: 'Lihat Tagihan',
      ));
    } else {
      final dueDay = bill.dueDay;
      final daysDiff = dueDay - currentDay;

      if (daysDiff < 0) {
        // Overdue
        final daysOverdue = currentDay - dueDay;
        items.add(AppNotificationItem(
          id: 'bill_overdue_${bill.id}_${now.month}_${now.year}',
          title: '⚠️ Tagihan Terlewat: ${bill.name}',
          message: 'Tagihan $amountStr telah melewati jatuh tempo $daysOverdue hari yang lalu (Tanggal $dueDay).',
          category: NotificationCategory.bills,
          type: NotificationType.overdue,
          timestamp: now.subtract(Duration(hours: 1)),
          isRead: readIds.contains('bill_overdue_${bill.id}_${now.month}_${now.year}'),
          actionLabel: 'Bayar Sekarang',
        ));
      } else if (daysDiff <= bill.reminderDaysBefore) {
        // Due soon
        final dueText = daysDiff == 0
            ? 'hari ini'
            : (daysDiff == 1 ? 'besok' : '$daysDiff hari lagi (Tanggal $dueDay)');

        items.add(AppNotificationItem(
          id: 'bill_due_${bill.id}_${now.month}_${now.year}',
          title: '🔔 Pengingat Tagihan: ${bill.name}',
          message: 'Tagihan sebesar $amountStr akan jatuh tempo $dueText.',
          category: NotificationCategory.bills,
          type: NotificationType.dueSoon,
          timestamp: now.subtract(const Duration(minutes: 30)),
          isRead: readIds.contains('bill_due_${bill.id}_${now.month}_${now.year}'),
          actionLabel: 'Bayar Sekarang',
        ));
      }
    }
  }

  // 2. EXCHANGE RATES NOTIFICATION
  if (myrRate != null) {
    final rateStr = _formatNum(myrRate.rate);
    items.add(AppNotificationItem(
      id: 'rate_update_${now.day}_${now.month}_${now.year}',
      title: '💱 Kurs Live Hari Ini (MYR ➔ IDR)',
      message: '1 MYR saat ini setara dengan Rp $rateStr (Update live pasar valas).',
      category: NotificationCategory.rates,
      type: NotificationType.rateAlert,
      timestamp: myrRate.fetchedAt,
      isRead: readIds.contains('rate_update_${now.day}_${now.month}_${now.year}'),
      actionLabel: 'Buka Kalkulator Kurs',
    ));
  }

  // 3. RECENT TRANSFERS ACTIVITY
  for (final transfer in transfers.take(5)) {
    final tDate = transfer.transferDate;
    final diffDays = now.difference(tDate).inDays;
    if (diffDays <= 7) {
      items.add(AppNotificationItem(
        id: 'transfer_${transfer.id}',
        title: '🔄 Log Transfer Berhasil',
        message: 'Transfer dana selesai dicatat pada tanggal ${tDate.day}/${tDate.month}/${tDate.year}.',
        category: NotificationCategory.activity,
        type: NotificationType.transferSuccess,
        timestamp: DateTime(tDate.year, tDate.month, tDate.day, 14, 30),
        isRead: readIds.contains('transfer_${transfer.id}'),
        actionLabel: 'Lihat Transaksi',
      ));
    }
  }

  // 4. LOW BALANCE ALERTS
  for (final balance in balances) {
    final isLow = (balance.currency == 'MYR' && balance.balance > 0 && balance.balance < 50) ||
        (balance.currency == 'IDR' && balance.balance > 0 && balance.balance < 100000);

    if (isLow) {
      final balStr = balance.currency == 'MYR'
          ? 'RM ${_formatNum(balance.balance)}'
          : 'Rp ${_formatNum(balance.balance)}';

      items.add(AppNotificationItem(
        id: 'low_balance_${balance.accountId}',
        title: '💳 Saldo Akun Menipis: ${balance.name}',
        message: 'Saldo ${balance.name} tersisa $balStr. Pertimbangkan untuk melakukan top-up atau transfer.',
        category: NotificationCategory.activity,
        type: NotificationType.lowBalance,
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: readIds.contains('low_balance_${balance.accountId}'),
        actionLabel: 'Top Up / Transfer',
      ));
    }
  }

  // Sort descending by timestamp
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider);
  return items.where((i) => !i.isRead).length;
});

String _formatNum(num val) {
  final s = val.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
