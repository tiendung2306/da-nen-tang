import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import './admin_user_management_page.dart';
import './admin_product_management_page.dart';
import './admin_category_management_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkAdminRole() {
    final authProvider = context.read<AuthProvider>();
    final roles = authProvider.userInfo?.roles ?? [];
    final isAdmin = roles.contains('ADMIN') || roles.contains('admin');

    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ admin mới có thể truy cập trang này'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý hệ thống'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Quản lý User', icon: Icon(Icons.people)),
              Tab(text: 'Quản lý Sản phẩm', icon: Icon(Icons.shopping_bag)),
              Tab(text: 'Quản lý Danh mục', icon: Icon(Icons.category)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: User Management
            const AdminUserManagementPage(),

            // Tab 2: Product Management
            const AdminProductManagementPage(),

            // Tab 3: Category Management
            const AdminCategoryManagementPage(),
          ],
        ),
      ),
    );
  }
}
