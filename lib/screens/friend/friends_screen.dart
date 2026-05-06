import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/friendship.dart';
import '../../providers/friend_provider.dart';
import '../../utils/snackbar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<FriendProvider>().loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friend = context.watch<FriendProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Bạn bè (${friend.friends.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lời mời'),
                  if (friend.pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${friend.pendingCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Đã gửi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: () => _showAddFriendDialog(),
          ),
        ],
      ),
      body: friend.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(friend.friends),
                _buildPendingList(friend.pendingRequests),
                _buildSentList(friend.sentRequests),
              ],
            ),
    );
  }

  /// ================= FRIENDS LIST =================
  Widget _buildFriendsList(List<Friendship> friends) {
    if (friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.people, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có bạn bè', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text('Bấm + để thêm bạn', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (_, i) {
        final f = friends[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xff2F80ED).withValues(alpha: 0.1),
              child: Text(
                (f.friendName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xff2F80ED),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              f.friendName ?? 'Người dùng',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(f.friendEmail ?? ''),
            trailing: PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Xóa bạn', style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (val) async {
                if (val == 'remove') {
                  final ok = await context.read<FriendProvider>().removeFriend(f.id);
                  if (ok && mounted) AppSnackBar.success(context, 'Đã xóa bạn');
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// ================= PENDING LIST =================
  Widget _buildPendingList(List<Friendship> requests) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('Không có lời mời nào', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) {
        final r = requests[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Text(
                (r.friendName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(r.friendName ?? 'Người dùng'),
            subtitle: Text(r.friendEmail ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.tick_circle, color: Colors.green),
                  onPressed: () async {
                    final ok = await context.read<FriendProvider>().acceptRequest(r.id);
                    if (ok && mounted) AppSnackBar.success(context, 'Đã chấp nhận');
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.red),
                  onPressed: () async {
                    final ok = await context.read<FriendProvider>().rejectRequest(r.id);
                    if (ok && mounted) AppSnackBar.success(context, 'Đã từ chối');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= SENT LIST =================
  Widget _buildSentList(List<Friendship> sent) {
    if (sent.isEmpty) {
      return const Center(
        child: Text('Chưa gửi lời mời nào', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sent.length,
      itemBuilder: (_, i) {
        final s = sent[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              child: const Icon(Iconsax.clock, color: Colors.grey),
            ),
            title: Text(s.friendName ?? 'Người dùng'),
            subtitle: Text(s.friendEmail ?? ''),
            trailing: const Text(
              'Đang chờ',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  /// ================= ADD FRIEND DIALOG =================
  void _showAddFriendDialog() {
    _searchController.clear();
    List<Map<String, dynamic>> results = [];
    bool hasSearched = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm bạn bè'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên hoặc email',
                      prefixIcon: const Icon(Iconsax.search_normal),
                      suffixIcon: IconButton(
                        icon: const Icon(Iconsax.search_status),
                        onPressed: () async {
                          final query = _searchController.text.trim();
                          if (query.isEmpty) return;
                          final list = await context
                              .read<FriendProvider>()
                              .searchUsers(query);
                          setDialogState(() {
                            results = list;
                            hasSearched = true;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (val) async {
                      final query = val.trim();
                      if (query.isEmpty) return;
                      final list = await context
                          .read<FriendProvider>()
                          .searchUsers(query);
                      setDialogState(() {
                        results = list;
                        hasSearched = true;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (hasSearched && results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Không tìm thấy người dùng',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (results.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final user = results[i];
                          final name = user['full_name'] ?? 'Người dùng';
                          final email = user['email'] ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xff2F80ED).withValues(alpha: 0.1),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xff2F80ED),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                            trailing: SizedBox(
                              width: 70,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () async {
                                  final ok = await context
                                      .read<FriendProvider>()
                                      .sendRequest(user['id']);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    if (ok) {
                                      AppSnackBar.success(context, 'Đã gửi lời mời kết bạn');
                                    } else {
                                      AppSnackBar.warning(context, 'Không thể gửi lời mời');
                                    }
                                  }
                                },
                                child: const Text('Kết bạn'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }
}
