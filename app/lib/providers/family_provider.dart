import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/models/family_invitation_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FamilyProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<Family> _families = [];
  List<Family> get families => _families;

  Family? _selectedFamily;
  Family? get selectedFamily => _selectedFamily;

  List<FamilyMember> _members = [];
  List<FamilyMember> get members => _members;

  List<FamilyInvitation> _invitations = [];
  List<FamilyInvitation> get invitations => _invitations;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFamilies() async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _families = await _apiService.getFamilies();
      // Auto-select first family if none selected
      if (_selectedFamily == null && _families.isNotEmpty) {
        _selectedFamily = _families.first;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<void> selectFamily(int familyId) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      // Find family from local list or fetch from API
      _selectedFamily = _families.firstWhere(
        (f) => f.id == familyId,
        orElse: () => _families.first,
      );
      // Fetch family members
      _members = await _apiService.getFamilyMembers(familyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  void setSelectedFamily(Family family) {
    _selectedFamily = family;
    notifyListeners();
  }

  /// Creates a new family and then refetches the list of families.
  Future<bool> createFamily(Map<String, dynamic> familyData) async {
    _errorMessage = null;
    try {
      final newFamily = await _apiService.createFamily(familyData);
      _families.insert(0, newFamily);
      _selectedFamily = newFamily;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinFamily(String inviteCode) async {
    _errorMessage = null;
    try {
      final family = await _apiService.joinFamily(inviteCode);
      _families.add(family);
      _selectedFamily = family;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveFamily(int familyId) async {
    _errorMessage = null;
    try {
      await _apiService.leaveFamily(familyId);
      _families.removeWhere((f) => f.id == familyId);
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = _families.isNotEmpty ? _families.first : null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Family Invitations ---
  Future<void> fetchInvitations() async {
    try {
      _invitations = await _apiService.getFamilyInvitations();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> respondToInvitation(int invitationId, bool accept) async {
    _errorMessage = null;
    try {
      await _apiService.respondToFamilyInvitation(invitationId, accept);
      // Remove from local list
      _invitations.removeWhere((inv) => inv.id == invitationId);
      // If accepted, refresh families list
      if (accept) {
        await fetchFamilies();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
