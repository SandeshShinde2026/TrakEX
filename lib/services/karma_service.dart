import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/karma_model.dart';
import '../models/debt_model.dart';

class KarmaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Calculate karma points based on repayment speed
  int calculateKarmaPoints(DateTime borrowTimestamp, DateTime repaymentTimestamp) {
    final Duration repaymentTime = repaymentTimestamp.difference(borrowTimestamp);
    final int hoursElapsed = repaymentTime.inHours;

    // Apply karma points based on repayment speed
    if (hoursElapsed <= 1) {
      return 100; // Within 1 hour
    } else if (hoursElapsed <= 6) {
      return 80; // Within 2-6 hours
    } else if (hoursElapsed <= 12) {
      return 60; // Within 6-12 hours
    } else if (hoursElapsed <= 24) {
      return 40; // Within 12-24 hours
    } else if (hoursElapsed <= 48) {
      return 20; // Within 1-2 days
    } else {
      return 5; // After 2+ days
    }
  }

  /// Determine badge level based on total karma points
  KarmaBadgeLevel determineBadgeLevel(int totalPoints) {
    if (totalPoints >= 900) {
      return KarmaBadgeLevel.topRepayer;
    } else if (totalPoints >= 700) {
      return KarmaBadgeLevel.reliableBuddy;
    } else if (totalPoints >= 500) {
      return KarmaBadgeLevel.okayishRepayer;
    } else if (totalPoints >= 300) {
      return KarmaBadgeLevel.slowPayer;
    } else {
      return KarmaBadgeLevel.leastTrusted;
    }
  }

  /// Get user's karma model
  Future<KarmaModel> getUserKarma(String userId) async {
    try {
      final karmaDoc = await _firestore.collection('karma').doc(userId).get();

      if (karmaDoc.exists) {
        return KarmaModel.fromDocument(karmaDoc);
      } else {
        // Create a new karma model if it doesn't exist
        final newKarma = KarmaModel(
          userId: userId,
          totalPoints: 0,
          badgeLevel: KarmaBadgeLevel.leastTrusted,
          lastUpdated: DateTime.now(),
        );

        await _firestore.collection('karma').doc(userId).set(newKarma.toMap());
        return newKarma;
      }
    } catch (e) {
      debugPrint('Error getting user karma: $e');
      // Return a default karma model
      return KarmaModel(
        userId: userId,
        totalPoints: 0,
        badgeLevel: KarmaBadgeLevel.leastTrusted,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update user's karma when a debt is repaid
  Future<KarmaModel> updateKarmaForRepayment(
    String userId,
    String debtId,
    DateTime borrowTimestamp,
    DateTime repaymentTimestamp
  ) async {
    try {
      // Calculate karma points for this repayment
      final int karmaPoints = calculateKarmaPoints(borrowTimestamp, repaymentTimestamp);

      // Get current karma
      final karmaDoc = await _firestore.collection('karma').doc(userId).get();

      if (karmaDoc.exists) {
        final currentKarma = KarmaModel.fromDocument(karmaDoc);

        // Update points history
        final updatedPointsHistory = Map<String, int>.from(currentKarma.pointsHistory);
        updatedPointsHistory[debtId] = karmaPoints;

        // Calculate new total points
        final newTotalPoints = updatedPointsHistory.values.fold<int>(0, (sum, points) => sum + points);

        // Determine new badge level
        final newBadgeLevel = determineBadgeLevel(newTotalPoints);

        // Create updated karma model
        final updatedKarma = currentKarma.copyWith(
          totalPoints: newTotalPoints,
          badgeLevel: newBadgeLevel,
          pointsHistory: updatedPointsHistory,
          lastUpdated: DateTime.now(),
        );

        // Update in Firestore
        await _firestore.collection('karma').doc(userId).update(updatedKarma.toMap());

        return updatedKarma;
      } else {
        // Create new karma model
        final pointsHistory = <String, int>{debtId: karmaPoints};
        final badgeLevel = determineBadgeLevel(karmaPoints);

        final newKarma = KarmaModel(
          userId: userId,
          totalPoints: karmaPoints,
          badgeLevel: badgeLevel,
          pointsHistory: pointsHistory,
          lastUpdated: DateTime.now(),
        );

        await _firestore.collection('karma').doc(userId).set(newKarma.toMap());

        return newKarma;
      }
    } catch (e) {
      debugPrint('Error updating karma for repayment: $e');
      rethrow;
    }
  }

  /// Get karma leaderboard for a user's friends
  Future<List<Map<String, dynamic>>> getKarmaLeaderboard(String userId, List<String> friendIds) async {
    try {
      debugPrint('Getting karma leaderboard for user: $userId');
      debugPrint('Friend IDs: $friendIds');

      final List<Map<String, dynamic>> leaderboard = [];

      // Add current user's karma
      debugPrint('Getting current user karma...');
      final userKarma = await getUserKarma(userId);
      debugPrint('User karma loaded: ${userKarma.totalPoints} points, badge: ${userKarma.badgeName}');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      debugPrint('User document exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        debugPrint('User name: ${userData['name']}');

        leaderboard.add({
          'userId': userId,
          'name': userData['name'] ?? 'Unknown',
          'photoUrl': userData['photoUrl'],
          'totalPoints': userKarma.totalPoints,
          'badgeLevel': userKarma.badgeLevel,
          'badgeEmoji': userKarma.badgeEmoji,
          'nickname': userKarma.nickname,
          'badgeName': userKarma.badgeName,
          'description': userKarma.description,
          'isCurrentUser': true,
        });

        debugPrint('Added current user to leaderboard');
      } else {
        debugPrint('User document does not exist!');
      }

      // Add friends' karma
      debugPrint('Adding friends to leaderboard...');
      int friendsAdded = 0;

      for (final friendId in friendIds) {
        debugPrint('Processing friend: $friendId');
        final friendKarma = await getUserKarma(friendId);
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        debugPrint('Friend document exists: ${friendDoc.exists}');

        if (friendDoc.exists) {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          debugPrint('Friend name: ${friendData['name']}');

          leaderboard.add({
            'userId': friendId,
            'name': friendData['name'] ?? 'Unknown',
            'photoUrl': friendData['photoUrl'],
            'totalPoints': friendKarma.totalPoints,
            'badgeLevel': friendKarma.badgeLevel,
            'badgeEmoji': friendKarma.badgeEmoji,
            'nickname': friendKarma.nickname,
            'badgeName': friendKarma.badgeName,
            'description': friendKarma.description,
            'isCurrentUser': false,
          });

          friendsAdded++;
          debugPrint('Added friend to leaderboard');
        } else {
          debugPrint('Friend document does not exist!');
        }
      }

      debugPrint('Added $friendsAdded friends to leaderboard');

      // Sort by total points (descending)
      leaderboard.sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));
      debugPrint('Leaderboard sorted, total entries: ${leaderboard.length}');

      // Add a dummy entry if leaderboard is empty
      if (leaderboard.isEmpty) {
        debugPrint('Leaderboard is empty, adding dummy entry');
        leaderboard.add({
          'userId': 'dummy',
          'name': 'Example User',
          'photoUrl': null,
          'totalPoints': 100,
          'badgeLevel': KarmaBadgeLevel.topRepayer,
          'badgeEmoji': '🤑',
          'nickname': 'The Payback Pro',
          'badgeName': 'Top Repayer',
          'description': 'Lightning-fast repayments, everyone loves lending to this legend',
          'isCurrentUser': false,
        });
      }

      return leaderboard;
    } catch (e, stackTrace) {
      debugPrint('Error getting karma leaderboard: $e');
      debugPrint('Stack trace: $stackTrace');

      // Return a dummy leaderboard in case of error
      return [
        {
          'userId': 'error',
          'name': 'Error Loading Data',
          'photoUrl': null,
          'totalPoints': 0,
          'badgeLevel': KarmaBadgeLevel.leastTrusted,
          'badgeEmoji': '🤡',
          'nickname': 'The Clown Collector',
          'badgeName': 'Least Trusted',
          'description': 'Danger zone — promises a lot, repays rarely. Handle with caution!',
          'isCurrentUser': false,
        }
      ];
    }
  }
}
