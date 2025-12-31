import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/providers/friend_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class UserSearchPage extends StatefulWidget {
  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final ApiService _apiService = locator<ApiService>();
  List<UserInfo> _searchResults = [];
  bool _isLoading = false;

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _apiService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm bạn bè')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(labelText: 'Nhập tên người dùng', suffixIcon: Icon(Icons.search)),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
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
  FriendshipStatus _status = FriendshipStatus.not_friends;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
  }

  Future<void> _checkFriendStatus() async {
    try {
      final response = await context.read<FriendProvider>().checkFriendStatus(widget.user.id.toString());
      setState(() {
        _status = response.friendshipStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _sendRequest() {
    setState(() => _isLoading = true);
    context.read<FriendProvider>().sendRequest(widget.user.id.toString()).then((_) {
      _checkFriendStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(widget.user.fullName.substring(0, 1))),
      title: Text(widget.user.fullName),
      subtitle: Text(widget.user.username),
      trailing: _isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: _status == FriendshipStatus.not_friends ? _sendRequest : null,
              child: Text(_status == FriendshipStatus.request_sent ? 'Đã gửi' : 'Kết bạn'),
            ),
    );
  }
}
