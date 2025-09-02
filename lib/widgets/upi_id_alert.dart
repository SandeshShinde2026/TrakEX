import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/user_details_screen.dart';

class UpiIdAlert extends StatelessWidget {
  const UpiIdAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    // Only show if user is logged in and doesn't have a UPI ID
    if (user == null || (user.upiId != null && user.upiId!.isNotEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.mediumSpacing,
        vertical: AppTheme.smallSpacing,
      ),
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.smallSpacing),
                const Expanded(
                  child: Text(
                    'UPI ID Missing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    // This is just a visual dismissal
                    // The alert will reappear on next load
                    // For permanent dismissal, we would need to store a preference
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            const Text(
              'You haven\'t added your UPI ID yet. Adding a UPI ID allows your friends to pay you directly through the app.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserDetailsScreen(isNewUser: false),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add UPI ID'),
            ),
          ],
        ),
      ),
    );
  }
}
