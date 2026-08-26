import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../services/fcm_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/notification_visuals.dart';
import '../widgets/admob_banner.dart';
import '../widgets/alert_reply_panel.dart';
import '../widgets/ui_kit.dart';

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
        title: const Text('Alerts'),
        actions: [
          StreamBuilder<int>(
            stream: _firestoreService.streamUnreadNotificationCount(
              _currentUser!.uid,
            ),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                tooltip: 'Alert options',
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    enabled: unread > 0,
                    child: const _MenuRow(
                      icon: Icons.done_all_rounded,
                      label: 'Mark all as read',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: _MenuRow(
                      icon: Icons.delete_sweep_rounded,
                      label: 'Clear all',
                      isDestructive: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _firestoreService.streamUserNotifications(
                _currentUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _InboxSkeleton();
                }

                if (snapshot.hasError) {
                  return const AppEmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load your alerts',
                    message:
                        'Check your connection and try again. New alerts will '
                        'still ring your phone.',
                    accent: AppColors.alert,
                  );
                }

                final notifications = snapshot.data ?? const [];
                _maybeOpenInitialNotification(notifications);

                if (notifications.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.shield_moon_rounded,
                    title: 'Nothing to worry about',
                    message:
                        'No one has needed to reach you about your vehicle. '
                        'When someone scans your code, the alert lands here — '
                        'and your phone will ring for it.',
                    accent: AppColors.success,
                  );
                }

                return _buildGroupedList(notifications);
              },
            ),
          ),
          const AdMobBanner(),
        ],
      ),
    );
  }

  // -- List ---------------------------------------------------------------

  /// Groups alerts under Today / Yesterday / date headings. A flat list of
  /// "3h ago" strings loses the sense of when a problem happened.
  Widget _buildGroupedList(List<NotificationModel> notifications) {
    final entries = <Widget>[];
    String? currentHeading;

    for (var i = 0; i < notifications.length; i++) {
      final notification = notifications[i];
      final heading = _dateHeading(notification.sentAt);

      if (heading != currentHeading) {
        currentHeading = heading;
        entries.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xs,
              entries.isEmpty ? 0 : AppSpacing.xl,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Text(heading.toUpperCase(), style: AppText.overline),
          ),
        );
      }

      entries.add(
        EntranceFade(
          delay: Duration(milliseconds: 30 * (i.clamp(0, 8))),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _NotificationCard(
              notification: notification,
              onTap: () => _showNotificationDetails(notification),
              onDelete: () => _deleteNotification(notification),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: entries,
    );
  }

  static String _dateHeading(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final difference = today.difference(that).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return DateFormat('EEEE').format(date);
    if (date.year == now.year) return DateFormat('d MMMM').format(date);
    return DateFormat('d MMMM y').format(date);
  }

  void _maybeOpenInitialNotification(List<NotificationModel> notifications) {
    if (_didHandleInitialNotification) return;

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
        showAppSnackBar(
          ScaffoldMessenger.of(context),
          'That alert is no longer available.',
        );
      });
    }
  }

  // -- Actions ------------------------------------------------------------

  Future<void> _deleteNotification(NotificationModel notification) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _firestoreService.deleteNotification(notification.id);
      await FCMService.cancelNotificationLifecycleById(notification.id);
      if (!mounted) return;
      showAppSnackBar(messenger, 'Alert deleted');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    }
  }

  Future<void> _showNotificationDetails(NotificationModel notification) async {
    // Reading the alert acknowledges it, which stops the escalating reminders.
    if (!notification.read) {
      await _firestoreService.markNotificationAsRead(notification.id);
      await FCMService.cancelNotificationLifecycleById(notification.id);
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return _NotificationDetailSheet(
            notification: notification,
            scrollController: scrollController,
            onReply: (reply) => _firestoreService.replyToNotification(
              notificationId: notification.id,
              reply: reply,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    final userId = _currentUser?.uid;
    if (userId == null || userId.isEmpty) return;

    if (action == 'mark_all_read') {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final ids = await _firestoreService.markAllNotificationsAsRead(userId);
        await FCMService.cancelNotificationLifecycleByIds(ids);
        if (!mounted) return;
        showAppSnackBar(
          messenger,
          ids.isEmpty
              ? 'Nothing left to mark'
              : 'Marked ${ids.length} alert${ids.length == 1 ? '' : 's'} as read',
          kind: AppSnackKind.success,
        );
      } catch (e) {
        if (!mounted) return;
        showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
      }
      return;
    }

    if (action != 'clear_all') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all alerts?'),
        content: const Text(
          'Every alert will be deleted from this device and your account. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final existing = await _firestoreService.getUserNotifications(
        userId,
        limit: 300,
      );
      await _firestoreService.clearAllNotifications(userId);
      await FCMService.cancelNotificationLifecycleByIds(
        existing.map((notification) => notification.id),
      );
      if (!mounted) return;
      showAppSnackBar(messenger, 'All alerts cleared', kind: AppSnackKind.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    }
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = ReasonVisual.of(notification.reason);
    final isUnread = !notification.read;

    return Dismissible(
      key: ValueKey<String>('alert-${notification.id}'),
      direction: DismissDirection.endToStart,
      background: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.alert,
          borderRadius: AppRadius.cardAll,
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: AppSpacing.xl),
            child: Icon(Icons.delete_rounded, color: AppColors.onDark),
          ),
        ),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        // The Firestore stream removes the row; dismissing here too would
        // double-remove and desync the list.
        return false;
      },
      child: AppCard(
        onTap: onTap,
        color: isUnread ? AppColors.surface : AppColors.background,
        borderColor: isUnread
            ? visual.color.withValues(alpha: 0.35)
            : AppColors.border,
        shadows: isUnread ? AppShadows.card : const <BoxShadow>[],
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity spine — colour plus position, never colour alone.
              if (isUnread)
                Container(width: 4, color: visual.color)
              else
                const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconBadge(icon: visual.icon, color: visual.color),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.reasonText,
                                    style: isUnread
                                        ? AppText.titleMedium
                                        : AppText.titleSmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                  ),
                                ),
                                if (isUnread) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  StatusPill(
                                    label: 'NEW',
                                    color: visual.color,
                                  ),
                                ],
                              ],
                            ),
                            if (notification.message.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                notification.message.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification.timeAgo,
                                  style: AppText.caption.copyWith(
                                    color: AppColors.textTertiary,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.notification,
    required this.scrollController,
    required this.onReply,
  });

  final NotificationModel notification;
  final ScrollController scrollController;
  final AlertReplySender onReply;

  @override
  Widget build(BuildContext context) {
    final visual = ReasonVisual.of(notification.reason);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetGrabber(),

          // Header band — carries the severity colour so the sheet reads at a
          // glance before any text is processed.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: AppRadius.heroAll,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  visual.color,
                  Color.lerp(visual.color, Colors.black, 0.22)!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(visual.icon, color: AppColors.onDark, size: 34),
                const SizedBox(height: AppSpacing.md),
                Text(notification.reasonText, style: AppText.panicTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ReasonVisual.guidance(notification.reason),
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (notification.message.trim().isNotEmpty) ...[
            Text('WHAT THEY SAID', style: AppText.overline),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.cardAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                notification.message.trim(),
                style: AppText.bodyLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          Text('WHEN', style: AppText.overline),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${DateFormat('EEEE d MMMM, h:mm a').format(notification.sentAt)}'
                  '  ·  ${notification.timeAgo}',
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: AppRadius.cardAll,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.visibility_off_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Whoever sent this stayed anonymous, and they never saw '
                    'your contact details either.',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Replaces what used to be a "Got it, I'm heading over" button that
          // only closed the sheet. It promised the scanner had been answered
          // and told nobody anything.
          AlertReplyPanel(
            notification: notification,
            accent: visual.isUrgent ? AppColors.alert : AppColors.primary,
            onReply: onReply,
            onReplied: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.alert : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: AppText.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        AppSkeleton(height: 12, width: 60, radius: 4),
        SizedBox(height: AppSpacing.lg),
        AppSkeleton(height: 104),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(height: 104),
        SizedBox(height: AppSpacing.md),
        AppSkeleton(height: 104),
      ],
    );
  }
}
