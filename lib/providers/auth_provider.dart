import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null || _userModel != null;

  AuthProvider() {
    _init();

    // Fallback timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (_isLoading) {
        debugPrint('AuthProvider: Timeout reached, forcing loading to false');
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('AuthProvider: Initializing');

    try {
      // Check if we have a current user already
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        debugPrint('AuthProvider: Current user found on init: ${currentUser.uid}');
        try {
          // Force token refresh to ensure we have a valid token
          await currentUser.getIdToken(true);
          _user = currentUser;
          await _fetchUserData();
          debugPrint('AuthProvider: User data fetched successfully on init');
        } catch (e) {
          debugPrint('AuthProvider: Error refreshing token on init: $e');
          _error = 'Authentication error. Please log in again.';
          await _authService.signOut();
          _user = null;
          _userModel = null;
        }
      } else {
        debugPrint('AuthProvider: No current user found on init');
      }

      // Listen to auth state changes
      _authService.authStateChanges.listen((User? user) async {
        debugPrint('AuthProvider: Auth state changed, user: ${user?.uid ?? 'null'}');

        if (user != null) {
          // Check if token is valid and not expired
          try {
            // Force token refresh to ensure we have a valid token
            await user.getIdToken(true);
            _user = user;
            await _fetchUserData();
            _error = null;
            debugPrint('AuthProvider: User authenticated and data fetched');
          } catch (e) {
            debugPrint('AuthProvider: Error refreshing token in listener: $e');
            _error = 'Authentication error. Please log in again.';
            await _authService.signOut();
            _user = null;
            _userModel = null;
          }
        } else {
          debugPrint('AuthProvider: User signed out');
          _user = null;
          _userModel = null;
        }

        _isLoading = false;
        notifyListeners();
      });

      // Set loading to false after initial setup
      _isLoading = false;
      notifyListeners();
      debugPrint('AuthProvider: Initialization complete');
    } catch (e) {
      debugPrint('AuthProvider: Error during initialization: $e');
      _isLoading = false;
      _error = 'Failed to initialize authentication: $e';
      notifyListeners();
    }
  }

  // Check if user is authenticated with a valid token
  Future<bool> checkAuthStatus() async {
    debugPrint('AuthProvider: Checking auth status');

    // First check if we have a current user from Firebase Auth
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      debugPrint('AuthProvider: No current user found');
      _user = null;
      _userModel = null;
      _error = 'User not authenticated. Please log in again.';
      notifyListeners();
      return false;
    }

    // Update our user reference
    _user = currentUser;

    try {
      debugPrint('AuthProvider: Refreshing token for user ${_user!.uid}');
      // Try to refresh the token
      await _user!.getIdToken(true);
      debugPrint('AuthProvider: Token refreshed successfully');

      // Refresh user data
      await _fetchUserData();

      // Clear any previous errors
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Auth token validation failed: $e');
      _error = 'Session expired. Please log in again.';

      // Force sign out on token validation failure
      try {
        await _authService.signOut();
      } catch (signOutError) {
        debugPrint('AuthProvider: Error during sign out: $signOutError');
      }

      _user = null;
      _userModel = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchUserData() async {
    try {
      if (_user != null) {
        debugPrint('AuthProvider: Fetching user data for ${_user!.uid}');
        final userData = await _authService.getUserData(_user!.uid);

        if (userData != null) {
          _userModel = userData;
          debugPrint('AuthProvider: User data fetched successfully');

          // Initialize FCM and update token
          await _initializeFCM();
        } else {
          debugPrint('AuthProvider: User data not found in Firestore');
          // If user exists in Auth but not in Firestore, create the user document
          try {
            debugPrint('AuthProvider: Creating user document in Firestore');
            final name = _user!.displayName ?? 'User';
            final email = _user!.email ?? '';
            final newUser = UserModel(
              id: _user!.uid,
              name: name,
              email: email,
              nameLower: name.toLowerCase(),
              emailLower: email.toLowerCase(),
            );

            // Use the AuthService to create the user document
            await _authService.updateUserProfile(newUser);

            _userModel = newUser;
            debugPrint('AuthProvider: User document created successfully');

            // Initialize FCM for new user
            await _initializeFCM();
          } catch (createError) {
            debugPrint('AuthProvider: Error creating user document: $createError');
            _error = 'Failed to create user profile. Please try again.';
          }
        }
      } else {
        debugPrint('AuthProvider: Cannot fetch user data, no authenticated user');
        _userModel = null;
      }
    } catch (e) {
      debugPrint('AuthProvider: Error fetching user data: $e');
      _error = 'Failed to load user data: ${e.toString()}';
    }
  }

  // Initialize FCM and update user's FCM token
  Future<void> _initializeFCM() async {
    try {
      if (_userModel == null) return;

      debugPrint('AuthProvider: Initializing FCM for user ${_userModel!.id}');

      // Initialize FCM service
      await FCMService.initialize();

      // Get FCM token
      final fcmToken = await FCMService.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('AuthProvider: FCM token obtained: ${fcmToken.substring(0, 20)}...');

        // Update user's FCM token in Firestore
        await FCMService.updateUserFCMToken(_userModel!.id, fcmToken);

        // Update local user model
        _userModel = _userModel!.copyWith(fcmToken: fcmToken);

        debugPrint('AuthProvider: FCM token updated successfully');
      } else {
        debugPrint('AuthProvider: Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error initializing FCM: $e');
    }
  }

  // Method to be called by other providers to load notifications
  Future<void> loadUserNotifications(Function(String) loadNotificationsCallback) async {
    if (_userModel != null) {
      await loadNotificationsCallback(_userModel!.id);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('AuthProvider: Attempting to sign in with email: $email');

      // Temporary bypass for network issues in emulator - REMOVE FOR PRODUCTION
      if (email == 'test@test.com' && password == 'test123') {
        debugPrint('AuthProvider: Using mock authentication for testing');
        _isLoading = false;
        _user = null; // Mock user - you can create a mock User object if needed
        _userModel = UserModel(
          id: 'mock_user_id',
          name: 'Test User',
          email: 'test@test.com',
          nameLower: 'test user',
          emailLower: 'test@test.com',
        );
        notifyListeners();
        return true;
      }

      final userCredential = await _authService.signInWithEmailAndPassword(email, password);

      // Ensure we have a valid user
      if (userCredential.user == null) {
        debugPrint('AuthProvider: Sign in failed - no user returned');
        _isLoading = false;
        _error = 'Login failed. Please try again.';
        notifyListeners();
        return false;
      }

      // Force token refresh
      debugPrint('AuthProvider: Sign in successful, refreshing token');
      await userCredential.user!.getIdToken(true);

      // Update user reference
      _user = userCredential.user;

      // Fetch user data
      await _fetchUserData();

      debugPrint('AuthProvider: Sign in and data fetch complete');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Sign in error: $e');
      _isLoading = false;

      // Convert Firebase errors to more specific user-friendly messages
      String errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('user-not-found')) {
        _error = 'USER_NOT_FOUND';
      } else if (errorMessage.contains('wrong-password') || errorMessage.contains('invalid-credential')) {
        _error = 'WRONG_PASSWORD';
      } else if (errorMessage.contains('invalid-email')) {
        _error = 'INVALID_EMAIL';
      } else if (errorMessage.contains('user-disabled')) {
        _error = 'USER_DISABLED';
      } else if (errorMessage.contains('too-many-requests')) {
        _error = 'TOO_MANY_REQUESTS';
      } else if (errorMessage.contains('network-request-failed') || errorMessage.contains('network error')) {
        _error = 'NETWORK_ERROR';
      } else if (errorMessage.contains('permission-denied') || errorMessage.contains('firestore')) {
        _error = 'DATABASE_ERROR';
      } else {
        _error = 'UNKNOWN_ERROR: ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerWithEmailAndPassword(name, email, password);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;

      // Convert Firebase registration errors to specific codes
      String errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('email-already-in-use')) {
        _error = 'EMAIL_ALREADY_EXISTS';
      } else if (errorMessage.contains('weak-password')) {
        _error = 'WEAK_PASSWORD';
      } else if (errorMessage.contains('invalid-email')) {
        _error = 'INVALID_EMAIL';
      } else if (errorMessage.contains('network-request-failed') || errorMessage.contains('network error')) {
        _error = 'NETWORK_ERROR';
      } else if (errorMessage.contains('permission-denied') || errorMessage.contains('firestore')) {
        _error = 'DATABASE_ERROR';
      } else {
        _error = 'REGISTRATION_ERROR: ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('AuthProvider: Starting sign out process');

      // Clear user state immediately for mock users
      if (_userModel?.id == 'mock_user_id') {
        debugPrint('AuthProvider: Clearing mock user state');
        _user = null;
        _userModel = null;
        _error = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // For real Firebase users, sign out from Firebase
      await _authService.signOut();

      // Clear all user state
      _user = null;
      _userModel = null;
      _error = null;
      _isLoading = false;

      debugPrint('AuthProvider: Sign out completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error during sign out: $e');

      // Even if there's an error, clear the user state
      _user = null;
      _userModel = null;
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updateUserProfile(updatedUser);
      _userModel = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
