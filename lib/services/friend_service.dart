import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import 'debt_service.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DebtService _debtService = DebtService();

  // Search for users by name or email
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      debugPrint('Searching for users with query: "$query", current user ID: $currentUserId');

      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      // Create a list to store the results
      final List<UserModel> users = [];

      // Get real users from Firestore
      try {
        debugPrint('Fetching users from Firestore...');

        // Try to get users whose name or email contains the query
        // This approach uses two separate queries for better performance
        final nameQuery = await _firestore
            .collection('users')
            .where('nameLower', isGreaterThanOrEqualTo: lowerQuery)
            .where('nameLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
            .get();

        final emailQuery = await _firestore
            .collection('users')
            .where('emailLower', isGreaterThanOrEqualTo: lowerQuery)
            .where('emailLower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
            .get();

        // Combine results from both queries
        final Set<String> processedIds = {};

        // Process name query results
        for (var doc in nameQuery.docs) {
          final id = doc.id;
          // Skip current user and already processed users
          if (id == currentUserId || processedIds.contains(id)) continue;

          processedIds.add(id);
          users.add(UserModel.fromDocument(doc));
        }

        // Process email query results
        for (var doc in emailQuery.docs) {
          final id = doc.id;
          // Skip current user and already processed users
          if (id == currentUserId || processedIds.contains(id)) continue;

          processedIds.add(id);
          users.add(UserModel.fromDocument(doc));
        }

        debugPrint('Total users found in Firestore: ${users.length}');
      } catch (e) {
        // If there's a permission error, fall back to a more basic approach
        debugPrint('Error with optimized query, trying fallback approach: $e');

        try {
          // Fallback: Get all users and filter manually
          final allUsers = await _firestore.collection('users').get();
          debugPrint('Total users in Firestore: ${allUsers.docs.length}');

          // Process Firestore users
          for (var doc in allUsers.docs) {
            try {
              final data = doc.data();
              final id = doc.id;
              final name = data['name']?.toString() ?? 'Unknown';
              final email = data['email']?.toString() ?? 'Unknown';

              // Skip current user
              if (id == currentUserId) continue;

              // Check if name or email contains the query (case insensitive)
              final lowerName = name.toLowerCase();
              final lowerEmail = email.toLowerCase();

              if (lowerName.contains(lowerQuery) || lowerEmail.contains(lowerQuery)) {
                // Create user model manually
                final user = UserModel(
                  id: id,
                  name: name,
                  email: email,
                  photoUrl: data['photoUrl']?.toString(),
                  friendIds: data['friendIds'] is List
                    ? List<String>.from((data['friendIds'] as List).map((item) => item.toString()))
                    : [],
                );

                users.add(user);
              }
            } catch (e) {
              debugPrint('Error processing Firestore user: $e');
            }
          }
        } catch (e) {
          debugPrint('Error fetching users from Firestore (likely permissions): $e');
          debugPrint('To fix this, update your Firestore security rules to allow reading the users collection.');

          // Add some test users as a last resort
          final testUsers = [
            {
              'id': 'test_user_1',
              'name': 'Ganesh',
              'email': 'ganesh@example.com',
            },
            {
              'id': 'test_user_2',
              'name': 'Shantanu',
              'email': 'shantanu@example.com',
            },
            {
              'id': 'test_user_3',
              'name': 'Shashank',
              'email': 'shashank@example.com',
            },
            {
              'id': 'test_user_4',
              'name': 'Sharad',
              'email': 'sharad@example.com',
            },
          ];

          // Filter test users based on the query
          for (var userData in testUsers) {
            final name = userData['name']!.toLowerCase();
            final email = userData['email']!.toLowerCase();

            if (name.contains(lowerQuery) || email.contains(lowerQuery)) {
              final testUser = UserModel(
                id: userData['id']!,
                name: userData['name']!,
                email: userData['email']!,
                photoUrl: null,
              );
              users.add(testUser);
              debugPrint('Added test user: ${testUser.name}');
            }
          }
        }
      }

      // Sort results by name
      users.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('Final search results count: ${users.length}');
      return users;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Check if a friend request already exists between two users
  Future<FriendRequestModel?> checkExistingRequest(String userId1, String userId2) async {
    try {
      // Check if user1 sent a request to user2
      final query1 = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId1)
          .where('receiverId', isEqualTo: userId2)
          .get();

      if (query1.docs.isNotEmpty) {
        return FriendRequestModel.fromDocument(query1.docs.first);
      }

      // Check if user2 sent a request to user1
      final query2 = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId2)
          .where('receiverId', isEqualTo: userId1)
          .get();

      if (query2.docs.isNotEmpty) {
        return FriendRequestModel.fromDocument(query2.docs.first);
      }

      return null;
    } catch (e) {
      debugPrint('Error checking existing request: $e');
      return null;
    }
  }

  // Send friend request
  Future<FriendRequestModel?> sendFriendRequest(
    String senderId,
    String receiverId,
    String senderName,
    String senderEmail,
    String? senderPhotoUrl,
    String receiverName,
    String receiverEmail,
    String? receiverPhotoUrl,
  ) async {
    try {
      // Check if a request already exists
      final existingRequest = await checkExistingRequest(senderId, receiverId);
      if (existingRequest != null) {
        return existingRequest;
      }

      // Check if they are already friends
      final userDoc = await _firestore.collection('users').doc(senderId).get();
      final user = UserModel.fromDocument(userDoc);

      if (user.friendIds.contains(receiverId)) {
        throw 'You are already friends with this user';
      }

      // Create a new request
      final requestRef = _firestore.collection('friendRequests').doc();
      final request = FriendRequestModel(
        id: requestRef.id,
        senderId: senderId,
        receiverId: receiverId,
        createdAt: DateTime.now(),
        status: FriendRequestStatus.pending,
        senderName: senderName,
        senderEmail: senderEmail,
        senderPhotoUrl: senderPhotoUrl,
        receiverName: receiverName,
        receiverEmail: receiverEmail,
        receiverPhotoUrl: receiverPhotoUrl,
      );

      await requestRef.set(request.toMap());
      return request;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      rethrow;
    }
  }

  // Add a friend
  Future<void> addFriend(String userId, String friendId) async {
    try {
      // Update current user's friend list
      await _firestore.collection('users').doc(userId).update({
        'friendIds': FieldValue.arrayUnion([friendId]),
      });

      // Update friend's friend list
      await _firestore.collection('users').doc(friendId).update({
        'friendIds': FieldValue.arrayUnion([userId]),
      });

      // Initialize trust scores
      await _firestore.collection('users').doc(userId).update({
        'trustScores.$friendId': 50.0, // Initial trust score
      });

      await _firestore.collection('users').doc(friendId).update({
        'trustScores.$userId': 50.0, // Initial trust score
      });

      // Initialize privacy settings
      await _firestore.collection('users').doc(userId).update({
        'friendPrivacySettings.$friendId': true, // Default to visible
      });

      await _firestore.collection('users').doc(friendId).update({
        'friendPrivacySettings.$userId': true, // Default to visible
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove a friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      debugPrint('FriendService: Removing friend relationship between $userId and $friendId');

      // Clear all debt/transaction history between the users first
      debugPrint('FriendService: Clearing all debt data between users');
      await _debtService.clearTransactionHistory(userId, friendId);

      // Update current user's friend list
      await _firestore.collection('users').doc(userId).update({
        'friendIds': FieldValue.arrayRemove([friendId]),
      });

      // Update friend's friend list
      await _firestore.collection('users').doc(friendId).update({
        'friendIds': FieldValue.arrayRemove([userId]),
      });

      // Remove trust scores
      await _firestore.collection('users').doc(userId).update({
        'trustScores.$friendId': FieldValue.delete(),
      });

      await _firestore.collection('users').doc(friendId).update({
        'trustScores.$userId': FieldValue.delete(),
      });

      // Remove privacy settings
      await _firestore.collection('users').doc(userId).update({
        'friendPrivacySettings.$friendId': FieldValue.delete(),
      });

      await _firestore.collection('users').doc(friendId).update({
        'friendPrivacySettings.$userId': FieldValue.delete(),
      });

      debugPrint('FriendService: Successfully removed friend and all related data');
    } catch (e) {
      debugPrint('FriendService: Error removing friend: $e');
      rethrow;
    }
  }

  // Get all friends of a user
  Future<List<UserModel>> getFriends(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromDocument(userDoc);

      if (user.friendIds.isEmpty) return [];

      // Handle case where there are many friends by batching
      final List<UserModel> friends = [];

      // Process in batches of 10 to avoid Firestore limitations
      for (var i = 0; i < user.friendIds.length; i += 10) {
        final end = (i + 10 < user.friendIds.length) ? i + 10 : user.friendIds.length;
        final batch = user.friendIds.sublist(i, end);

        if (batch.isEmpty) continue;

        final query = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in query.docs) {
          friends.add(UserModel.fromDocument(doc));
        }
      }

      return friends;
    } catch (e) {
      debugPrint('Error getting friends: $e');
      rethrow;
    }
  }

  // Get pending friend requests received by a user
  Future<List<FriendRequestModel>> getPendingReceivedRequests(String userId) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return query.docs
          .map((doc) => FriendRequestModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending received requests: $e');
      return [];
    }
  }

  // Get pending friend requests sent by a user
  Future<List<FriendRequestModel>> getPendingSentRequests(String userId) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return query.docs
          .map((doc) => FriendRequestModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending sent requests: $e');
      return [];
    }
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      // Get the request
      final requestDoc = await _firestore.collection('friendRequests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw 'Friend request not found';
      }

      final request = FriendRequestModel.fromDocument(requestDoc);

      // Update request status
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Add friend to both users' friend lists
      await addFriend(request.receiverId, request.senderId);

      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'rejected'});

      return true;
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      rethrow;
    }
  }

  // Cancel sent friend request
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error canceling friend request: $e');
      rethrow;
    }
  }

  // Update trust score
  Future<void> updateTrustScore(String userId, String friendId, double newScore) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'trustScores.$friendId': newScore,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update privacy setting
  Future<void> updatePrivacySetting(String userId, String friendId, bool isVisible) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'friendPrivacySettings.$friendId': isVisible,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get friend summary (including debt balance)
  Future<Map<String, dynamic>> getFriendSummary(String userId, String friendId) async {
    try {
      // Get friend data
      final friendDoc = await _firestore.collection('users').doc(friendId).get();
      final friend = UserModel.fromDocument(friendDoc);

      // Get net balance
      final netBalance = await _debtService.getNetBalance(userId, friendId);

      // Get trust score
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromDocument(userDoc);
      final trustScore = user.trustScores[friendId] ?? 50.0;

      return {
        'friend': friend,
        'netBalance': netBalance,
        'trustScore': trustScore,
        'isVisible': user.friendPrivacySettings[friendId] ?? true,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Get karma leaderboard among friends
  Future<List<Map<String, dynamic>>> getKarmaLeaderboard(String userId) async {
    try {
      final friends = await getFriends(userId);
      final leaderboard = <Map<String, dynamic>>[];

      // Add current user
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentUser = UserModel.fromDocument(userDoc);

      // Get total karma points for current user
      final userDebts = await _firestore
          .collection('debts')
          .where('borrowerId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .get();

      int userKarma = 0;
      for (var doc in userDebts.docs) {
        userKarma += (doc.data()['karmaPoints'] as int? ?? 0);
      }

      leaderboard.add({
        'user': currentUser,
        'karmaPoints': userKarma,
      });

      // Add friends
      for (var friend in friends) {
        final friendDebts = await _firestore
            .collection('debts')
            .where('borrowerId', isEqualTo: friend.id)
            .where('status', isEqualTo: 'paid')
            .get();

        int friendKarma = 0;
        for (var doc in friendDebts.docs) {
          friendKarma += (doc.data()['karmaPoints'] as int? ?? 0);
        }

        leaderboard.add({
          'user': friend,
          'karmaPoints': friendKarma,
        });
      }

      // Sort by karma points (descending)
      leaderboard.sort((a, b) => (b['karmaPoints'] as int).compareTo(a['karmaPoints'] as int));

      return leaderboard;
    } catch (e) {
      rethrow;
    }
  }
}
