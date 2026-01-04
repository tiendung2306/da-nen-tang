import 'package:flutter/material.dart';
import '../../models/admin_user_model.dart';
import '../../providers/admin_user_provider.dart';

/// Dialog xem chi tiết user
void showUserDetailDialog(BuildContext context, AdminUser user) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Chi tiết User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID', user.id.toString()),
            _detailRow('Username', user.username ?? 'N/A'),
            _detailRow('Email', user.email ?? 'N/A'),
            _detailRow('Tên đầy đủ', user.fullName ?? 'N/A'),
            _detailRow(
                'Trạng thái', user.isActive == true ? 'Active' : 'Inactive'),
            const SizedBox(height: 16),
            const Text('Vai trò:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...?user.roles?.map((role) => Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16),
                  child: Text('• ${role.name}'),
                )),
            const SizedBox(height: 16),
            _detailRow('Tạo lúc', user.createdAt?.toString() ?? 'N/A'),
            _detailRow('Cập nhật lúc', user.updatedAt?.toString() ?? 'N/A'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Dialog tạo user mới
void showCreateUserDialog(BuildContext context, AdminUserProvider provider) {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tạo User mới'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Nhập username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Username không được để trống';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Nhập email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Email không được để trống';
                  if (!value!.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đầy đủ',
                  hintText: 'Nhập tên đầy đủ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Mật khẩu không được để trống';
                  if ((value?.length ?? 0) < 6)
                    return 'Mật khẩu phải ít nhất 6 ký tự';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              try {
                await provider.createUser({
                  'username': usernameController.text,
                  'email': emailController.text,
                  'fullName': fullNameController.text,
                  'password': passwordController.text,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo user thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          },
          child: const Text('Tạo'),
        ),
      ],
    ),
  );
}

/// Dialog chỉnh sửa vai trò
void showEditRolesDialog(
    BuildContext context, AdminUser user, AdminUserProvider provider) {
  // Mock list of available roles
  final availableRoles = ['ADMIN', 'USER', 'MODERATOR'];
  final selectedRoles =
      List<String>.from(user.roles?.map((r) => r.name ?? '').toList() ?? []);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Chỉnh sửa vai trò'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableRoles
              .map(
                (role) => CheckboxListTile(
                  title: Text(role),
                  value: selectedRoles.contains(role),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedRoles.add(role);
                      } else {
                        selectedRoles.remove(role);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.updateUserRoles(user.id ?? 0, selectedRoles);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cập nhật vai trò thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
}

/// Dialog xác nhận hành động
void showConfirmDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// Helper function để hiển thị row chi tiết
Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    ),
  );
}
