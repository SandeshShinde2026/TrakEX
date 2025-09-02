import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> friendIds;
  final Map<String, double> trustScores; // Friend ID to trust score
  final Map<String, bool> friendPrivacySettings; // Friend ID to privacy setting
  final Map<String, Map<String, dynamic>> budgets; // Category to budget info
  final String? nameLower; // Lowercase version of name for case-insensitive search
  final String? emailLower; // Lowercase version of email for case-insensitive search
  final Map<String, dynamic>? additionalData; // Additional user details like age, gender, etc.
  final String? upiId; // UPI ID for payments
  final bool upiVisible; // Whether UPI ID is visible to friends
  final String? fcmToken; // Firebase Cloud Messaging token for push notifications

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.friendIds = const [],
    this.trustScores = const {},
    this.friendPrivacySettings = const {},
    this.budgets = const {},
    this.additionalData,
    this.upiId,
    this.upiVisible = true,
    this.fcmToken,
    String? nameLower,
    String? emailLower,
  }) :
    nameLower = nameLower ?? name.toLowerCase(),
    emailLower = emailLower ?? email.toLowerCase();

  Map<String, dynamic> toMap() {
    // Ensure all values are of the correct type for Firestore
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'nameLower': nameLower, // Add lowercase name for search
      'emailLower': emailLower, // Add lowercase email for search
      'friendIds': List<String>.from(friendIds), // Ensure it's a List<String>
      'trustScores': Map<String, dynamic>.from(trustScores.map(
        (key, value) => MapEntry(key, value.toDouble()))), // Convert to double
      'friendPrivacySettings': Map<String, dynamic>.from(friendPrivacySettings.map(
        (key, value) => MapEntry(key, value))), // Ensure it's a Map<String, dynamic>
      'budgets': Map<String, dynamic>.from(budgets), // Ensure it's a Map<String, dynamic>
      'additionalData': additionalData, // Additional user details
      'upiId': upiId,
      'upiVisible': upiVisible,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Safely convert each field with proper error handling
    try {
      debugPrint('Creating UserModel from map: $map');

      // Ensure ID is present
      final String id = map['id']?.toString() ?? '';
      if (id.isEmpty) {
        debugPrint('WARNING: User ID is empty in map: $map');
      }

      // Get name and email with defaults
      final String name = map['name']?.toString() ?? '';
      final String email = map['email']?.toString() ?? '';

      debugPrint('Processing user: ID=$id, Name=$name, Email=$email');

      // Handle friendIds
      List<String> friendIds = [];
      if (map['friendIds'] != null) {
        try {
          if (map['friendIds'] is List) {
            friendIds = List<String>.from(
              (map['friendIds'] as List).map((item) => item.toString())
            );
          } else {
            debugPrint('friendIds is not a List: ${map['friendIds']}');
          }
        } catch (e) {
          debugPrint('Error parsing friendIds: $e');
        }
      }
      debugPrint('Processed friendIds: $friendIds');

      // Handle trustScores
      Map<String, double> trustScores = {};
      if (map['trustScores'] != null) {
        try {
          if (map['trustScores'] is Map) {
            final scores = map['trustScores'] as Map;
            scores.forEach((key, value) {
              if (value is num) {
                trustScores[key.toString()] = value.toDouble();
              }
            });
          } else {
            debugPrint('trustScores is not a Map: ${map['trustScores']}');
          }
        } catch (e) {
          debugPrint('Error parsing trustScores: $e');
        }
      }
      debugPrint('Processed trustScores: $trustScores');

      // Handle friendPrivacySettings
      Map<String, bool> privacySettings = {};
      if (map['friendPrivacySettings'] != null) {
        try {
          if (map['friendPrivacySettings'] is Map) {
            final settings = map['friendPrivacySettings'] as Map;
            settings.forEach((key, value) {
              if (value is bool) {
                privacySettings[key.toString()] = value;
              }
            });
          } else {
            debugPrint('friendPrivacySettings is not a Map: ${map['friendPrivacySettings']}');
          }
        } catch (e) {
          debugPrint('Error parsing friendPrivacySettings: $e');
        }
      }
      debugPrint('Processed privacySettings: $privacySettings');

      // Handle budgets
      Map<String, Map<String, dynamic>> budgets = {};
      if (map['budgets'] != null) {
        try {
          if (map['budgets'] is Map) {
            final budgetMap = map['budgets'] as Map;
            budgetMap.forEach((key, value) {
              if (value is Map) {
                budgets[key.toString()] = Map<String, dynamic>.from(value);
              }
            });
          } else {
            debugPrint('budgets is not a Map: ${map['budgets']}');
          }
        } catch (e) {
          debugPrint('Error parsing budgets: $e');
        }
      }
      debugPrint('Processed budgets: $budgets');

      // Process additionalData
      Map<String, dynamic>? additionalData;
      if (map['additionalData'] != null && map['additionalData'] is Map) {
        additionalData = Map<String, dynamic>.from(map['additionalData'] as Map);
        debugPrint('Processed additionalData: $additionalData');
      }

      // Process UPI fields
      final String? upiId = map['upiId']?.toString();
      final bool upiVisible = map['upiVisible'] ?? true;
      final String? fcmToken = map['fcmToken']?.toString();
      debugPrint('Processed UPI fields: upiId=$upiId, upiVisible=$upiVisible, fcmToken=$fcmToken');

      debugPrint('Successfully created UserModel from map');
      return UserModel(
        id: id,
        name: name,
        email: email,
        photoUrl: map['photoUrl']?.toString(),
        friendIds: friendIds,
        trustScores: trustScores,
        friendPrivacySettings: privacySettings,
        budgets: budgets,
        additionalData: additionalData,
        upiId: upiId,
        upiVisible: upiVisible,
        fcmToken: fcmToken,
        nameLower: map['nameLower']?.toString() ?? name.toLowerCase(),
        emailLower: map['emailLower']?.toString() ?? email.toLowerCase(),
      );
    } catch (e) {
      debugPrint('Error parsing UserModel: $e');
      // Return a default user model if parsing fails
      final name = map['name']?.toString() ?? '';
      final email = map['email']?.toString() ?? '';

      // Try to extract additionalData if available
      Map<String, dynamic>? additionalData;
      if (map['additionalData'] != null && map['additionalData'] is Map) {
        try {
          additionalData = Map<String, dynamic>.from(map['additionalData'] as Map);
        } catch (additionalDataError) {
          debugPrint('Error parsing additionalData in fallback: $additionalDataError');
        }
      }

      // Extract UPI fields if available
      final String? upiId = map['upiId']?.toString();
      final bool upiVisible = map['upiVisible'] ?? true;
      final String? fcmToken = map['fcmToken']?.toString();

      return UserModel(
        id: map['id']?.toString() ?? '',
        name: name,
        email: email,
        additionalData: additionalData,
        upiId: upiId,
        upiVisible: upiVisible,
        fcmToken: fcmToken,
        nameLower: map['nameLower']?.toString() ?? name.toLowerCase(),
        emailLower: map['emailLower']?.toString() ?? email.toLowerCase(),
      );
    }
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Ensure the document ID is included in the data
    final Map<String, dynamic> dataWithId = {
      ...data,
      'id': doc.id, // Use the document ID from Firestore
    };
    return UserModel.fromMap(dataWithId);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? friendIds,
    Map<String, double>? trustScores,
    Map<String, bool>? friendPrivacySettings,
    Map<String, Map<String, dynamic>>? budgets,
    Map<String, dynamic>? additionalData,
    String? upiId,
    bool? upiVisible,
    String? fcmToken,
    String? nameLower,
    String? emailLower,
  }) {
    final newName = name ?? this.name;
    final newEmail = email ?? this.email;

    return UserModel(
      id: id ?? this.id,
      name: newName,
      email: newEmail,
      photoUrl: photoUrl ?? this.photoUrl,
      friendIds: friendIds ?? this.friendIds,
      trustScores: trustScores ?? this.trustScores,
      friendPrivacySettings: friendPrivacySettings ?? this.friendPrivacySettings,
      budgets: budgets ?? this.budgets,
      additionalData: additionalData ?? this.additionalData,
      upiId: upiId ?? this.upiId,
      upiVisible: upiVisible ?? this.upiVisible,
      fcmToken: fcmToken ?? this.fcmToken,
      nameLower: nameLower ?? (name != null ? newName.toLowerCase() : this.nameLower),
      emailLower: emailLower ?? (email != null ? newEmail.toLowerCase() : this.emailLower),
    );
  }
}
