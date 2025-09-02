import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../constants/app_constants.dart';
import '../services/debt_service.dart';

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int _dailyDebtReminderId = 1001;
  static const int _weeklyDebtSummaryId = 2001;
  static const int _monthlyFinancialSummaryId = 3001;
  static const int _overduePaymentReminderId = 4001;

  // Initialize the background notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Schedule recurring notifications
      await _scheduleRecurringNotifications();

      _isInitialized = true;
      debugPrint('BackgroundNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BackgroundNotificationService: $e');
    }
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();
    
    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
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
  }

  // Create notification channels for different types
  Future<void> _createNotificationChannels() async {
    const debtChannel = AndroidNotificationChannel(
      'debt_reminders',
      'Debt Reminders',
      description: 'Daily reminders about pending debts and payments',
      importance: Importance.high,
      playSound: true,
    );

    const summaryChannel = AndroidNotificationChannel(
      'financial_summary',
      'Financial Summary',
      description: 'Weekly and monthly financial summaries',
      importance: Importance.defaultImportance,
    );

    const urgentChannel = AndroidNotificationChannel(
      'urgent_payments',
      'Urgent Payments',
      description: 'Overdue payment reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(debtChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(summaryChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(urgentChannel);
  }

  // Schedule recurring notifications using flutter_local_notifications
  Future<void> _scheduleRecurringNotifications() async {
    // Cancel existing scheduled notifications
    await _notifications.cancelAll();

    // Schedule daily debt reminder at 9 AM
    await _scheduleDailyNotification(
      id: _dailyDebtReminderId,
      title: '💰 Daily Debt Check',
      body: 'Don\'t forget to check your pending payments and settlements!',
      hour: 9,
      minute: 0,
    );

    // Schedule weekly debt summary on Sundays at 7 PM
    await _scheduleWeeklyNotification(
      id: _weeklyDebtSummaryId,
      title: '📊 Weekly Financial Summary',
      body: 'Your weekly debt and expense summary is ready. Tap to view details.',
      weekday: DateTime.sunday,
      hour: 19,
      minute: 0,
    );

    // Schedule monthly financial summary on 1st of each month at 10 AM
    await _scheduleMonthlyNotification(
      id: _monthlyFinancialSummaryId,
      title: '📈 Monthly Financial Report',
      body: 'Your monthly financial report is ready with insights and recommendations.',
      day: 1,
      hour: 10,
      minute: 0,
    );

    debugPrint('Recurring notifications scheduled successfully');
  }

  // Schedule daily notification
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_reminders',
          'Debt Reminders',
          channelDescription: 'Daily reminders about pending debts and payments',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  // Schedule weekly notification
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    // Find next occurrence of the specified weekday
    final daysUntilWeekday = (weekday - now.weekday) % 7;
    if (daysUntilWeekday == 0 && scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    } else {
      scheduledTime = scheduledTime.add(Duration(days: daysUntilWeekday));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'financial_summary',
          'Financial Summary',
          channelDescription: 'Weekly and monthly financial summaries',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeat weekly
    );
  }

  // Schedule monthly notification
  Future<void> _scheduleMonthlyNotification({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      // Move to next month
      if (now.month == 12) {
        scheduledTime = DateTime(now.year + 1, 1, day, hour, minute);
      } else {
        scheduledTime = DateTime(now.year, now.month + 1, day, hour, minute);
      }
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'financial_summary',
          'Financial Summary',
          channelDescription: 'Weekly and monthly financial summaries',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // Note: Monthly repetition is not directly supported, so we schedule for next month
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
    // This can be expanded to navigate to specific screens
  }

  // Show immediate debt reminder notification
  Future<void> showDebtReminderNotification({
    required String friendName,
    required double amount,
    required String type, // 'owe' or 'owed'
    required int daysPending,
  }) async {
    final title = type == 'owe' 
        ? '💰 Payment Reminder' 
        : '📥 Money Owed to You';
    
    final message = type == 'owe'
        ? 'You owe $friendName ${AppConstants.currencySymbol}${amount.toStringAsFixed(0)} for $daysPending days'
        : '$friendName owes you ${AppConstants.currencySymbol}${amount.toStringAsFixed(0)} for $daysPending days';

    await _showNotification(
      id: friendName.hashCode + type.hashCode,
      title: title,
      body: message,
      channelId: 'debt_reminders',
      payload: 'debt:$friendName:$type:$amount',
    );
  }

  // Show group expense reminder
  Future<void> showGroupExpenseReminder({
    required String groupName,
    required String expenseTitle,
    required double yourShare,
    required String paidBy,
  }) async {
    final title = '👥 Group Expense Reminder';
    final message = 'Your share for "$expenseTitle" in $groupName: ${AppConstants.currencySymbol}${yourShare.toStringAsFixed(0)} (paid by $paidBy)';

    await _showNotification(
      id: expenseTitle.hashCode + groupName.hashCode,
      title: title,
      body: message,
      channelId: 'debt_reminders',
      payload: 'group:$groupName:$expenseTitle',
    );
  }

  // Show overdue payment notification
  Future<void> showOverduePaymentNotification({
    required String friendName,
    required double amount,
    required int daysOverdue,
  }) async {
    final title = '🚨 Overdue Payment';
    final message = 'Payment to $friendName is $daysOverdue days overdue! Amount: ${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}';

    await _showNotification(
      id: 9999 + friendName.hashCode,
      title: title,
      body: message,
      channelId: 'urgent_payments',
      payload: 'overdue:$friendName:$amount',
    );
  }

  // Generic notification method
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'debt_reminders' ? 'Debt Reminders' :
      channelId == 'urgent_payments' ? 'Urgent Payments' : 'Financial Summary',
      channelDescription: 'Financial notifications',
      importance: channelId == 'urgent_payments' ? Importance.max : Importance.high,
      priority: channelId == 'urgent_payments' ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: channelId == 'urgent_payments',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Update notification preferences
  Future<void> updateNotificationPreference(String type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_notifications_$type', enabled);

    // Re-schedule notifications if enabled
    if (enabled) {
      await _scheduleRecurringNotifications();
    }
  }

  // Check if notification type is enabled
  Future<bool> isNotificationEnabled(String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('bg_notifications_$type') ?? true;
  }

  // Schedule a one-time debt analysis notification
  Future<void> scheduleDebtAnalysisNotification(String userId) async {
    try {
      if (!await isNotificationEnabled('daily_debt')) return;

      // Fetch debt data from Firestore
      final debtService = DebtService();

      // Get both lent and borrowed debts
      final lentDebtsStream = debtService.getLentDebts(userId);
      final borrowedDebtsStream = debtService.getBorrowedDebts(userId);

      // Get the first snapshot from streams
      final lentDebts = await lentDebtsStream.first;
      final borrowedDebts = await borrowedDebtsStream.first;

      // Combine all debts
      final allDebts = [...lentDebts, ...borrowedDebts];

      // Filter pending debts
      final pendingDebts = allDebts.where((debt) =>
        debt.status.toString().contains('pending') || debt.status.toString().contains('partially_paid')
      ).toList();

      if (pendingDebts.isNotEmpty) {
        final totalOwed = pendingDebts
            .where((debt) => debt.debtorId == userId)
            .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

        final totalLent = pendingDebts
            .where((debt) => debt.creditorId == userId)
            .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

        String message = '';
        if (totalOwed > 0 && totalLent > 0) {
          message = 'You owe ${AppConstants.currencySymbol}${totalOwed.toStringAsFixed(0)} and are owed ${AppConstants.currencySymbol}${totalLent.toStringAsFixed(0)}';
        } else if (totalOwed > 0) {
          message = 'You have pending payments of ${AppConstants.currencySymbol}${totalOwed.toStringAsFixed(0)}';
        } else if (totalLent > 0) {
          message = 'You are owed ${AppConstants.currencySymbol}${totalLent.toStringAsFixed(0)} from friends';
        }

        if (message.isNotEmpty) {
          await _showNotification(
            id: _dailyDebtReminderId + Random().nextInt(1000),
            title: '💰 Payment Reminder',
            body: message,
            channelId: 'debt_reminders',
            payload: 'debt_analysis',
          );
        }
      }
    } catch (e) {
      debugPrint('Error in debt analysis notification: $e');
    }
  }
}
