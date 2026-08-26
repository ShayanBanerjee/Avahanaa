/// The owner's reply to whoever is standing at their vehicle.
///
/// This is the second half of the product. The alert gets the owner moving;
/// this tells the person in the street that it worked, which is the
/// de-escalation the whole thing exists to cause. Someone who can see "the
/// owner is on their way, about 5 minutes" stops deciding whether to key the
/// car.
///
/// Panic-mode rules apply. One obvious primary action sized for a thumb, the
/// alternatives smaller and below it, no text entry, and no way to get it
/// wrong. The owner is reading this while walking.
library;

import 'package:flutter/material.dart';

import '../models/alert_reply.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Sends [reply]; throws a human-readable string on failure.
typedef AlertReplySender = Future<void> Function(AlertReply reply);

class AlertReplyPanel extends StatefulWidget {
  const AlertReplyPanel({
    super.key,
    required this.notification,
    required this.onReply,
    this.onReplied,
    this.accent = AppColors.primary,
  });

  final NotificationModel notification;
  final AlertReplySender onReply;

  /// Called after a reply lands, so a sheet can close itself.
  final VoidCallback? onReplied;

  /// Severity colour of the alert this answers, so the reply reads as part of
  /// the same event rather than as generic chrome.
  final Color accent;

  @override
  State<AlertReplyPanel> createState() => _AlertReplyPanelState();
}

class _AlertReplyPanelState extends State<AlertReplyPanel> {
  AlertReply? _sending;

  /// Set the moment a reply succeeds, so the panel can flip to its confirmed
  /// state without waiting for the Firestore stream to come back around. The
  /// owner is walking; a second of "did that work?" is a second too long.
  AlertReply? _justSent;

  Future<void> _send(AlertReply reply) async {
    if (_sending != null) return;
    setState(() => _sending = reply);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onReply(reply);
      if (!mounted) return;
      setState(() {
        _sending = null;
        _justSent = reply;
      });
      showAppSnackBar(
        messenger,
        'They have been told — ${reply.scannerLabel.toLowerCase()}',
        kind: AppSnackKind.success,
      );
      widget.onReplied?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = null);
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _justSent ?? widget.notification.reply;
    if (sent != null) return _ReplySentPanel(reply: sent);

    // The likeliest answer is the big one. Everything else is a smaller
    // choice underneath it — the design system allows exactly one primary
    // action, and on a panic surface it has to be unmistakable.
    const primary = AlertReply.onMyWayFive;
    final alternatives = AlertReply.quickReplies
        .where((r) => r != primary)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REPLY TO THEM', style: AppText.overline),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'They are still standing at your vehicle with the page open. One tap '
          'tells them you are coming.',
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _sending == null ? () => _send(primary) : null,
            icon: _sending == primary
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(AppColors.onDark),
                    ),
                  )
                : const Icon(Icons.directions_run_rounded, size: 24),
            label: Text(
              _sending == primary ? 'Sending…' : primary.ownerLabel,
              style: AppText.labelLarge.copyWith(
                color: AppColors.onDark,
                fontSize: 17,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final reply in alternatives)
              _ReplyChip(
                reply: reply,
                busy: _sending == reply,
                enabled: _sending == null,
                onTap: () => _send(reply),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReplyChip extends StatelessWidget {
  const _ReplyChip({
    required this.reply,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final AlertReply reply;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // "I can't get there" is a real answer and needs to be reachable, but it
    // should never be the one a thumb finds by accident.
    final isDecline = !reply.isOnTheWay;

    return Material(
      color: isDecline ? AppColors.surfaceMuted : AppColors.primaryTint,
      borderRadius: AppRadius.controlAll,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.controlAll,
        child: Container(
          // 48 high keeps every option at the minimum tap target, even the
          // ones that are deliberately not the primary action.
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                reply.ownerLabel,
                style: AppText.labelMedium.copyWith(
                  color: isDecline
                      ? AppColors.textSecondary
                      : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the owner sees once they have answered.
///
/// Deliberately restates what the *scanner* is now reading, not what the owner
/// tapped. The reassurance the owner needs is that the person at their car
/// knows someone is coming.
class _ReplySentPanel extends StatelessWidget {
  const _ReplySentPanel({required this.reply});

  final AlertReply reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successTint,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_chat_read_rounded,
            color: AppColors.successDark,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'They have been told',
                  style: AppText.titleSmall.copyWith(
                    color: AppColors.successDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Their page now reads: "${reply.scannerLabel}".',
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single one-tap reply, sized for a panic surface.
///
/// This exists for the home alert banner, where the owner has already read the
/// reason and the note on the card itself. What they have not done is tell the
/// person in the street anything, so on that surface the reply — not "see what
/// happened" — is the primary action.
class AlertQuickReplyButton extends StatefulWidget {
  const AlertQuickReplyButton({
    super.key,
    required this.onReply,
    this.reply = AlertReply.onMyWayFive,
    this.background = AppColors.surface,
    this.foreground = AppColors.alertDeep,
  });

  final AlertReplySender onReply;
  final AlertReply reply;
  final Color background;
  final Color foreground;

  @override
  State<AlertQuickReplyButton> createState() => _AlertQuickReplyButtonState();
}

class _AlertQuickReplyButtonState extends State<AlertQuickReplyButton> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _send() async {
    if (_sending || _sent) return;
    setState(() => _sending = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onReply(widget.reply);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
      showAppSnackBar(
        messenger,
        'They have been told — ${widget.reply.scannerLabel.toLowerCase()}',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAppSnackBar(messenger, e.toString(), kind: AppSnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Once sent, the button holds its confirmed state rather than disappearing.
    // A control that vanishes under a thumb reads as a misfire, and this one
    // sits directly above another button.
    final label = _sent
        ? 'They know you are coming'
        : _sending
        ? 'Telling them…'
        : widget.reply.ownerLabel;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _sending || _sent ? null : _send,
        icon: Icon(
          _sent ? Icons.check_circle_rounded : Icons.directions_run_rounded,
          size: 22,
        ),
        label: Text(label, style: AppText.labelLarge.copyWith(fontSize: 17)),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.background,
          foregroundColor: widget.foreground,
          disabledBackgroundColor: widget.background,
          disabledForegroundColor: widget.foreground,
        ),
      ),
    );
  }
}
