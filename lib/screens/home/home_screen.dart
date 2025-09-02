import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ad_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/in_app_notification_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_helper.dart';

import '../analytics/analytics_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/enhanced_expenses_screen.dart';
import 'dashboard_screen.dart';
import 'budget_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'in_app_notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // Static method to navigate to a specific tab
  static void navigateToTab(BuildContext context, int tabIndex) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState._navigateToTab(tabIndex);
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Method to navigate to a specific tab
  void _navigateToTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _screens.length) {
      setState(() {
        _currentIndex = tabIndex;
      });
    }
  }

  // Method to get the appropriate theme icon
  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.wb_sunny; // Sun icon for light mode
      case ThemeMode.dark:
        return Icons.nightlight_round; // Moon icon for dark mode
      case ThemeMode.system:
        return Icons.brightness_auto; // Auto icon for system mode
    }
  }

  // Method to toggle theme mode
  void _toggleTheme(ThemeProvider themeProvider) {
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        themeProvider.setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        themeProvider.setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        // If system mode, switch to light mode first
        themeProvider.setThemeMode(ThemeMode.light);
        break;
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    EnhancedExpensesScreen(), // Using the enhanced expenses screen with date grouping
    const BudgetScreen(),
    const AnalyticsScreen(), // Analytics screen
    const FriendsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    // Get responsive values
    final iconSize = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 18,
      tabletFactor: 1.2,
      desktopFactor: 1.4,
    );



    final fabSize = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 72.0,
    );

    return Scaffold(
      appBar: AppBar(
        // Theme toggle button on the left
        leading: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                _getThemeIcon(themeProvider.themeMode),
                size: iconSize,
              ),
              onPressed: () => _toggleTheme(themeProvider),
              tooltip: 'Toggle Theme',
            );
          },
        ),
        title: Text(
          AppConstants.appName,
          style: GoogleFonts.playfairDisplay(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w900, // Extra bold
            letterSpacing: 1.0, // Add letter spacing for elegance
          ),
        ),
        actions: [
          // Notifications icon with badge
          Consumer<InAppNotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, size: iconSize),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InAppNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 99
                              ? '99+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Profile icon
          IconButton(
            icon: Icon(Icons.person, size: iconSize),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
        ],
      ),
      // Show floating action button only on the expenses tab and when there are expenses
      floatingActionButton: _currentIndex == 1 ? SizedBox(
        width: fabSize,
        height: fabSize,
        child: FloatingActionButton(
          onPressed: () {
            final adProvider = Provider.of<AdProvider>(context, listen: false);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddExpenseScreen(),
              ),
            ).then((result) {
              // The expense provider should already have updated the expenses list
              // through the real-time Firestore listener and local list update

              if (result == true) {
                // Show interstitial ad after expense is added
                adProvider.onExpenseAdded();
              } else {
                // If we didn't get a success result, force a refresh of the expenses screen
                final expensesScreen = _screens[1] as EnhancedExpensesScreen;
                expensesScreen.refreshExpenses();
              }
            });
          },
          heroTag: 'add',
          child: Icon(
            Icons.add,
            size: fabSize * 0.5,
          ),
        ),
      ) : null,
    );
  }


}
