import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../services/background_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final BackgroundNotificationService _backgroundService = BackgroundNotificationService();

  // Background notification settings
  bool _dailyDebtReminders = true;
  bool _weeklyDebtSummary = true;
  bool _monthlyFinancialSummary = true;
  bool _overduePaymentAlerts = true;
  bool _groupExpenseReminders = true;

  @override
  void initState() {
    super.initState();
    _loadBackgroundNotificationSettings();
  }

  Future<void> _loadBackgroundNotificationSettings() async {
    _dailyDebtReminders = await _backgroundService.isNotificationEnabled('daily_debt');
    _weeklyDebtSummary = await _backgroundService.isNotificationEnabled('weekly_summary');
    _monthlyFinancialSummary = await _backgroundService.isNotificationEnabled('monthly_summary');
    _overduePaymentAlerts = await _backgroundService.isNotificationEnabled('overdue_alerts');
    _groupExpenseReminders = await _backgroundService.isNotificationEnabled('group_expense');

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateBackgroundNotificationSetting(String type, bool value) async {
    await _backgroundService.updateNotificationPreference(type, value);

    // Re-initialize background service to apply changes
    if (value) {
      await _backgroundService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: () {
              _showResetConfirmation(context, notificationProvider);
            },
          ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Notification Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  Text(
                    'Choose which notifications you want to receive',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Expense Reminders
                  _buildNotificationSetting(
                    context,
                    title: 'Expense Reminders',
                    subtitle: 'Get reminders about recurring expenses',
                    icon: Icons.receipt_long,
                    value: notificationProvider.expenseReminders,
                    onChanged: (value) {
                      notificationProvider.toggleExpenseReminders(value);
                    },
                  ),
                  
                  // Budget Alerts
                  _buildNotificationSetting(
                    context,
                    title: 'Budget Alerts',
                    subtitle: 'Get alerts when you approach or exceed your budget',
                    icon: Icons.account_balance_wallet,
                    value: notificationProvider.budgetAlerts,
                    onChanged: (value) {
                      notificationProvider.toggleBudgetAlerts(value);
                    },
                  ),
                  
                  // Friend Requests
                  _buildNotificationSetting(
                    context,
                    title: 'Friend Requests',
                    subtitle: 'Get notified about new friend requests',
                    icon: Icons.person_add,
                    value: notificationProvider.friendRequests,
                    onChanged: (value) {
                      notificationProvider.toggleFriendRequests(value);
                    },
                  ),
                  
                  // Debt Reminders
                  _buildNotificationSetting(
                    context,
                    title: 'Debt Reminders',
                    subtitle: 'Get reminders about money you owe or are owed',
                    icon: Icons.money,
                    value: notificationProvider.debtReminders,
                    onChanged: (value) {
                      notificationProvider.toggleDebtReminders(value);
                    },
                  ),
                  
                  // Payment Confirmations
                  _buildNotificationSetting(
                    context,
                    title: 'Payment Confirmations',
                    subtitle: 'Get notified when payments are made or received',
                    icon: Icons.payment,
                    value: notificationProvider.paymentConfirmations,
                    onChanged: (value) {
                      notificationProvider.togglePaymentConfirmations(value);
                    },
                  ),

                  const SizedBox(height: AppTheme.mediumSpacing),
                  const Divider(),
                  const SizedBox(height: AppTheme.mediumSpacing),

                  // Background Notifications Section
                  Text(
                    'Background Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  Text(
                    'These notifications work even when the app is closed',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),

                  // Daily Debt Reminders
                  _buildNotificationSetting(
                    context,
                    title: 'Daily Debt Reminders',
                    subtitle: 'Daily reminders about pending payments (9:00 AM)',
                    icon: Icons.schedule,
                    value: _dailyDebtReminders,
                    onChanged: (value) async {
                      setState(() => _dailyDebtReminders = value);
                      await _updateBackgroundNotificationSetting('daily_debt', value);
                    },
                  ),

                  // Weekly Debt Summary
                  _buildNotificationSetting(
                    context,
                    title: 'Weekly Debt Summary',
                    subtitle: 'Weekly summary of all debts (Sundays, 7:00 PM)',
                    icon: Icons.calendar_view_week,
                    value: _weeklyDebtSummary,
                    onChanged: (value) async {
                      setState(() => _weeklyDebtSummary = value);
                      await _updateBackgroundNotificationSetting('weekly_summary', value);
                    },
                  ),

                  // Monthly Financial Report
                  _buildNotificationSetting(
                    context,
                    title: 'Monthly Financial Report',
                    subtitle: 'Monthly financial insights (1st of month, 10:00 AM)',
                    icon: Icons.assessment,
                    value: _monthlyFinancialSummary,
                    onChanged: (value) async {
                      setState(() => _monthlyFinancialSummary = value);
                      await _updateBackgroundNotificationSetting('monthly_summary', value);
                    },
                  ),

                  // Overdue Payment Alerts
                  _buildNotificationSetting(
                    context,
                    title: 'Overdue Payment Alerts',
                    subtitle: 'Urgent alerts for overdue payments (every 6 hours)',
                    icon: Icons.warning,
                    value: _overduePaymentAlerts,
                    onChanged: (value) async {
                      setState(() => _overduePaymentAlerts = value);
                      await _updateBackgroundNotificationSetting('overdue_alerts', value);
                    },
                  ),

                  // Group Expense Reminders
                  _buildNotificationSetting(
                    context,
                    title: 'Group Expense Reminders',
                    subtitle: 'Reminders about unsettled group expenses',
                    icon: Icons.group,
                    value: _groupExpenseReminders,
                    onChanged: (value) async {
                      setState(() => _groupExpenseReminders = value);
                      await _updateBackgroundNotificationSetting('group_expense', value);
                    },
                  ),

                  const SizedBox(height: AppTheme.mediumSpacing),

                  // Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        await _backgroundService.showDebtReminderNotification(
                          friendName: 'Test Friend',
                          amount: 500.0,
                          type: 'owe',
                          daysPending: 3,
                        );

                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Send Test Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.smallSpacing),
                  const Divider(),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Info Card
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
                                Icons.info,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About Notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          Text(
                            'Notifications help you stay on top of your finances. '
                            'You can customize which notifications you receive to '
                            'focus on what matters most to you.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          Text(
                            'Note: You may need to enable notifications in your '
                            'device settings for this app.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
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

  Widget _buildNotificationSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: value
                  ? AppTheme.primaryColor
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppTheme.primaryColor,
                inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation(
      BuildContext context, NotificationProvider notificationProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Notification Settings'),
          content: const Text(
              'Are you sure you want to reset all notification settings to default?'),
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
                notificationProvider.resetToDefault();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings reset to default'),
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
}
