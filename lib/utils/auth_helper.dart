import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../constants/app_theme.dart';

class AuthHelper {
  /// Shows a dialog when authentication is required
  static void showAuthRequiredDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Text(message ?? 'You need to be logged in to perform this action.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to login screen
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  /// Shows a snackbar with authentication error
  static void showAuthErrorSnackbar(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Authentication error. Please log in again.'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  /// Checks if the user is authenticated and shows a dialog if not
  static Future<bool> checkAuthenticated(BuildContext context) async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    // Check authentication status
    final isAuthenticated = await authProvider.checkAuthStatus();

    // If not mounted, return false
    if (!context.mounted) return false;

    // If not authenticated, show dialog
    if (!isAuthenticated) {
      showAuthRequiredDialog(
        context,
        message: authProvider.error ?? 'User not authenticated. Please log in again.'
      );
      return false;
    }

    return true;
  }

  /// Force refresh the authentication token
  static Future<bool> refreshToken(BuildContext context) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;

      // If no user, return false
      if (currentUser == null) return false;

      // Force token refresh
      await currentUser.getIdToken(true);
      return true;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }
}
