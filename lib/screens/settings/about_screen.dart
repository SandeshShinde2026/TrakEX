import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // App Name and Version
            Text(
              AppConstants.appName,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w900, // Extra bold
                letterSpacing: 1.5, // Add letter spacing for elegance
              ),
            ),
            const Text(
              'Version 1.0.0 (100)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // App Description
            const Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(AppTheme.mediumSpacing),
                child: Column(
                  children: [
                    Text(
                      'TrakEX is a smart expense tracker app designed to help you track expenses, '
                      'set budgets, and manage shared expenses with friends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'Our mission is to make financial management simple and accessible for everyone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Features
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            
            _buildFeatureItem(
              context,
              icon: Icons.receipt_long,
              title: 'Expense Tracking',
              description: 'Track your daily expenses across multiple categories',
            ),
            
            _buildFeatureItem(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Budget Management',
              description: 'Set and monitor budgets to control your spending',
            ),
            
            _buildFeatureItem(
              context,
              icon: Icons.people,
              title: 'Friend Connections',
              description: 'Connect with friends to split expenses and track debts',
            ),
            
            _buildFeatureItem(
              context,
              icon: Icons.analytics,
              title: 'Financial Analytics',
              description: 'Visualize your spending patterns with detailed charts',
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),
            const Divider(),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Developer Info
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Developer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    const Text(
                      'Sandesh Shinde',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'App Developer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.email),
                          onPressed: () => _launchEmail('sandeshshinde2026@gmail.com'),
                          tooltip: 'Email',
                        ),
                        IconButton(
                          icon: const Icon(Icons.link),
                          onPressed: () => _launchUrl('https://github.com/SandeshShinde2026'),
                          tooltip: 'GitHub',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Legal Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _showLegalInfo(context, 'Privacy Policy'),
                  child: const Text('Privacy Policy'),
                ),
                const Text('•', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () => _showLegalInfo(context, 'Terms of Service'),
                  child: const Text('Terms of Service'),
                ),
              ],
            ),
            
            // Copyright
            const Text(
              '© 2023 Mujjar Funds. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
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
          description,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=About Mujjar Funds App',
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }
  
  void _showLegalInfo(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            'This is a placeholder for the $title. In a real app, '
            'this would contain the full legal text explaining '
            'the rules and guidelines for using the app.\n\n'
            'The document would cover usage rights, data handling, '
            'account policies, and other legal information.',
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
