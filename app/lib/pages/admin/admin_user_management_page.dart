import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_user_model.dart';
import '../../providers/admin_user_provider.dart';
import './admin_user_dialogs.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  @override
  void initState() {
    super.initState();
    // Fetch users khi page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().fetchUsers(page: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AdminUserProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchUsers(page: 0),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header với nút thêm user
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng số user: ${provider.totalElements}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showCreateUserDialog(context, provider);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm user'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              // User list
              Expanded(
                child: provider.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Không có user nào'),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Tên đầy đủ')),
                            DataColumn(label: Text('Vai trò')),
                            DataColumn(label: Text('Trạng thái')),
                            DataColumn(label: Text('Hành động')),
                          ],
                          rows: provider.users.map((user) {
                            return DataRow(cells: [
                              DataCell(Text(user.id.toString())),
                              DataCell(Text(user.username ?? 'N/A')),
                              DataCell(Text(user.email ?? 'N/A')),
                              DataCell(Text(user.fullName ?? 'N/A')),
                              DataCell(
                                Wrap(
                                  spacing: 4,
                                  children: user.roles
                                          ?.map((role) => Chip(
                                                label: Text(
                                                  role.name ?? 'N/A',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                                backgroundColor:
                                                    Colors.blue[100],
                                                padding: EdgeInsets.zero,
                                              ))
                                          .toList() ??
                                      [],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: user.isActive == true
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.isActive == true
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      color: user.isActive == true
                                          ? Colors.green[900]
                                          : Colors.red[900],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    _handleUserAction(
                                        value, user, provider, context);
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Text('Xem chi tiết'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'toggle_status',
                                      child: Text('Bật/Tắt'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit_roles',
                                      child: Text('Sửa vai trò'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'reset_password',
                                      child: Text('Đặt lại mật khẩu'),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
              ),

              // Pagination
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: provider.currentPage > 0
                          ? () => provider.previousPage()
                          : null,
                      child: const Text('Trang trước'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Trang ${provider.currentPage + 1} / ${provider.totalPages}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: provider.currentPage < provider.totalPages - 1
                          ? () => provider.nextPage()
                          : null,
                      child: const Text('Trang sau'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleUserAction(String action, AdminUser user,
      AdminUserProvider provider, BuildContext context) {
    switch (action) {
      case 'view':
        showUserDetailDialog(context, user);
        break;
      case 'toggle_status':
        showConfirmDialog(
          context,
          'Thay đổi trạng thái',
          'Bạn có chắc muốn ${user.isActive == true ? 'vô hiệu hóa' : 'kích hoạt'} user này?',
          () async {
            try {
              await provider.updateUserStatus(
                  user.id ?? 0, !(user.isActive ?? false));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Cập nhật trạng thái thành công')),
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
        );
        break;
      case 'edit_roles':
        showEditRolesDialog(context, user, provider);
        break;
      case 'reset_password':
        showConfirmDialog(
          context,
          'Đặt lại mật khẩu',
          'Bạn có chắc muốn đặt lại mật khẩu cho user này?',
          () async {
            try {
              await provider.resetUserPassword(user.id ?? 0);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu đã được đặt lại')),
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
        );
        break;
      case 'delete':
        showConfirmDialog(
          context,
          'Xóa user',
          'Bạn có chắc muốn xóa user này? Hành động này không thể hoàn tác.',
          () async {
            try {
              await provider.deleteUser(user.id ?? 0);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User đã được xóa')),
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
        );
        break;
    }
  }
}
