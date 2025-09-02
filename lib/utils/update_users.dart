import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility class to update existing users with missing fields
class UpdateUsersUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates all users in the database to add missing fields
  static Future<String> updateAllUsers() async {
    try {
      // Get all users
      final QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      int updatedCount = 0;
      int errorCount = 0;
      
      // Process each user
      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final String name = data['name']?.toString() ?? '';
          final String email = data['email']?.toString() ?? '';
          
          // Check if nameLower or emailLower is missing
          if (data['nameLower'] == null || data['emailLower'] == null) {
            // Update the user document with the missing fields
            await _firestore.collection('users').doc(doc.id).update({
              'nameLower': name.toLowerCase(),
              'emailLower': email.toLowerCase(),
            });
            
            debugPrint('Updated user: ${doc.id} (${name})');
            updatedCount++;
          }
        } catch (e) {
          debugPrint('Error updating user ${doc.id}: $e');
          errorCount++;
        }
      }
      
      return 'Updated $updatedCount users. Errors: $errorCount';
    } catch (e) {
      debugPrint('Error updating users: $e');
      return 'Error: ${e.toString()}';
    }
  }
  
  /// Updates a specific user by ID
  static Future<String> updateUser(String userId) async {
    try {
      // Get the user document
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return 'User not found';
      }
      
      final data = userDoc.data() as Map<String, dynamic>;
      final String name = data['name']?.toString() ?? '';
      final String email = data['email']?.toString() ?? '';
      
      // Update the user document with the missing fields
      await _firestore.collection('users').doc(userId).update({
        'nameLower': name.toLowerCase(),
        'emailLower': email.toLowerCase(),
      });
      
      return 'User updated successfully';
    } catch (e) {
      debugPrint('Error updating user: $e');
      return 'Error: ${e.toString()}';
    }
  }
}
