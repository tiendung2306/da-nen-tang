import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/friend_provider.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';

class UserSearchPage extends StatefulWidget {
  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<UserInfo> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _apiService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm bạn bè'),
        backgroundColor: const Color(0xFFF26F21),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập email hoặc tên để tìm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return UserTile(user: user);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class UserTile extends StatefulWidget {
  final UserInfo user;
  const UserTile({Key? key, required this.user}) : super(key: key);

  @override
  _UserTileState createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late Future<FriendStatusResponse> _statusFuture;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  void _fetchStatus() {
    if (mounted) {
      setState(() {
        _statusFuture = context.read<FriendProvider>().checkFriendStatus(widget.user.id.toString());
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    final friendProvider = context.read<FriendProvider>();
    try {
      setState(() { _statusFuture = Future.value(FriendStatusResponse(status: 'request_sent')); });
      await friendProvider.sendRequest(widget.user.id.toString());
      _fetchStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      _fetchStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FriendStatusResponse>(
      future: _statusFuture,
      builder: (context, snapshot) {
        Widget trailingButton;

        if (snapshot.connectionState == ConnectionState.waiting) {
          trailingButton = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0));
        } else if (snapshot.hasError) {
          trailingButton = IconButton(icon: const Icon(Icons.refresh, color: Colors.red), onPressed: _fetchStatus);
        } else if (snapshot.hasData) {
          trailingButton = _buildButtonForStatus(context, snapshot.data!.friendshipStatus);
        } else {
          trailingButton = const SizedBox.shrink();
        }

        return ListTile(
          leading: CircleAvatar(child: Text(widget.user.name.substring(0, 1))),
          title: Text(widget.user.name),
          subtitle: Text(widget.user.email ?? widget.user.username),
          trailing: trailingButton,
        );
      },
    );
  }

  Widget _buildButtonForStatus(BuildContext context, FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.not_friends:
        return ElevatedButton(onPressed: _sendFriendRequest, child: const Text('Kết bạn'));
      case FriendshipStatus.request_sent:
        return OutlinedButton(onPressed: null, child: const Text('Đã gửi'));
      case FriendshipStatus.request_received:
        return ElevatedButton(onPressed: () {}, child: const Text('Phản hồi'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber));
      case FriendshipStatus.friends:
        return TextButton(onPressed: null, child: const Text('Bạn bè'));
    }
  }
}
