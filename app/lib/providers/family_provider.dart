import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/models/family_invitation_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FamilyProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<Family> _families = [];
  Family? _selectedFamily;
  List<FamilyMember> _members = [];
  List<FamilyInvitation> _invitations = [];
  String? _errorMessage;

  List<Family> get families => _families;
  Family? get selectedFamily => _selectedFamily;
  List<FamilyMember> get members => _members;
  List<FamilyInvitation> get invitations => _invitations;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFamilies() async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;

    try {
      _families = await _apiService.getFamilies();
      if (_selectedFamily == null && _families.isNotEmpty) {
        _selectedFamily = _families.first;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  void setSelectedFamily(Family family) {
    if (_selectedFamily?.id != family.id) {
      _selectedFamily = family;
      notifyListeners();
    }
  }

  Future<void> selectFamily(int familyId) async {
    setStatus(ViewStatus.Loading);
    try {
      _selectedFamily = _families.firstWhere((f) => f.id == familyId, orElse: () => _families.first);
      _members = await _apiService.getFamilyMembers(familyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<bool> createFamily(Map<String, dynamic> familyData, {XFile? image}) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      final newFamily = await _apiService.createFamily(familyData, image: image);
      _families.insert(0, newFamily);
      _selectedFamily = newFamily;
      setStatus(ViewStatus.Ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      setStatus(ViewStatus.Ready);
      return false;
    }
  }

  Future<bool> updateFamily(int familyId, Map<String, dynamic> familyData, {XFile? image}) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      final updatedFamily = await _apiService.updateFamilyWithImage(familyId, familyData, image: image);
      final index = _families.indexWhere((f) => f.id == familyId);
      if (index != -1) {
        _families[index] = updatedFamily;
      }
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = updatedFamily;
      }
      setStatus(ViewStatus.Ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      setStatus(ViewStatus.Ready);
      return false;
    }
  }

  Future<bool> joinFamily(String inviteCode) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      final family = await _apiService.joinFamily(inviteCode);
      if (!_families.any((f) => f.id == family.id)) {
        _families.add(family);
      }
      _selectedFamily = family;
      setStatus(ViewStatus.Ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      setStatus(ViewStatus.Ready);
      return false;
    }
  }

  Future<bool> leaveFamily(int familyId) async {
    setStatus(ViewStatus.Loading);
    try {
      await _apiService.leaveFamily(familyId);
      _families.removeWhere((f) => f.id == familyId);
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = _families.isNotEmpty ? _families.first : null;
      }
      setStatus(ViewStatus.Ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      setStatus(ViewStatus.Ready);
      return false;
    }
  }

  Future<bool> deleteImage(int familyId) async {
    setStatus(ViewStatus.Loading);
    try {
      final updatedFamily = await _apiService.deleteFamilyImage(familyId);
      final index = _families.indexWhere((f) => f.id == familyId);
      if (index != -1) {
        _families[index] = updatedFamily;
      }
      if (_selectedFamily?.id == familyId) {
        _selectedFamily = updatedFamily;
      }
      setStatus(ViewStatus.Ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      setStatus(ViewStatus.Ready);
      return false;
    }
  }

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
      _invitations.removeWhere((inv) => inv.id == invitationId);
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
