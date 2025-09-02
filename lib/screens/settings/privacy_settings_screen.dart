import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/privacy_provider.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacyProvider = Provider.of<PrivacyProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: () {
              _showResetConfirmation(context, privacyProvider);
            },
          ),
        ],
      ),
      body: privacyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Privacy Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  const Text(
                    'Control what information is shared with others',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Friend Search
                  _buildPrivacySetting(
                    context,
                    title: 'Allow Friend Search',
                    subtitle: 'Let others find you by email or username',
                    icon: Icons.search,
                    value: privacyProvider.allowFriendSearch,
                    onChanged: (value) {
                      privacyProvider.toggleAllowFriendSearch(value);
                    },
                  ),
                  
                  // Profile Details
                  _buildPrivacySetting(
                    context,
                    title: 'Show Profile Details',
                    subtitle: 'Show your profile details to friends',
                    icon: Icons.person,
                    value: privacyProvider.showProfileDetails,
                    onChanged: (value) {
                      privacyProvider.toggleShowProfileDetails(value);
                    },
                  ),
                  
                  // Expenses Visibility
                  _buildPrivacySetting(
                    context,
                    title: 'Show Expenses to Friends',
                    subtitle: 'Allow friends to see your personal expenses',
                    icon: Icons.receipt,
                    value: privacyProvider.showExpensesToFriends,
                    onChanged: (value) {
                      privacyProvider.toggleShowExpensesToFriends(value);
                    },
                  ),
                  
                  // Budget Visibility
                  _buildPrivacySetting(
                    context,
                    title: 'Show Budgets to Friends',
                    subtitle: 'Allow friends to see your budget information',
                    icon: Icons.account_balance_wallet,
                    value: privacyProvider.showBudgetsToFriends,
                    onChanged: (value) {
                      privacyProvider.toggleShowBudgetsToFriends(value);
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.mediumSpacing),
                  const Divider(),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Privacy Info Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'About Privacy',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          const Text(
                            'Your privacy is important to us. These settings control what '
                            'information is shared with your friends and other users. '
                            'By default, we keep your financial information private.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          const Text(
                            'Note: Shared expenses and debts are always visible to the '
                            'friends involved in those transactions.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Data Protection Card
                  Card(
                    margin: const EdgeInsets.only(top: AppTheme.mediumSpacing),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Data Protection',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          const Text(
                            'Your data is encrypted and stored securely. We never share '
                            'your personal information with third parties without your consent.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: AppTheme.mediumSpacing),
                          OutlinedButton(
                            onPressed: () {
                              // Show privacy policy
                              _showPrivacyPolicy(context);
                            },
                            child: const Text('View Privacy Policy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrivacySetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        side: BorderSide(color: Colors.grey.withAlpha(50), width: 0.5),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? Theme.of(context).primaryColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
                color: value ? Theme.of(context).primaryColor : null,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future<void> _showResetConfirmation(
      BuildContext context, PrivacyProvider privacyProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Privacy Settings'),
          content: const Text(
              'Are you sure you want to reset all privacy settings to default?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () {
                privacyProvider.resetToDefault();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy settings reset to default'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the privacy policy. In a real app, '
            'this would contain the full privacy policy text explaining how '
            'user data is collected, stored, and used.\n\n'
            'The privacy policy would also detail user rights regarding their '
            'data and how they can request data deletion or export.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
