import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/models/family_invitation_model.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FamilyProvider extends ChangeNotifier {
  final ApiService _apiService = locator<ApiService>();

  List<Family> _families = [];
  Family? _selectedFamily;
  List<FamilyMember> _members = [];
  List<FamilyInvitation> _invitations = [];
  String? _errorMessage;
  bool _isLoading = false;

  List<Family> get families => _families;
  Family? get selectedFamily => _selectedFamily;
  List<FamilyMember> get members => _members;
  List<FamilyInvitation> get invitations => _invitations;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchFamilies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _families = await _apiService.getFamilies();
      if (_selectedFamily == null && _families.isNotEmpty) {
        _selectedFamily = _families.first;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedFamily(Family family) {
    if (_selectedFamily?.id != family.id) {
      _selectedFamily = family;
      notifyListeners();
    }
  }

  Future<void> selectFamily(int familyId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedFamily = _families.firstWhere((f) => f.id == familyId, orElse: () => _families.first);
      _members = await _apiService.getFamilyMembers(familyId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFamily(Map<String, dynamic> familyData, {XFile? image}) async {
    _setLoading(true);
    try {
      final family = await _apiService.createFamily(familyData);
      // TODO: Handle image upload if API supports it in createFamily
      _families.insert(0, family);
      _selectedFamily = family;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateFamily(int familyId, Map<String, dynamic> familyData, {XFile? image}) async {
    _setLoading(true);
    try {
      final updatedFamily = await _apiService.updateFamilyWithImage(familyId, familyData, image: image);
      final index = _families.indexWhere((f) => f.id == familyId);
      if (index != -1) {
        _families[index] = updatedFamily;
      }
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = updatedFamily;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteImage(int familyId) async {
    _setLoading(true);
    try {
      final updatedFamily = await _apiService.deleteFamilyImage(familyId);
      final index = _families.indexWhere((f) => f.id == familyId);
      if (index != -1) {
        _families[index] = updatedFamily;
      }
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = updatedFamily;
      }
       _setLoading(false);
      return true;
    } catch (e) {
       _setLoading(false);
      return false;
    }
  }


  Future<bool> joinFamily(String inviteCode) async {
    _setLoading(true);
    try {
      final family = await _apiService.joinFamily(inviteCode);
      if (!_families.any((f) => f.id == family.id)) {
        _families.add(family);
      }
      _selectedFamily = family;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> leaveFamily(int familyId) async {
    _setLoading(true);
    try {
      await _apiService.leaveFamily(familyId);
      _families.removeWhere((f) => f.id == familyId);
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = _families.isNotEmpty ? _families.first : null;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchInvitations() async {
    try {
      _invitations = await _apiService.getFamilyInvitations();
      notifyListeners();
    } catch (e) {
      // silent fail is ok
    }
  }

  Future<bool> respondToInvitation(int invitationId, bool accept) async {
    try {
      await _apiService.respondToFamilyInvitation(invitationId, accept);
      _invitations.removeWhere((inv) => inv.id == invitationId);
      if (accept) {
        await fetchFamilies();
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
