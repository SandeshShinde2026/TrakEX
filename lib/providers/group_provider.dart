import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user's groups
  Future<void> loadUserGroups(String userId) async {
    debugPrint('GroupProvider: Loading groups for user: $userId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups(userId);
      debugPrint('GroupProvider: Loaded ${_groups.length} groups');
      for (var group in _groups) {
        debugPrint('GroupProvider: Group: ${group.name} (ID: ${group.id}, Members: ${group.memberCount})');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('GroupProvider: Error loading groups: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create a new group
  Future<GroupModel?> createGroup({
    required String name,
    required String createdBy,
    required List<String> memberIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final group = await _groupService.createGroup(
        name: name,
        createdBy: createdBy,
        memberIds: memberIds,
      );

      if (group != null) {
        _groups.insert(0, group); // Add to beginning of list
      }

      _isLoading = false;
      notifyListeners();
      return group;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update group
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    List<String>? memberIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        memberIds: memberIds,
      );

      if (success) {
        // Update local group
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          final updatedGroup = _groups[index].copyWith(
            name: name,
            memberIds: memberIds,
            updatedAt: DateTime.now(),
          );
          _groups[index] = updatedGroup;
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add member to group
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      final success = await _groupService.addMemberToGroup(groupId, userId);
      
      if (success) {
        // Update local group
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          final currentMembers = List<String>.from(_groups[index].memberIds);
          if (!currentMembers.contains(userId)) {
            currentMembers.add(userId);
            _groups[index] = _groups[index].copyWith(
              memberIds: currentMembers,
              updatedAt: DateTime.now(),
            );
            notifyListeners();
          }
        }
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove member from group
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final success = await _groupService.removeMemberFromGroup(groupId, userId);
      
      if (success) {
        // Update local group
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          final currentMembers = List<String>.from(_groups[index].memberIds);
          currentMembers.remove(userId);
          _groups[index] = _groups[index].copyWith(
            memberIds: currentMembers,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete group
  Future<bool> deleteGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _groupService.deleteGroup(groupId);
      
      if (success) {
        _groups.removeWhere((g) => g.id == groupId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get group by ID
  GroupModel? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  // Get group by ID from server
  Future<GroupModel?> getGroupByIdFromServer(String groupId) async {
    try {
      return await _groupService.getGroup(groupId);
    } catch (e) {
      debugPrint('GroupProvider: Error getting group from server: $e');
      return null;
    }
  }

  // Get groups where user is a member
  List<GroupModel> getGroupsForUser(String userId) {
    return _groups.where((group) => group.isMember(userId)).toList();
  }

  // Get groups created by user
  List<GroupModel> getGroupsCreatedBy(String userId) {
    return _groups.where((group) => group.isCreator(userId)).toList();
  }

  // Get group members (returns UserModel list if you have access to friends)
  List<String> getGroupMemberIds(String groupId) {
    final group = getGroupById(groupId);
    return group?.memberIds ?? [];
  }

  // Clear data
  void clearData() {
    _groups.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Refresh groups
  Future<void> refreshGroups(String userId) async {
    await loadUserGroups(userId);
  }
}
