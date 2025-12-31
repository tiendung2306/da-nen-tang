import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';
import 'package:flutter_boilerplate/providers/friend_provider.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/pages/auth/user_search_page.dart';
import 'package:flutter_boilerplate/constants/api_config.dart'; // For getImageUrl

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
      context.read<FriendProvider>().fetchAll();
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

  Widget _buildProfileInfoTab() {
    final authProvider = context.watch<AuthProvider>();
    final userInfo = authProvider.userInfo;
    if (userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final avatarUrl = ApiConfig.getImageUrl(userInfo.avatarUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50, 
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 32),
          _buildInfoRow(label: 'Tên tài khoản', value: userInfo.fullName),
          _buildInfoRow(label: 'Email', value: userInfo.email),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: () => authProvider.logout(), child: const Text('Đăng xuất')),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Scaffold(
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.friends.isEmpty) {
            return const Center(child: Text('Chưa có bạn bè nào.'));
          }
          return ListView.builder(
            itemCount: friendProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendProvider.friends[index];
              return ListTile(
                leading: CircleAvatar(child: Text(friend.fullName.substring(0, 1))),
                title: Text(friend.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.red),
                  onPressed: () => _showUnfriendDialog(context, friend),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserSearchPage())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final received = friendProvider.receivedRequests;
        final sent = friendProvider.sentRequests;
        if (received.isEmpty && sent.isEmpty) {
          return const Center(child: Text('Không có lời mời nào.'));
        }
        return ListView(
          children: [
            if (received.isNotEmpty) _buildRequestList(title: 'Lời mời đã nhận', requests: received, isReceived: true),
            if (sent.isNotEmpty) _buildRequestList(title: 'Lời mời đã gửi', requests: sent, isReceived: false),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Expanded(child: Text(value, style: const TextStyle(fontSize: 16)))]));
  }

  void _showUnfriendDialog(BuildContext context, UserInfo friend) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Xác nhận'), content: Text('Bạn có chắc muốn hủy kết bạn với ${friend.fullName}?'), actions: [TextButton(child: const Text('Không'), onPressed: () => Navigator.of(ctx).pop()), TextButton(child: const Text('Có'), onPressed: () { context.read<FriendProvider>().removeFriend(friend.id.toString()); Navigator.of(ctx).pop(); })]));
  }

  Widget _buildRequestList({required String title, required List<FriendRequest> requests, required bool isReceived}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(16), child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: requests.length, itemBuilder: (context, index) { 
        final request = requests[index];
        final user = isReceived ? request.requester : request.addressee;
        if (user == null) return const SizedBox.shrink();
        return ListTile(
          leading: CircleAvatar(child: Text(user.fullName.substring(0, 1))),
          title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: isReceived 
            ? Row(mainAxisSize: MainAxisSize.min, children: [ElevatedButton(onPressed: () => context.read<FriendProvider>().respondToRequest(request.id.toString(), true), child: const Text('Chấp nhận')), const SizedBox(width: 8), OutlinedButton(onPressed: () => context.read<FriendProvider>().respondToRequest(request.id.toString(), false), child: const Text('Từ chối'))])
            : OutlinedButton(onPressed: () => context.read<FriendProvider>().cancelRequest(request.id.toString()), child: const Text('Hủy')),
        );
      }),
    ]);
  }
}
