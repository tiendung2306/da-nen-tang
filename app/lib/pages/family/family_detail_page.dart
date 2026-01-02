import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/providers/family_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/pages/shopping/shopping_list_page.dart';
import 'package:flutter_boilerplate/pages/meal_plan/meal_plan_page.dart';
import 'package:flutter_boilerplate/pages/recipe/family_recipe_list_page.dart';
import 'package:flutter_boilerplate/pages/fridge/fridge_page.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';
import 'package:flutter_boilerplate/constants/api_config.dart';

class FamilyDetailPage extends StatefulWidget {
  final int familyId;
  const FamilyDetailPage({Key? key, required this.familyId}) : super(key: key);

  @override
  _FamilyDetailPageState createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage> {
  final ApiService _apiService = locator<ApiService>();
  bool _isUpdatingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().selectFamily(widget.familyId);
    });
  }

  void _showImageOptions(Family family) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Chụp ảnh'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAndUpdateImage(family, ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUpdateImage(family, ImageSource.gallery);
                },
              ),
              if (family.avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteImage(family);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpdateImage(Family family, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _isUpdatingImage = true);
        
        final success = await context.read<FamilyProvider>().updateFamily(
          family.id,
          {'name': family.name},
          image: image,
        );
        
        if (mounted) {
          setState(() => _isUpdatingImage = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật ảnh nhóm'), backgroundColor: Colors.green),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.read<FamilyProvider>().errorMessage ?? 'Cập nhật ảnh thất bại'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteImage(Family family) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ảnh nhóm'),
        content: const Text('Bạn có chắc muốn xóa ảnh của nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUpdatingImage = true);
      
      final success = await context.read<FamilyProvider>().deleteImage(family.id);
      
      if (mounted) {
        setState(() => _isUpdatingImage = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ảnh nhóm'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<FamilyProvider>().errorMessage ?? 'Xóa ảnh thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showInviteDialog(Family family, List<FamilyMember> members) {
    showDialog(
      context: context,
      builder: (ctx) => _InviteMemberDialog(
        family: family,
        apiService: _apiService,
        members: members,
      ),
    );
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

  void _navigateToRecipes(Family family) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyRecipeListPage(family: family),
      ),
    );
  }

  void _navigateToFridge(Family family) {
    // Select the family first, then navigate to fridge page
    context.read<FamilyProvider>().selectFamily(family.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FridgePage(),
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
                  // Avatar with edit option
                  GestureDetector(
                    onTap: () => _showImageOptions(family),
                    child: Stack(
                      children: [
                        _isUpdatingImage
                            ? CircleAvatar(
                                radius: 60,
                                backgroundColor: orangeColor.withOpacity(0.2),
                                child: const CircularProgressIndicator(),
                              )
                            : CircleAvatar(
                                radius: 60,
                                backgroundColor: orangeColor.withOpacity(0.2),
                                backgroundImage: ApiConfig.getImageUrl(family.avatarUrl) != null 
                                    ? NetworkImage(ApiConfig.getImageUrl(family.avatarUrl)!) 
                                    : null,
                                child: family.avatarUrl == null 
                                    ? Icon(Icons.group, size: 60, color: orangeColor) 
                                    : null,
                              ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: orangeColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Nhấn để thay đổi ảnh', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                                  backgroundImage: ApiConfig.getImageUrl(member.avatarUrl) != null
                                      ? NetworkImage(ApiConfig.getImageUrl(member.avatarUrl)!)
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
                        isLoading: false,
                        onTap: () => _showInviteDialog(family, members),
                      ),
                      _buildActionButton(
                        icon: Icons.shopping_cart,
                        text: 'Danh sách mua sắm',
                        color: orangeColor,
                        onTap: () => _navigateToShoppingList(family),
                      ),
                      _buildActionButton(
                        icon: Icons.restaurant_menu,
                        text: 'Công thức nấu ăn',
                        color: orangeColor,
                        onTap: () => _navigateToRecipes(family),
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
                      onTap: () => _navigateToFridge(family),
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

// Dialog mời thành viên với 2 tab
class _InviteMemberDialog extends StatefulWidget {
  final Family family;
  final ApiService apiService;
  final List<FamilyMember> members;

  const _InviteMemberDialog({
    Key? key,
    required this.family,
    required this.apiService,
    required this.members,
  }) : super(key: key);

  @override
  _InviteMemberDialogState createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab 1: Mã mời
  String? _inviteCode;
  bool _isLoadingCode = false;
  
  // Tab 2: Mời bạn bè
  List<UserInfo> _friends = [];
  bool _isLoadingFriends = false;
  Set<int> _invitingFriendIds = {};
  Set<int> _invitedFriendIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInviteCode();
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInviteCode() async {
    setState(() => _isLoadingCode = true);
    try {
      final code = await widget.apiService.generateInviteCode(widget.family.id);
      if (mounted) {
        setState(() => _inviteCode = code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải mã mời: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCode = false);
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);
    try {
      final friends = await widget.apiService.getFriends();
      // Loại bỏ các bạn đã là thành viên gia đình
      final memberIds = widget.members.map((m) => m.id).toSet();
      final availableFriends = friends.where((f) => !memberIds.contains(f.id)).toList();
      if (mounted) {
        setState(() => _friends = availableFriends);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách bạn bè: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  Future<void> _inviteFriend(UserInfo friend) async {
    setState(() => _invitingFriendIds.add(friend.id));
    try {
      await widget.apiService.inviteFriendToFamily(widget.family.id, friend.id);
      if (mounted) {
        setState(() => _invitedFriendIds.add(friend.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi lời mời đến ${friend.fullName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _invitingFriendIds.remove(friend.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mời thành viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.qr_code), text: 'Mã mời'),
                Tab(icon: Icon(Icons.people), text: 'Bạn bè'),
              ],
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInviteCodeTab(),
                  _buildFriendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeTab() {
    if (_isLoadingCode) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.share, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Chia sẻ mã mời này cho bạn bè:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _inviteCode ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  tooltip: 'Sao chép',
                  onPressed: () {
                    if (_inviteCode != null) {
                      Clipboard.setData(ClipboardData(text: _inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép mã mời')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn bè có thể dùng mã này để tham gia gia đình',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không có bạn bè nào để mời',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tất cả bạn bè đều đã là thành viên hoặc bạn chưa có bạn bè',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        final isInviting = _invitingFriendIds.contains(friend.id);
        final isInvited = _invitedFriendIds.contains(friend.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              (friend.fullName?.isNotEmpty ?? false) ? friend.fullName![0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          title: Text(
            friend.fullName ?? friend.username,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text('@${friend.username}'),
          trailing: isInvited
              ? const Chip(
                  label: Text('Đã mời', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green,
                )
              : ElevatedButton(
                  onPressed: isInviting ? null : () => _inviteFriend(friend),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: isInviting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mời'),
                ),
        );
      },
    );
  }
}
