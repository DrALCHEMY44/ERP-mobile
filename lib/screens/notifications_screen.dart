import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/erp_provider.dart';
import '../widgets/app_drawer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erp = Provider.of<ErpProvider>(context);
    final notificationsList = erp.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (erp.unreadNotifications.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                erp.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.'), behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark All Read', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/notifications'),
      body: notificationsList.isEmpty
          ? const Center(
              child: Text('No notifications received yet.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationsList.length,
              itemBuilder: (context, index) {
                final notif = notificationsList[index];
                
                IconData leadingIcon = Icons.info_outline;
                Color notifColor = Colors.blue;

                switch (notif.type) {
                  case NotificationType.info:
                    leadingIcon = Icons.info;
                    notifColor = Colors.blue;
                    break;
                  case NotificationType.warning:
                    leadingIcon = Icons.warning_amber;
                    notifColor = Colors.amber;
                    break;
                  case NotificationType.error:
                    leadingIcon = Icons.error_outline;
                    notifColor = Colors.red;
                    break;
                  case NotificationType.success:
                    leadingIcon = Icons.check_circle_outline;
                    notifColor = Colors.green;
                    break;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  // Grey out read notifications slightly
                  color: notif.isRead 
                      ? theme.colorScheme.surface
                      : notifColor.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: notifColor.withValues(alpha: 0.15),
                          radius: 20,
                          child: Icon(leadingIcon, color: notifColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
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
                                        fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: notifColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: TextStyle(
                                  color: notif.isRead ? Colors.grey.shade600 : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRelativeTime(notif.createdAt),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                              ),
                            ],
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

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
