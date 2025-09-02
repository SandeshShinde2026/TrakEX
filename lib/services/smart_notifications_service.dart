import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';

class SmartNotificationsService {
  static final SmartNotificationsService _instance = SmartNotificationsService._internal();
  factory SmartNotificationsService() => _instance;
  SmartNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification channels
  static const String _spendingChannelId = 'spending_alerts';
  static const String _budgetChannelId = 'budget_warnings';
  static const String _debtChannelId = 'debt_reminders';
  static const String _insightsChannelId = 'smart_insights';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        _spendingChannelId,
        'Spending Alerts',
        description: 'Notifications about your spending patterns',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _budgetChannelId,
        'Budget Warnings',
        description: 'Notifications when you exceed budget limits',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _debtChannelId,
        'Debt Reminders',
        description: 'Reminders about pending debts and payments',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        _insightsChannelId,
        'Smart Insights',
        description: 'AI-powered spending insights and tips',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Spending alert notifications
  Future<void> showSpendingAlert({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!await _shouldShowNotification('spending_alerts')) return;

    const androidDetails = AndroidNotificationDetails(
      _spendingChannelId,
      'Spending Alerts',
      channelDescription: 'Notifications about your spending patterns',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: payload,
    );
  }

  // Budget warning notifications
  Future<void> showBudgetWarning({
    required String category,
    required double spentAmount,
    required double budgetAmount,
    required double percentage,
  }) async {
    if (!await _shouldShowNotification('budget_warnings')) return;

    final title = 'Budget Alert: $category';
    final message = 'You\'ve spent ${AppConstants.currencySymbol}${spentAmount.toStringAsFixed(0)} '
        '(${percentage.toInt()}%) of your ${AppConstants.currencySymbol}${budgetAmount.toStringAsFixed(0)} budget';

    const androidDetails = AndroidNotificationDetails(
      _budgetChannelId,
      'Budget Warnings',
      channelDescription: 'Notifications when you exceed budget limits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.orange,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: 'budget_warning:$category',
    );
  }

  // Debt reminder notifications
  Future<void> showDebtReminder({
    required String friendName,
    required double amount,
    required int daysPending,
  }) async {
    if (!await _shouldShowNotification('debt_reminders')) return;

    final title = 'Payment Reminder';
    final message = '$friendName owes you ${AppConstants.currencySymbol}${amount.toStringAsFixed(0)} '
        'for $daysPending days';

    const androidDetails = AndroidNotificationDetails(
      _debtChannelId,
      'Debt Reminders',
      channelDescription: 'Reminders about pending debts and payments',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: 'debt_reminder:$friendName',
    );
  }

  // Smart insights notifications
  Future<void> showSmartInsight({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!await _shouldShowNotification('smart_insights')) return;

    const androidDetails = AndroidNotificationDetails(
      _insightsChannelId,
      'Smart Insights',
      channelDescription: 'AI-powered spending insights and tips',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: Colors.blue,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: payload,
    );
  }

  // Weekly summary notification
  Future<void> showWeeklySummary({
    required double totalSpent,
    required double budgetUsed,
    required String topCategory,
    required int transactionCount,
  }) async {
    if (!await _shouldShowNotification('weekly_summary')) return;

    final title = 'Weekly Summary';
    final message = 'You spent ${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(0)} '
        'in $transactionCount transactions. Top category: $topCategory';

    const androidDetails = AndroidNotificationDetails(
      _insightsChannelId,
      'Smart Insights',
      channelDescription: 'Weekly spending summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: 'weekly_summary',
    );
  }

  // Check if user wants to receive specific notification types
  Future<bool> _shouldShowNotification(String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_$type') ?? true;
  }

  // Update notification preferences
  Future<void> updateNotificationPreference(String type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_$type', enabled);
  }

  // Analyze expenses and trigger smart notifications
  Future<void> analyzeAndNotify({
    required List<ExpenseModel> expenses,
    required List<BudgetModel> budgets,
  }) async {
    await _checkSpendingPatterns(expenses);
    await _checkBudgetAlerts(expenses, budgets);
    await _checkWeekendSpending(expenses);
  }

  Future<void> _checkSpendingPatterns(List<ExpenseModel> expenses) async {
    final today = DateTime.now();
    final todayExpenses = expenses.where((e) => 
      e.date.year == today.year &&
      e.date.month == today.month &&
      e.date.day == today.day
    ).toList();

    if (todayExpenses.length >= 5) {
      await showSpendingAlert(
        title: 'High Activity Day',
        message: 'You\'ve made ${todayExpenses.length} transactions today. Consider reviewing your spending.',
        payload: 'high_activity',
      );
    }

    // Check for consecutive spending days
    final consecutiveDays = _getConsecutiveSpendingDays(expenses);
    if (consecutiveDays >= 7) {
      await showSpendingAlert(
        title: 'Spending Streak',
        message: 'You\'ve spent money for $consecutiveDays consecutive days. Consider taking a spending break.',
        payload: 'spending_streak',
      );
    }
  }

  Future<void> _checkBudgetAlerts(List<ExpenseModel> expenses, List<BudgetModel> budgets) async {
    for (final budget in budgets) {
      final categoryExpenses = expenses.where((e) => e.category == budget.category).toList();
      final totalSpent = categoryExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final percentage = (totalSpent / budget.amount) * 100;

      if (percentage >= 80 && percentage < 100) {
        await showBudgetWarning(
          category: budget.category,
          spentAmount: totalSpent,
          budgetAmount: budget.amount,
          percentage: percentage,
        );
      } else if (percentage >= 100) {
        await showSpendingAlert(
          title: 'Budget Exceeded',
          message: 'You\'ve exceeded your ${budget.category} budget by ${AppConstants.currencySymbol}${(totalSpent - budget.amount).toStringAsFixed(0)}',
          payload: 'budget_exceeded:${budget.category}',
        );
      }
    }
  }

  Future<void> _checkWeekendSpending(List<ExpenseModel> expenses) async {
    final now = DateTime.now();
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      final weekendExpenses = expenses.where((e) => 
        e.date.weekday >= DateTime.saturday &&
        e.date.isAfter(now.subtract(const Duration(days: 2)))
      ).toList();

      final weekendTotal = weekendExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      
      if (weekendTotal > 0) {
        await showSmartInsight(
          title: 'Weekend Spending',
          message: 'You\'ve spent ${AppConstants.currencySymbol}${weekendTotal.toStringAsFixed(0)} this weekend',
          payload: 'weekend_spending',
        );
      }
    }
  }

  int _getConsecutiveSpendingDays(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return 0;
    
    final sortedExpenses = expenses.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int consecutiveDays = 0;
    DateTime? lastDate;
    
    for (final expense in sortedExpenses) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (lastDate == null) {
        lastDate = expenseDate;
        consecutiveDays = 1;
      } else {
        final difference = lastDate.difference(expenseDate).inDays;
        if (difference == 1) {
          consecutiveDays++;
          lastDate = expenseDate;
        } else {
          break;
        }
      }
    }
    
    return consecutiveDays;
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
