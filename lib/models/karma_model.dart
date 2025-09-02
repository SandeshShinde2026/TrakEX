import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enum for karma badge levels
enum KarmaBadgeLevel {
  topRepayer,    // 900+ points
  reliableBuddy, // 700-899 points
  okayishRepayer, // 500-699 points
  slowPayer,     // 300-499 points
  leastTrusted,  // <300 points
}

/// Class to represent a user's karma information
class KarmaModel {
  final String userId;
  final int totalPoints;
  final KarmaBadgeLevel badgeLevel;
  final Map<String, int> pointsHistory; // Map of debt IDs to points earned
  final DateTime lastUpdated;

  KarmaModel({
    required this.userId,
    required this.totalPoints,
    required this.badgeLevel,
    this.pointsHistory = const {},
    required this.lastUpdated,
  });

  /// Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'badgeLevel': _badgeLevelToString(badgeLevel),
      'pointsHistory': pointsHistory,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create a copy with updated values
  KarmaModel copyWith({
    String? userId,
    int? totalPoints,
    KarmaBadgeLevel? badgeLevel,
    Map<String, int>? pointsHistory,
    DateTime? lastUpdated,
  }) {
    return KarmaModel(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      badgeLevel: badgeLevel ?? this.badgeLevel,
      pointsHistory: pointsHistory ?? this.pointsHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Create from Firestore document
  factory KarmaModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    try {
      return KarmaModel(
        userId: data['userId'] ?? '',
        totalPoints: data['totalPoints'] ?? 0,
        badgeLevel: _stringToBadgeLevel(data['badgeLevel']),
        pointsHistory: _parsePointsHistory(data['pointsHistory']),
        lastUpdated: _parseTimestamp(data['lastUpdated']),
      );
    } catch (e) {
      debugPrint('Error parsing KarmaModel: $e');
      return KarmaModel(
        userId: data['userId'] ?? '',
        totalPoints: data['totalPoints'] ?? 0,
        badgeLevel: KarmaBadgeLevel.leastTrusted,
        pointsHistory: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get badge emoji based on badge level
  String get badgeEmoji {
    switch (badgeLevel) {
      case KarmaBadgeLevel.topRepayer:
        return '🤑';
      case KarmaBadgeLevel.reliableBuddy:
        return '😎';
      case KarmaBadgeLevel.okayishRepayer:
        return '😬';
      case KarmaBadgeLevel.slowPayer:
        return '😵‍💫';
      case KarmaBadgeLevel.leastTrusted:
        return '🤡';
    }
  }

  /// Get nickname based on badge level
  String get nickname {
    switch (badgeLevel) {
      case KarmaBadgeLevel.topRepayer:
        return 'The Payback Pro';
      case KarmaBadgeLevel.reliableBuddy:
        return 'The Cool Creditor';
      case KarmaBadgeLevel.okayishRepayer:
        return 'The Borderline Biller';
      case KarmaBadgeLevel.slowPayer:
        return 'The Delayed Dealer';
      case KarmaBadgeLevel.leastTrusted:
        return 'The Clown Collector';
    }
  }

  /// Get badge name based on badge level
  String get badgeName {
    switch (badgeLevel) {
      case KarmaBadgeLevel.topRepayer:
        return 'Top Repayer';
      case KarmaBadgeLevel.reliableBuddy:
        return 'Reliable Buddy';
      case KarmaBadgeLevel.okayishRepayer:
        return 'Okayish Repayer';
      case KarmaBadgeLevel.slowPayer:
        return 'Slow Payer';
      case KarmaBadgeLevel.leastTrusted:
        return 'Least Trusted';
    }
  }

  /// Get description based on badge level
  String get description {
    switch (badgeLevel) {
      case KarmaBadgeLevel.topRepayer:
        return 'Lightning-fast repayments, everyone loves lending to this legend';
      case KarmaBadgeLevel.reliableBuddy:
        return 'Smooth and timely, no drama, always comes through';
      case KarmaBadgeLevel.okayishRepayer:
        return 'Means well, tries hard, but sometimes cuts it close';
      case KarmaBadgeLevel.slowPayer:
        return 'Frequently forgets or delays payments — needs reminders';
      case KarmaBadgeLevel.leastTrusted:
        return 'Danger zone — promises a lot, repays rarely. Handle with caution!';
    }
  }

  /// Helper method to convert badge level to string
  static String _badgeLevelToString(KarmaBadgeLevel level) {
    switch (level) {
      case KarmaBadgeLevel.topRepayer:
        return 'topRepayer';
      case KarmaBadgeLevel.reliableBuddy:
        return 'reliableBuddy';
      case KarmaBadgeLevel.okayishRepayer:
        return 'okayishRepayer';
      case KarmaBadgeLevel.slowPayer:
        return 'slowPayer';
      case KarmaBadgeLevel.leastTrusted:
        return 'leastTrusted';
    }
  }

  /// Helper method to convert string to badge level
  static KarmaBadgeLevel _stringToBadgeLevel(String? level) {
    switch (level) {
      case 'topRepayer':
        return KarmaBadgeLevel.topRepayer;
      case 'reliableBuddy':
        return KarmaBadgeLevel.reliableBuddy;
      case 'okayishRepayer':
        return KarmaBadgeLevel.okayishRepayer;
      case 'slowPayer':
        return KarmaBadgeLevel.slowPayer;
      case 'leastTrusted':
      default:
        return KarmaBadgeLevel.leastTrusted;
    }
  }

  /// Helper method to parse points history
  static Map<String, int> _parsePointsHistory(dynamic data) {
    if (data == null) return {};

    try {
      final Map<String, int> result = {};
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);

      map.forEach((key, value) {
        if (value is num) {
          result[key] = value.toInt();
        }
      });

      return result;
    } catch (e) {
      debugPrint('Error parsing points history: $e');
      return {};
    }
  }

  /// Helper method to parse timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now();
  }
}
