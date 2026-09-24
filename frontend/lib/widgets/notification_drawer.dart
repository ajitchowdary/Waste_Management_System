import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/notification_service.dart';
import 'glass_container.dart';

class NotificationDrawer extends StatefulWidget {
  const NotificationDrawer({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NotificationDrawer(),
    );
  }

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  String _selectedCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;

    return ValueListenableBuilder<List<AppNotification>>(
      valueListenable: service.notificationsNotifier,
      builder: (context, notifications, child) {
        final filtered = notifications.where((n) {
          if (_selectedCategory == 'ALL') return true;
          return n.category == _selectedCategory;
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF070B14),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Color(0xFF00F5A0), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Operations Alerts',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        if (service.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F5A0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${service.unreadCount} NEW',
                              style: const TextStyle(color: Color(0xFF070B14), fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: service.markAllAsRead,
                      child: const Text('Mark Read', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 12)),
                    ),
                  ],
                ),
              ),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['ALL', 'DISPATCH', 'ALERT', 'PLANT', 'CRON'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: const Color(0xFF00F5A0),
                        backgroundColor: Colors.white.withOpacity(0.06),
                        labelStyle: TextStyle(
                          color: isSel ? const Color(0xFF070B14) : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onSelected: (val) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10, height: 1),

              // Notification List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No alerts found',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final notif = filtered[index];
                          Color catColor = const Color(0xFF00F5A0);
                          if (notif.category == 'ALERT') catColor = const Color(0xFFEF476F);
                          if (notif.category == 'DISPATCH') catColor = const Color(0xFF00D9F5);
                          if (notif.category == 'CRON') catColor = const Color(0xFFFFD166);

                          return InkWell(
                            onTap: () => service.markAsRead(notif.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: notif.isRead ? Colors.white.withOpacity(0.04) : catColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: notif.isRead ? Colors.white10 : catColor.withOpacity(0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: notif.isRead ? Colors.white70 : Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (!notif.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.65),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('hh:mm a').format(notif.timestamp),
                                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
