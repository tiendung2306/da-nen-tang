import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart'; // Import locator

class FriendProvider extends BaseProvider {
  // FIX: Get the singleton instance of ApiService from the locator.
  final ApiService _apiService = locator<ApiService>();

  List<UserInfo> _friends = [];
  List<FriendRequest> _receivedRequests = [];
  List<FriendRequest> _sentRequests = [];

  List<UserInfo> get friends => _friends;
  List<FriendRequest> get receivedRequests => _receivedRequests;
  List<FriendRequest> get sentRequests => _sentRequests;

  Future<void> fetchAll() async {
    setStatus(ViewStatus.Loading);
    try {
      await Future.wait([
        fetchFriends(),
        fetchReceivedRequests(),
        fetchSentRequests(),
      ]);
    } catch (e) {
      // Handle errors, maybe show a message to the user
      print('Error fetching friend data: $e');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<void> fetchFriends() async {
    _friends = await _apiService.getFriends();
    notifyListeners();
  }

  Future<void> fetchReceivedRequests() async {
    _receivedRequests = await _apiService.getReceivedFriendRequests();
    notifyListeners();
  }

  Future<void> fetchSentRequests() async {
    _sentRequests = await _apiService.getSentFriendRequests();
    notifyListeners();
  }

  Future<void> sendRequest(String userId) async {
    await _apiService.sendFriendRequest(userId: userId);
    await fetchSentRequests(); 
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await _apiService.respondToFriendRequest(requestId: requestId, accept: accept);
    await Future.wait([fetchReceivedRequests(), if (accept) fetchFriends()]);
  }

  Future<void> cancelRequest(String requestId) async {
    await _apiService.cancelFriendRequest(requestId: requestId);
    await fetchSentRequests();
  }

  Future<void> removeFriend(String userId) async {
    await _apiService.unfriend(userId: userId);
    await fetchFriends();
  }

  Future<FriendStatusResponse> checkFriendStatus(String userId) async {
    return await _apiService.getFriendStatus(userId: userId);
  }
}
