import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/in_app_notification_provider.dart';
import '../../models/in_app_notification.dart';
import '../../constants/app_theme.dart';

class InAppNotificationsScreen extends StatelessWidget {
  const InAppNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<InAppNotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text('Mark All Read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = Provider.of<InAppNotificationProvider>(context, listen: false);
              if (value == 'clear_all') {
                _showClearAllDialog(context, provider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<InAppNotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!provider.hasNotifications) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your in-app notifications will appear here',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _buildNotificationCard(context, notification, provider, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    InAppNotification notification,
    InAppNotificationProvider provider,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
            : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? (isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0))
              : notification.color.withOpacity(0.3),
          width: notification.isRead ? 0.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                            ),
                            onPressed: () => provider.deleteNotification(notification.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, InAppNotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
