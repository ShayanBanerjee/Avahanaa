import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';
import '../models/notification_model.dart';
import 'package:intl/intl.dart';
import '../widgets/admob_banner.dart';

class NotificationsScreen extends StatefulWidget {
  final String? initialNotificationId;

  const NotificationsScreen({super.key, this.initialNotificationId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _didHandleInitialNotification = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _firestoreService.streamUserNotifications(
                _currentUser!.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];
                _maybeOpenInitialNotification(notifications);

                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
          const AdMobBanner(),
        ],
      ),
    );
  }

  void _maybeOpenInitialNotification(List<NotificationModel> notifications) {
    if (_didHandleInitialNotification) {
      return;
    }

    final initialId = widget.initialNotificationId?.trim() ?? '';
    if (initialId.isEmpty) {
      _didHandleInitialNotification = true;
      return;
    }

    NotificationModel? target;
    for (final notification in notifications) {
      if (notification.id == initialId) {
        target = notification;
        break;
      }
    }

    if (target != null) {
      _didHandleInitialNotification = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNotificationDetails(target!);
      });
      return;
    }

    if (notifications.isNotEmpty) {
      _didHandleInitialNotification = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The tapped alert is no longer available.'),
          ),
        );
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see notifications here when someone needs to reach you about your vehicle',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.read ? 0 : 2,
      color: notification.read ? null : const Color(0xFFF0F9FF),
      child: InkWell(
        onTap: () => _showNotificationDetails(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getReasonColor(
                    notification.reason,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    notification.reasonIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.reasonText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.read
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (notification.message.isNotEmpty) ...[
                      Text(
                        notification.message,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      notification.timeAgo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // More button
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showNotificationMenu(notification),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'blocking_driveway':
        return const Color(0xFFEF4444);
      case 'illegal_parking':
        return const Color(0xFFF59E0B);
      case 'blocking_traffic':
        return const Color(0xFFEF4444);
      case 'double_parked':
        return const Color(0xFFF59E0B);
      case 'emergency':
        return const Color(0xFFDC2626);
      case 'private_property':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _showNotificationDetails(NotificationModel notification) async {
    // Mark as read
    if (!notification.read) {
      await _firestoreService.markNotificationAsRead(notification.id);
      await FCMService.cancelNotificationLifecycleById(notification.id);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon and title
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getReasonColor(
                          notification.reason,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          notification.reasonIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.reasonText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM d, y • h:mm a',
                            ).format(notification.sentAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (notification.message.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationMenu(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(this.context);
                Navigator.pop(context);
                await _firestoreService.deleteNotification(notification.id);
                await FCMService.cancelNotificationLifecycleById(
                  notification.id,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) async {
    if (action == 'clear_all') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Clear All Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear All'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final userId = _currentUser?.uid;
        if (userId == null || userId.isEmpty) {
          return;
        }
        final existingNotifications = await _firestoreService
            .getUserNotifications(userId, limit: 300);
        await _firestoreService.clearAllNotifications(userId);
        await FCMService.cancelNotificationLifecycleByIds(
          existingNotifications.map((notification) => notification.id),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications cleared')),
          );
        }
      }
    }
  }
}
