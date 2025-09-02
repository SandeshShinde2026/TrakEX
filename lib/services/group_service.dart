import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'groups';

  // Create a new group
  Future<GroupModel?> createGroup({
    required String name,
    required String createdBy,
    required List<String> memberIds,
  }) async {
    try {
      debugPrint('GroupService: Creating group "$name" by user: $createdBy');
      debugPrint('GroupService: Initial member IDs: $memberIds');

      // Ensure creator is included in members
      final allMemberIds = <String>{createdBy, ...memberIds}.toList();
      debugPrint('GroupService: All member IDs (including creator): $allMemberIds');

      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();

      final group = GroupModel(
        id: docRef.id,
        name: name,
        createdBy: createdBy,
        memberIds: allMemberIds,
        createdAt: now,
        updatedAt: now,
      );

      debugPrint('GroupService: Saving group to Firestore with ID: ${docRef.id}');
      await docRef.set(group.toMap());
      debugPrint('GroupService: Group created successfully: ${group.name}');
      return group;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  // Get all groups for a user
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      debugPrint('GroupService: Querying groups for user: $userId');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      debugPrint('GroupService: Found ${querySnapshot.docs.length} group documents');

      final groups = querySnapshot.docs
          .map((doc) => GroupModel.fromDocument(doc))
          .toList();

      for (var group in groups) {
        debugPrint('GroupService: Group: ${group.name} (ID: ${group.id}, Members: ${group.memberIds})');
      }

      return groups;
    } catch (e) {
      debugPrint('Error getting user groups: $e');
      return [];
    }
  }

  // Get a specific group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(groupId).get();
      
      if (doc.exists) {
        return GroupModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting group: $e');
      return null;
    }
  }

  // Update group details
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    List<String>? memberIds,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) {
        updateData['name'] = name;
      }

      if (memberIds != null) {
        updateData['memberIds'] = memberIds;
      }

      await _firestore.collection(_collection).doc(groupId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating group: $e');
      return false;
    }
  }

  // Add member to group
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding member to group: $e');
      return false;
    }
  }

  // Remove member from group
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing member from group: $e');
      return false;
    }
  }

  // Delete group
  Future<bool> deleteGroup(String groupId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting group: $e');
      return false;
    }
  }

  // Get groups created by a specific user
  Future<List<GroupModel>> getGroupsCreatedBy(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GroupModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting groups created by user: $e');
      return [];
    }
  }

  // Stream groups for real-time updates
  Stream<List<GroupModel>> streamUserGroups(String userId) {
    return _firestore
        .collection(_collection)
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromDocument(doc))
            .toList());
  }
}
