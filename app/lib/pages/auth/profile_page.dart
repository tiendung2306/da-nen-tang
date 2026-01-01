import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';
import 'package:flutter_boilerplate/providers/friend_provider.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/pages/auth/landing_page.dart';
import 'package:flutter_boilerplate/constants/api_config.dart';
import 'user_search_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendProvider>(context, listen: false).fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Center(
          child: Text('Tài Khoản & Bạn Bè', style: TextStyle(color: Colors.black)),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF26F21),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF26F21),
          tabs: const [
            Tab(icon: Icon(Icons.person)),
            Tab(icon: Icon(Icons.people)),
            Tab(icon: Icon(Icons.inbox)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileInfoTab(),
          _buildFriendsTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  // Tab 1: Personal Information - Restored
  Widget _buildProfileInfoTab() {
    final authProvider = context.watch<AuthProvider>();
    final userInfo = authProvider.userInfo;
    if (userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final avatarUrl = ApiConfig.getImageUrl(userInfo.avatarUrl);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showAvatarOptions(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFF0F0F0),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          userInfo.fullName.isNotEmpty ? userInfo.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 40, color: Colors.grey),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF26F21),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn để thay đổi ảnh đại diện',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(label: 'Tên tài khoản', value: userInfo.fullName),
          _buildInfoRow(label: 'Email', value: userInfo.email ?? ''),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
              child: const Text('Đăng xuất', style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final hasAvatar = authProvider.userInfo?.avatarUrl != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFF26F21)),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF26F21)),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa ảnh đại diện', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAvatar();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (pickedFile != null) {
      try {
        await context.read<AuthProvider>().uploadAvatar(pickedFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa ảnh đại diện?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await context.read<AuthProvider>().deleteAvatar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ảnh đại diện!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Tab 2: Friends List - Restored
  Widget _buildFriendsTab() {
    return Scaffold(
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.viewStatus == ViewStatus.Loading && friendProvider.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (friendProvider.friends.isEmpty) {
            return const Center(child: Text('Chưa có bạn bè nào.\nNhấn nút + để tìm bạn.'));
          }
          return RefreshIndicator(
            onRefresh: () => friendProvider.fetchFriends(),
            child: ListView.builder(
              itemCount: friendProvider.friends.length,
              itemBuilder: (context, index) {
                final friend = friendProvider.friends[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(friend.name.substring(0, 1))),
                  title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () => _showUnfriendDialog(context, friend),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserSearchPage())),
        child: const Icon(Icons.add), 
        backgroundColor: const Color(0xFFF26F21),
      ),
    );
  }

  // Tab 3: Friend Requests - Restored
  Widget _buildRequestsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.viewStatus == ViewStatus.Loading && friendProvider.receivedRequests.isEmpty && friendProvider.sentRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final validReceived = friendProvider.receivedRequests.where((r) => r.requester != null).toList();
        final validSent = friendProvider.sentRequests.where((r) => r.addressee != null).toList();

        return RefreshIndicator(
          onRefresh: () => Future.wait([friendProvider.fetchReceivedRequests(), friendProvider.fetchSentRequests()]),
          child: ListView(
            children: [
              _buildRequestList(title: 'Lời mời đã nhận', requests: validReceived, isReceived: true),
              _buildRequestList(title: 'Lời mời đã gửi', requests: validSent, isReceived: false),
            ],
          ),
        );
      },
    );
  }

  // Helper Widgets - All restored
  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Expanded(child: Text(value, style: const TextStyle(fontSize: 16)))]));
  }

  void _showUnfriendDialog(BuildContext context, UserInfo friend) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Xác nhận'), content: Text('Bạn có chắc muốn hủy kết bạn với ${friend.name}?'), actions: [TextButton(child: const Text('Không'), onPressed: () => Navigator.of(ctx).pop()), TextButton(child: const Text('Có', style: TextStyle(color: Colors.red)), onPressed: () { context.read<FriendProvider>().removeFriend(friend.id.toString()); Navigator.of(ctx).pop(); })]));
  }

  Widget _buildRequestList({required String title, required List<FriendRequest> requests, required bool isReceived}) {
    if (requests.isEmpty) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 24.0), child: Center(child: Text('Không có $title nào.', style: const TextStyle(color: Colors.grey))));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black))), ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: requests.length, itemBuilder: (context, index) { final request = requests[index]; final user = isReceived ? request.requester! : request.addressee!; return ListTile(leading: CircleAvatar(child: Text(user.name.substring(0, 1))), title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: isReceived ? _buildRespondButtons(context, request.id.toString()) : _buildCancelButton(context, request.id.toString())); }), const Divider()]);
  }

  Widget _buildRespondButtons(BuildContext context, String requestId) {
    final friendProvider = context.read<FriendProvider>();
    return Row(mainAxisSize: MainAxisSize.min, children: [ElevatedButton(onPressed: () => friendProvider.respondToRequest(requestId, true), child: const Text('Chấp nhận')), const SizedBox(width: 8), OutlinedButton(onPressed: () => friendProvider.respondToRequest(requestId, false), child: const Text('Từ chối'))]);
  }

  Widget _buildCancelButton(BuildContext context, String requestId) {
    final friendProvider = context.read<FriendProvider>();
    return OutlinedButton(onPressed: () => friendProvider.cancelRequest(requestId), child: const Text('Hủy'));
  }
}
