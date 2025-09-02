import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String name, String email, String password) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!.uid, name, email);

      return userCredential;
    } catch (e) {
      debugPrint('Error during registration: $e');
      // Convert Firebase errors to more user-friendly messages
      if (e.toString().contains('email-already-in-use')) {
        throw 'This email is already registered. Please use a different email or try logging in.';
      } else if (e.toString().contains('weak-password')) {
        throw 'The password is too weak. Please use a stronger password.';
      } else if (e.toString().contains('invalid-email')) {
        throw 'The email address is not valid. Please check and try again.';
      } else {
        throw 'Registration failed: ${e.toString()}';
      }
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(String uid, String name, String email) async {
    try {
      // Create user model with lowercase fields for search
      final userModel = UserModel(
        id: uid,
        name: name,
        email: email,
        nameLower: name.toLowerCase(),
        emailLower: email.toLowerCase(),
      );

      // Convert to map with proper type checking
      final userData = userModel.toMap();

      // Ensure the data is valid for Firestore
      await _firestore.collection('users').doc(uid).set(userData);

      debugPrint('User document created successfully for uid: $uid');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      throw 'Failed to create user profile. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      // First check if the document exists
      final docSnapshot = await _firestore.collection('users').doc(user.id).get();

      if (docSnapshot.exists) {
        // Update existing document
        debugPrint('AuthService: Updating existing user document');
        await _firestore.collection('users').doc(user.id).update(user.toMap());
      } else {
        // Create new document if it doesn't exist
        debugPrint('AuthService: Creating new user document');
        await _firestore.collection('users').doc(user.id).set(user.toMap());
      }
    } catch (e) {
      debugPrint('AuthService: Error updating user profile: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username, {String? currentUserId}) async {
    try {
      debugPrint('AuthService: Checking username availability for: $username');

      // Query for users with this username in their additionalData
      final querySnapshot = await _firestore
          .collection('users')
          .where('additionalData.username', isEqualTo: username)
          .get();

      // If no documents found, username is available
      if (querySnapshot.docs.isEmpty) {
        debugPrint('AuthService: Username is available');
        return true;
      }

      // If current user is updating their own username, allow it
      if (currentUserId != null) {
        final isCurrentUser = querySnapshot.docs.any((doc) => doc.id == currentUserId);
        if (isCurrentUser && querySnapshot.docs.length == 1) {
          debugPrint('AuthService: Username belongs to current user');
          return true;
        }
      }

      debugPrint('AuthService: Username is already taken');
      return false;
    } catch (e) {
      debugPrint('AuthService: Error checking username availability: $e');
      // In case of error, assume username is not available for safety
      return false;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      debugPrint('AuthService: Getting user by username: $username');

      final querySnapshot = await _firestore
          .collection('users')
          .where('additionalData.username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromDocument(querySnapshot.docs.first);
      }

      return null;
    } catch (e) {
      debugPrint('AuthService: Error getting user by username: $e');
      return null;
    }
  }
}
