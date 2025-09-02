import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';

class TestData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _uuid = const Uuid();

  // Create a test expense for the current user
  static Future<String> createTestExpense(String userId) async {
    try {
      debugPrint('TestData: Creating test expense for user $userId');
      final String id = _uuid.v4();
      final now = DateTime.now();

      final expense = ExpenseModel(
        id: id,
        userId: userId,
        category: 'Food & Dining',
        description: 'Test expense created at ${now.toString()}',
        amount: 25.50,
        date: now,
        mood: 'Happy',
        isGroupExpense: false,
        participants: [],
      );

      // Convert to map for debugging
      final Map<String, dynamic> expenseMap = expense.toMap();
      debugPrint('TestData: Expense data to be saved: $expenseMap');

      // Set with timeout
      await _firestore.collection('expenses').doc(id).set(expenseMap)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw 'Connection timeout while creating test expense. Please check your internet connection.';
      });

      debugPrint('TestData: Test expense created successfully with ID: $id');

      // Verify the expense was created
      final docSnapshot = await _firestore.collection('expenses').doc(id).get();
      if (docSnapshot.exists) {
        debugPrint('TestData: Verified expense document exists in Firestore');
      } else {
        debugPrint('TestData: WARNING - Expense document was not found after creation');
      }

      return id;
    } catch (e) {
      debugPrint('TestData: Error creating test expense: $e');
      rethrow;
    }
  }

  // Check if the expenses collection exists and is accessible
  static Future<bool> checkExpensesCollection() async {
    try {
      debugPrint('TestData: Checking if expenses collection is accessible');
      final snapshot = await _firestore.collection('expenses').limit(1).get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw 'Connection timeout while checking expenses collection. Please check your internet connection.';
      });

      debugPrint('TestData: Expenses collection exists and is accessible. Documents: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first;
        debugPrint('TestData: Sample expense document ID: ${firstDoc.id}');
      }

      return true;
    } catch (e) {
      debugPrint('TestData: Error accessing expenses collection: $e');
      rethrow;
    }
  }

  // Check if the user document exists
  static Future<bool> checkUserDocument(String userId) async {
    try {
      debugPrint('TestData: Checking if user document exists for user $userId');
      final doc = await _firestore.collection('users').doc(userId).get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw 'Connection timeout while checking user document. Please check your internet connection.';
      });

      final exists = doc.exists;
      debugPrint('TestData: User document exists: $exists');

      if (exists) {
        final userData = doc.data();
        debugPrint('TestData: User data: $userData');
      }

      return exists;
    } catch (e) {
      debugPrint('TestData: Error checking user document: $e');
      rethrow;
    }
  }

  // Get all expenses for a user - direct method for debugging
  static Future<List<Map<String, dynamic>>> getExpensesForUser(String userId) async {
    try {
      debugPrint('TestData: Getting all expenses for user $userId');
      final snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw 'Connection timeout while fetching expenses. Please check your internet connection.';
      });

      final expenses = snapshot.docs.map((doc) => doc.data()).toList();
      debugPrint('TestData: Found ${expenses.length} expenses for user $userId');

      return expenses;
    } catch (e) {
      debugPrint('TestData: Error getting expenses for user: $e');
      rethrow;
    }
  }
}
