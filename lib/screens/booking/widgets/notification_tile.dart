import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_ui_model.dart';
import 'glass_card.dart';

class NotificationTile extends StatelessWidget {
  final NotificationUiModel item;
  final bool isDarkMode;
  final VoidCallback onLongPress;
  final Function(DismissDirection) onDismissed;

  const NotificationTile({
    super.key,
    required this.item,
    required this.isDarkMode,
    required this.onLongPress,
    required this.onDismissed,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981); // Green
      case 'pending':
        return const Color(0xFFF59E0B); // Orange
      case 'failed':
        return const Color(0xFFEF4444); // Red
      case 'sent':
      default:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.done_all_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      case 'sent':
      default:
        return Icons.done_rounded;
    }
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final now = DateTime.now();
    final localDateTime = dateTime.toLocal();
    if (localDateTime.year == now.year && localDateTime.month == now.month && localDateTime.day == now.day) {
      final h = localDateTime.hour.toString().padLeft(2, '0');
      final m = localDateTime.minute.toString().padLeft(2, '0');
      return 'Today, $h:$m';
    } else {
      final d = localDateTime.day.toString().padLeft(2, '0');
      final mo = localDateTime.month.toString().padLeft(2, '0');
      final h = localDateTime.hour.toString().padLeft(2, '0');
      final m = localDateTime.minute.toString().padLeft(2, '0');
      return '$d/$mo $h:$m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = isDarkMode ? Colors.white : const Color(0xFF1E2025);
    final secondaryText = isDarkMode ? const Color(0xFF9EA3B0) : const Color(0xFF6B7280);

    IconData typeIcon;
    Color typeIconColor;
    String cleanRecipientName;

    if (item.recipientType == 'followup') {
      typeIcon = Icons.event_repeat_rounded;
      typeIconColor = Colors.amber;
      cleanRecipientName = 'System (Follow-up Agent)';
    } else if (item.recipientType == 'provider') {
      typeIcon = Icons.handyman_rounded;
      typeIconColor = const Color(0xFF3B82F6);
      cleanRecipientName = item.recipientId == 'provider_001' ? 'Ali Electric Works (Provider)' : 'Provider (${item.recipientId})';
    } else {
      typeIcon = Icons.person_outline_rounded;
      typeIconColor = const Color(0xFFEC4899);
      cleanRecipientName = item.recipientId == 'user_customer_999' ? 'Ali Ahmed (Customer)' : 'Customer (${item.recipientId})';
    }

    final statusColor = _getStatusColor(item.status);
    final statusIcon = _getStatusIcon(item.status);
    final formattedTime = _formatTimestamp(item.createdAt);

    return Dismissible(
      key: Key(item.notificationId),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        onDismissed(direction);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Dismissing notification...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Dismissing notification...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_sweep_rounded, color: Colors.white),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: GlassCard(
            radius: 20,
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: typeIconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(typeIcon, size: 14, color: typeIconColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cleanRecipientName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(
                          item.channel == 'email'
                              ? Icons.alternate_email_rounded
                              : (item.channel == 'push' ? Icons.app_settings_alt_rounded : Icons.textsms_outlined),
                          size: 12,
                          color: secondaryText.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 8, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: primaryText.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link_rounded, size: 10, color: secondaryText.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'ID: ${item.bookingId.length > 12 ? item.bookingId.substring(0, 12) : item.bookingId}...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: secondaryText.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: secondaryText.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
