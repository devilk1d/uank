import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../bills/providers/bill_providers.dart';
import '../../bills/widgets/pay_bill_dialog.dart';
import '../../exchange_rates/screens/exchange_rate_screen.dart';
import '../../shell/main_shell.dart';
import '../../transfers/screens/add_transfer_sheet.dart';
import '../models/app_notification_item.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotifications = ref.watch(notificationsProvider);
    final selectedCategory = ref.watch(selectedNotificationCategoryProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final filteredList = selectedCategory == NotificationCategory.all
        ? allNotifications
        : allNotifications.where((n) => n.category == selectedCategory).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // 1. Header (Back Button, Title & Mark Read)
              _buildHeader(context, ref, unreadCount, allNotifications),
              const SizedBox(height: 18),

              // 2. Filter Pills (All / Bills / Forex Rates / Activity)
              _buildFilterChips(ref, selectedCategory, allNotifications),
              const SizedBox(height: 16),

              // 3. Notification List
              if (filteredList.isEmpty)
                _buildEmptyState()
              else
                ...filteredList.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationCard(item: item),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    int unreadCount,
    List<AppNotificationItem> allItems,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkCardBg,
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),

        // Mark All Read Button
        if (allItems.isNotEmpty && unreadCount > 0)
          GestureDetector(
            onTap: () {
              ref.read(readNotificationIdsProvider.notifier).markAllAsRead(
                    allItems.map((i) => i.id).toList(),
                  );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.done_all_rounded, size: 15, color: AppColors.primaryLight),
                  SizedBox(width: 5),
                  Text(
                    'Mark read',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips(
    WidgetRef ref,
    NotificationCategory selected,
    List<AppNotificationItem> allItems,
  ) {
    final filters = [
      (NotificationCategory.all, 'All'),
      (NotificationCategory.bills, 'Bills'),
      (NotificationCategory.rates, 'Rates'),
      (NotificationCategory.activity, 'Activity'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((cat) {
          final isSelected = selected == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedNotificationCategoryProvider.notifier).select(cat.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.darkCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.darkCardBorder,
                  ),
                ),
                child: Text(
                  cat.$2,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkCardBg,
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: AppColors.darkTextMuted,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You have caught up with all updates',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});

  final AppNotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = _getTypeStyle(item.type);

    return GestureDetector(
      onTap: () {
        ref.read(readNotificationIdsProvider.notifier).markAsRead(item.id);
        _handleAction(context, ref);
      },
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Circle Icon Container (Matching Transaction & Transfer tiles)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.color.withValues(alpha: 0.15),
                border: Border.all(color: style.color.withValues(alpha: 0.3)),
              ),
              child: Icon(style.icon, size: 20, color: style.color),
            ),
            const SizedBox(width: 14),

            // Middle Description Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Relative Time
            Text(
              _formatRelativeTime(item.timestamp),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref) {
    if (item.type == NotificationType.overdue || item.type == NotificationType.dueSoon) {
      final bills = ref.read(billsProvider).asData?.value ?? [];
      final bill = bills.where((b) => item.id.contains(b.id)).firstOrNull;
      if (bill != null) {
        PayBillDialog.show(context, bill, periodMonth: DateTime.now());
      } else {
        Navigator.pop(context);
        ref.read(bottomNavIndexProvider.notifier).setIndex(3);
      }
    } else if (item.type == NotificationType.paid) {
      Navigator.pop(context);
      ref.read(bottomNavIndexProvider.notifier).setIndex(3);
    } else if (item.type == NotificationType.rateAlert) {
      ExchangeRateScreen.show(context);
    } else if (item.type == NotificationType.transferSuccess) {
      Navigator.pop(context);
      ref.read(bottomNavIndexProvider.notifier).setIndex(1);
    } else if (item.type == NotificationType.lowBalance) {
      AddTransferSheet.show(context);
    }
  }

  _TypeStyle _getTypeStyle(NotificationType type) {
    switch (type) {
      case NotificationType.overdue:
        return const _TypeStyle(icon: Icons.error_outline_rounded, color: AppColors.red);
      case NotificationType.dueSoon:
        return const _TypeStyle(icon: Icons.notifications_active_rounded, color: AppColors.orange);
      case NotificationType.paid:
        return const _TypeStyle(icon: Icons.check_circle_outline_rounded, color: AppColors.green);
      case NotificationType.rateAlert:
        return const _TypeStyle(icon: Icons.currency_exchange_rounded, color: AppColors.primaryLight);
      case NotificationType.transferSuccess:
        return const _TypeStyle(icon: Icons.swap_horiz_rounded, color: AppColors.teal);
      case NotificationType.lowBalance:
        return const _TypeStyle(icon: Icons.account_balance_wallet_outlined, color: AppColors.orange);
      case NotificationType.general:
        return const _TypeStyle(icon: Icons.info_outline_rounded, color: AppColors.primaryLight);
    }
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m';
    } else if (diff.inHours < 24 && now.day == time.day) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 2 || (now.day - time.day == 1 && diff.inDays < 3)) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

class _TypeStyle {
  final IconData icon;
  final Color color;

  const _TypeStyle({required this.icon, required this.color});
}
