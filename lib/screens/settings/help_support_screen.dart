import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            const Text(
              'Find answers to common questions or contact our support team',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            
            _buildFaqItem(
              context,
              question: 'How do I add a new expense?',
              answer: 'To add a new expense, go to the Expenses tab and tap the "+" button at the bottom. Fill in the expense details and tap "Save".',
            ),
            
            _buildFaqItem(
              context,
              question: 'How do I set a budget?',
              answer: 'To set a budget, go to the Budget tab and tap "Set Budget". Choose a category, enter the amount, and set the time period.',
            ),
            
            _buildFaqItem(
              context,
              question: 'How do I add friends?',
              answer: 'To add friends, go to the Friends tab and tap the "+" button. You can search for friends by email or username.',
            ),
            
            _buildFaqItem(
              context,
              question: 'How do I split expenses with friends?',
              answer: 'When adding a new expense, select the "Split with Friends" option. Choose the friends to split with and how to divide the amount.',
            ),
            
            _buildFaqItem(
              context,
              question: 'How do I track debts?',
              answer: 'Debts are automatically tracked when you split expenses with friends. You can view and manage them in the Friends tab.',
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),
            const Divider(),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Contact Support Section
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            const Text(
              'Need more help? Contact our support team',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            _buildContactOption(
              context,
              title: 'Email Support',
              subtitle: 'support@trakex.com',
              icon: Icons.email,
              onTap: () => _launchEmail('support@trakex.com'),
            ),
            
            _buildContactOption(
              context,
              title: 'Live Chat',
              subtitle: 'Chat with our support team',
              icon: Icons.chat,
              onTap: () => _showComingSoonDialog(context, 'Live Chat'),
            ),
            
            _buildContactOption(
              context,
              title: 'Help Center',
              subtitle: 'Browse our knowledge base',
              icon: Icons.help_center,
              onTap: () => _showComingSoonDialog(context, 'Help Center'),
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),
            const Divider(),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // App Info Section
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
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    _buildInfoRow('App Name', AppConstants.appName),
                    _buildInfoRow('Version', '1.0.0'),
                    _buildInfoRow('Build', '100'),
                    const SizedBox(height: AppTheme.smallSpacing),
                    OutlinedButton(
                      onPressed: () {
                        _showTermsAndConditions(context);
                      },
                      child: const Text('Terms & Conditions'),
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

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        side: BorderSide(color: Colors.grey.withAlpha(50), width: 0.5),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        side: BorderSide(color: Colors.grey.withAlpha(50), width: 0.5),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request&body=Hello, I need help with...',
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text(
          'The $feature feature is coming soon! We\'re working hard to bring you this functionality in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the Terms & Conditions. In a real app, '
            'this would contain the full terms and conditions text explaining '
            'the rules and guidelines for using the app.\n\n'
            'The terms would cover usage rights, prohibited activities, '
            'account termination policies, and other legal information.',
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
