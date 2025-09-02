import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/payment_transaction_model.dart';

class DatabaseSetup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates all users to add UPI fields if they don't exist
  Future<void> updateUserCollection() async {
    try {
      // Get all users
      final QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      
      int updatedCount = 0;
      
      // Update each user
      for (final doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        
        // Check if UPI fields already exist
        if (!userData.containsKey('upiId') || !userData.containsKey('upiVisible')) {
          // Update the user document
          await _firestore.collection('users').doc(doc.id).update({
            'upiId': userData['upiId'] ?? '',
            'upiVisible': userData['upiVisible'] ?? true,
          });
          
          updatedCount++;
        }
      }
      
      debugPrint('DatabaseSetup: Updated $updatedCount users with UPI fields');
    } catch (e) {
      debugPrint('DatabaseSetup: Error updating user collection: $e');
    }
  }

  /// Creates the payments collection if it doesn't exist
  Future<void> createPaymentsCollection() async {
    try {
      // Check if payments collection exists by trying to get a document
      final QuerySnapshot paymentsSnapshot = await _firestore.collection('payments').limit(1).get();
      
      // If collection doesn't exist or is empty, create a test document
      if (paymentsSnapshot.docs.isEmpty) {
        // Create a test payment document
        await _firestore.collection('payments').doc('test_payment').set({
          'id': 'test_payment',
          'fromUserId': 'system',
          'toUserId': 'system',
          'amount': 0.0,
          'description': 'Test payment - Please delete',
          'timestamp': Timestamp.now(),
          'status': 'pending',
          'method': 'upi',
          'additionalData': {
            'isTestDocument': true,
            'createdAt': DateTime.now().toIso8601String(),
          },
        });
        
        debugPrint('DatabaseSetup: Created payments collection with test document');
      } else {
        debugPrint('DatabaseSetup: Payments collection already exists');
      }
    } catch (e) {
      debugPrint('DatabaseSetup: Error creating payments collection: $e');
    }
  }

  /// Run all database setup tasks
  Future<void> setupDatabase() async {
    await updateUserCollection();
    await createPaymentsCollection();
    debugPrint('DatabaseSetup: Database setup completed');
  }
}
