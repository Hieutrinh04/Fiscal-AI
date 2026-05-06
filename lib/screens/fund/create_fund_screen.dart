import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/friend_provider.dart';
import '../../providers/shared_fund_provider.dart';
import '../../utils/snackbar.dart';

class CreateFundScreen extends StatefulWidget {
  const CreateFundScreen({super.key});

  @override
  State<CreateFundScreen> createState() => _CreateFundScreenState();
}

class _CreateFundScreenState extends State<CreateFundScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _deadline;
  final List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    context.read<FriendProvider>().loadAll();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<FriendProvider>().friends;
    final fundProvider = context.watch<SharedFundProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo quỹ mới'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TÊN QUỸ
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên quỹ *',
                hintText: 'VD: Du lịch Đà Lạt',
                prefixIcon: const Icon(Iconsax.flag),
                filled: true,
                fillColor: const Color(0xffF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// MÔ TẢ
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                prefixIcon: const Icon(Iconsax.note),
                filled: true,
                fillColor: const Color(0xffF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// SỐ TIỀN MỤC TIÊU
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền mục tiêu *',
                hintText: 'VD: 5000000',
                prefixIcon: const Icon(Iconsax.dollar_circle),
                suffixText: '₫',
                filled: true,
                fillColor: const Color(0xffF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// HẠN CHÓT
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.calendar),
              title: Text(
                _deadline != null
                    ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                    : 'Chọn hạn chót (tùy chọn)',
              ),
              trailing: _deadline != null
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle),
                      onPressed: () => setState(() => _deadline = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),

            const Divider(height: 32),

            /// THÊM THÀNH VIÊN
            const Text(
              'Thêm thành viên từ bạn bè',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chưa có bạn bè. Hãy thêm bạn trước!',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...friends.map((f) {
                /// Xác định friendUserId: người KHÔNG phải mình
                final currentUserId = Supabase.instance.client.auth.currentUser!.id;
                final friendUserId = f.userId == currentUserId ? f.friendId : f.userId;
                final isSelected = _selectedMemberIds.contains(friendUserId);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedMemberIds.add(friendUserId);
                      } else {
                        _selectedMemberIds.remove(friendUserId);
                      }
                    });
                  },
                  title: Text(f.friendName ?? 'Người dùng'),
                  subtitle: Text(f.friendEmail ?? ''),
                  secondary: CircleAvatar(
                    child: Text(
                      (f.friendName ?? 'U')[0].toUpperCase(),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            /// ERROR
            if (fundProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  fundProvider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: fundProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Iconsax.add_circle),
                label: Text(fundProvider.isLoading ? 'Đang tạo...' : 'Tạo quỹ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xff2F80ED),
                ),
                onPressed: fundProvider.isLoading ? null : _handleCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim();

    if (name.isEmpty) {
      AppSnackBar.warning(context, 'Vui lòng nhập tên quỹ');
      return;
    }
    if (amountStr.isEmpty) {
      AppSnackBar.warning(context, 'Vui lòng nhập số tiền mục tiêu');
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      AppSnackBar.warning(context, 'Số tiền không hợp lệ');
      return;
    }

    final fund = await context.read<SharedFundProvider>().createFund(
          name: name,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          targetAmount: amount,
          deadline: _deadline,
          memberIds: _selectedMemberIds,
        );

    if (fund != null && mounted) {
      AppSnackBar.success(context, 'Tạo quỹ thành công!');
      Navigator.pop(context);
    }
  }
}
