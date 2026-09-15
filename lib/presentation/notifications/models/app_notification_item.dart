import 'package:flutter/material.dart';

enum NotificationCategory {
  all,
  bills,
  rates,
  activity,
}

enum NotificationType {
  overdue,
  dueSoon,
  paid,
  rateAlert,
  transferSuccess,
  lowBalance,
  general,
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
      actionIcon: actionIcon ?? this.actionIcon,
      onAction: onAction ?? this.onAction,
    );
  }
}
