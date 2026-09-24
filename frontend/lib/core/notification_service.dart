import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String category; // DISPATCH, PLANT, CRON, ALERT
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final ValueNotifier<List<AppNotification>> notificationsNotifier = ValueNotifier<List<AppNotification>>([
    AppNotification(
      id: 'notif-1',
      title: '🚚 New Shift Assignment Dispatched',
      message: 'Vehicle KA-01-EA-1234 assigned to Route North Line A with 3 hospital stops.',
      category: 'DISPATCH',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'notif-2',
      title: '🚨 CPCB 48-Hr Storage Warning',
      message: 'Fortis Hospital waste bags in storage room 4B approaching 48-hour pickup window.',
      category: 'ALERT',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    AppNotification(
      id: 'notif-3',
      title: '🏭 Treatment Plant Gate Ingestion',
      message: 'Truck KA-01-EA-5678 verified at gate. 14 collected bags transferred to PLANT_RECEIVED.',
      category: 'PLANT',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
    ),
    AppNotification(
      id: 'notif-4',
      title: '⏰ 6:00 PM Auto-Disposal Completed',
      message: 'Daily background batch cron job processed 48 plant bags to DISPOSED status.',
      category: 'CRON',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
  ]);

  int get unreadCount => notificationsNotifier.value.where((n) => !n.isRead).length;

  void markAllAsRead() {
    for (final n in notificationsNotifier.value) {
      n.isRead = true;
    }
    notificationsNotifier.value = List.from(notificationsNotifier.value);
  }

  void markAsRead(String id) {
    final index = notificationsNotifier.value.indexWhere((n) => n.id == id);
    if (index != -1) {
      notificationsNotifier.value[index].isRead = true;
      notificationsNotifier.value = List.from(notificationsNotifier.value);
    }
  }

  void clearAll() {
    notificationsNotifier.value = [];
  }
}
