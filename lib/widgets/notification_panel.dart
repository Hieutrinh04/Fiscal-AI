import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/notification_provider.dart';
import '../providers/shared_fund_provider.dart';
import '../models/notification.dart';
import '../models/shared_fund.dart';

class NotificationPanel extends StatelessWidget {
  final VoidCallback onClose;

  const NotificationPanel({super.key, required this.onClose});

  Color _typeColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return const Color(0xff16A34A);
      case 'reminder':
        return const Color(0xff2F80ED);
      case 'ai':
        return const Color(0xff8B5CF6);
      case 'fund_invite':
        return const Color(0xffF59E0B);
      default:
        return const Color(0xff2F80ED);
    }
  }

  Color _typeBgColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange.shade50;
      case 'success':
        return const Color(0xffDCFCE7);
      case 'reminder':
        return const Color(0xffEFF6FF);
      case 'ai':
        return const Color(0xffF3E8FF);
      case 'fund_invite':
        return const Color(0xffFEF3C7);
      default:
        return const Color(0xffEFF6FF);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'warning':
        return Iconsax.warning_2;
      case 'success':
        return Iconsax.tick_circle;
      case 'reminder':
        return Iconsax.clock;
      case 'ai':
        return Iconsax.cpu;
      case 'fund_invite':
        return Iconsax.people;
      default:
        return Iconsax.notification;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final notiProvider = context.watch<NotificationProvider>();
    final fundProvider = context.watch<SharedFundProvider>();
    final notifications = notiProvider.notifications;
    final pendingInvitations = fundProvider.invitations;

    return Stack(
      children: [
        /// BACKGROUND MỜ
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),

        /// PANEL
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.88,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                /// HEADER với gradient
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      /// Handle bar
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Title row
                      Row(
                        children: [
                          const Icon(Iconsax.notification, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Thông báo",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (notiProvider.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${notiProvider.unreadCount} mới",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.close_circle, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),

                      /// Mark all read
                      if (notiProvider.unreadCount > 0) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => notiProvider.markAllAsRead(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.tick_square, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text("Đánh dấu đã đọc tất cả",
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                /// LIST
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = notifications[i];
                            return _NotiItem(
                              notification: n,
                              typeColor: _typeColor(n.type),
                              typeBgColor: _typeBgColor(n.type),
                              typeIcon: _typeIcon(n.type),
                              timeAgo: _timeAgo(n.createdAt),
                              onMarkRead: () => notiProvider.markAsRead(n.id),
                              onDelete: () => notiProvider.deleteNotification(n.id),
                              pendingInvitations: pendingInvitations,
                              onAcceptInvitation: (inv) async {
                                final ok = await fundProvider.acceptInvitation(inv.id, inv.fundId);
                                if (ok) notiProvider.markAsRead(n.id);
                              },
                              onDeclineInvitation: (inv) async {
                                final ok = await fundProvider.declineInvitation(inv.id);
                                if (ok) notiProvider.markAsRead(n.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.notification, size: 36, color: Color(0xff2F80ED)),
          ),
          const SizedBox(height: 16),
          const Text("Chưa có thông báo nào",
              style: TextStyle(color: Color(0xff6B7280), fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text("Các thông báo quan trọng sẽ xuất hiện ở đây",
              style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12)),
        ],
      ),
    );
  }
}

/// ITEM
class _NotiItem extends StatelessWidget {
  final AppNotification notification;
  final Color typeColor;
  final Color typeBgColor;
  final IconData typeIcon;
  final String timeAgo;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final List<FundInvitation> pendingInvitations;
  final Function(FundInvitation)? onAcceptInvitation;
  final Function(FundInvitation)? onDeclineInvitation;

  const _NotiItem({
    required this.notification,
    required this.typeColor,
    required this.typeBgColor,
    required this.typeIcon,
    required this.timeAgo,
    required this.onMarkRead,
    required this.onDelete,
    this.pendingInvitations = const [],
    this.onAcceptInvitation,
    this.onDeclineInvitation,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final isFundInvite = notification.type == 'fund_invite';

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.trash, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            const Text("Xoá", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: (isUnread && !isFundInvite) ? onMarkRead : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? typeBgColor.withValues(alpha: 0.5) : const Color(0xffF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: isUnread
                ? Border.all(color: typeColor.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ICON
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: typeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),

              /// CONTENT
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
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: const TextStyle(color: Color(0xff6B7280), fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Iconsax.clock, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),

                    /// FUND INVITE ACTIONS
                    if (isFundInvite && isUnread && pendingInvitations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 34,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Iconsax.tick_circle, size: 16),
                                  onPressed: () {
                                    if (pendingInvitations.isNotEmpty) {
                                      onAcceptInvitation?.call(pendingInvitations.first);
                                    }
                                  },
                                  label: const Text('Đồng ý'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 34,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(color: Colors.red),
                                    foregroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Iconsax.close_circle, size: 16),
                                  onPressed: () {
                                    if (pendingInvitations.isNotEmpty) {
                                      onDeclineInvitation?.call(pendingInvitations.first);
                                    }
                                  },
                                  label: const Text('Từ chối'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isFundInvite && !isUnread)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Đã xử lý',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
