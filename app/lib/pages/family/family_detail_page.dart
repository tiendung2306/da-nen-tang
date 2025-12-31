import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/shopping/shopping_list_page.dart';
import 'package:flutter_boilerplate/pages/meal_plan/meal_plan_page.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FamilyDetailPage extends StatefulWidget {
  final int familyId;
  const FamilyDetailPage({Key? key, required this.familyId}) : super(key: key);

  @override
  _FamilyDetailPageState createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage> {
  final ApiService _apiService = locator<ApiService>();
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().selectFamily(widget.familyId);
    });
  }

  void _showInviteDialog(Family family) async {
    setState(() => _isGeneratingCode = true);
    
    try {
      final inviteCode = await _apiService.generateInviteCode(family.id);
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mời thành viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chia sẻ mã mời này cho bạn bè:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      inviteCode.isNotEmpty ? inviteCode : 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: inviteCode,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã mời')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
  }

  void _navigateToShoppingList(Family family) {
    // Set the selected family in provider before navigating
    context.read<FamilyProvider>().setSelectedFamily(family);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShoppingListPage(),
      ),
    );
  }

  void _navigateToMealPlan(Family family) {
    // Set the selected family in provider before navigating
    context.read<FamilyProvider>().setSelectedFamily(family);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MealPlanPage(),
      ),
    );
  }

  void _showExpenseReport(Family family) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Báo cáo chi tiêu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pie_chart, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Chức năng này đang được phát triển',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveFamily(Family family) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời khỏi nhóm'),
        content: Text('Bạn có chắc muốn rời khỏi nhóm "${family.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<FamilyProvider>().leaveFamily(family.id);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã rời khỏi nhóm')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rời nhóm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<FamilyProvider>(
            builder: (context, provider, _) {
              if (provider.selectedFamily != null) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'leave') {
                      _confirmLeaveFamily(provider.selectedFamily!);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Rời khỏi nhóm', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, child) {
          if (provider.viewStatus == ViewStatus.Loading || provider.selectedFamily == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.selectFamily(widget.familyId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final family = provider.selectedFamily!;
          final members = provider.members;

          return RefreshIndicator(
            onRefresh: () => provider.selectFamily(widget.familyId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Family Info Header
                  Text(
                    family.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: orangeColor.withOpacity(0.2),
                    backgroundImage: family.avatarUrl != null 
                        ? NetworkImage(family.avatarUrl!) 
                        : null,
                    child: family.avatarUrl == null 
                        ? Icon(Icons.group, size: 60, color: orangeColor) 
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Members Section
                  if (members.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thành viên (${members.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: members.length,
                        itemBuilder: (ctx, index) {
                          final member = members[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: member.avatarUrl != null
                                      ? NetworkImage(member.avatarUrl!)
                                      : null,
                                  child: member.avatarUrl == null
                                      ? Text(
                                          member.fullName.isNotEmpty 
                                              ? member.fullName[0].toUpperCase() 
                                              : '?',
                                          style: const TextStyle(fontSize: 20),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    member.fullName,
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  member.role == 'OWNER' ? 'Chủ nhóm' : 'Thành viên',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: member.role == 'OWNER' 
                                        ? orangeColor 
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _buildActionButton(
                        icon: Icons.person_add,
                        text: 'Thêm thành viên',
                        color: orangeColor,
                        isLoading: _isGeneratingCode,
                        onTap: () => _showInviteDialog(family),
                      ),
                      _buildActionButton(
                        icon: Icons.shopping_cart,
                        text: 'Danh sách mua sắm',
                        color: orangeColor,
                        onTap: () => _navigateToShoppingList(family),
                      ),
                      _buildActionButton(
                        icon: Icons.pie_chart,
                        text: 'Báo cáo chi tiêu',
                        color: orangeColor,
                        onTap: () => _showExpenseReport(family),
                      ),
                      _buildActionButton(
                        icon: Icons.calendar_month,
                        text: 'Lên lịch bữa ăn',
                        color: orangeColor,
                        onTap: () => _navigateToMealPlan(family),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Quick access to fridge
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.kitchen, color: Colors.blue),
                      ),
                      title: const Text('Tủ lạnh của nhóm'),
                      subtitle: const Text('Quản lý thực phẩm'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to Fridge page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chức năng đang phát triển')),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 4),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}
