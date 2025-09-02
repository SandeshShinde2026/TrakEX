import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/in_app_notification.dart';
import '../services/fcm_service.dart';

class InAppNotificationProvider extends ChangeNotifier {
  List<InAppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<InAppNotification> get notifications => _notifications;
  List<InAppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotifications => _notifications.isNotEmpty;

  // Constructor
  InAppNotificationProvider() {
    _loadNotifications();
    _addSampleNotifications(); // Add some sample notifications for demo
  }

  // Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('in_app_notifications') ?? [];
      
      _notifications = notificationsJson
          .map((json) => InAppNotification.fromJson(jsonDecode(json)))
          .toList();
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load notifications: $e';
      notifyListeners();
    }
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      await prefs.setStringList('in_app_notifications', notificationsJson);
    } catch (e) {
      _error = 'Failed to save notifications: $e';
      notifyListeners();
    }
  }

  // Add a new notification
  Future<void> addNotification(InAppNotification notification) async {
    _notifications.insert(0, notification);
    
    // Keep only the last 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    
    notifyListeners();
    await _saveNotifications();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveNotifications();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    notifyListeners();
    await _saveNotifications();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
    await _saveNotifications();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    notifyListeners();
    await _saveNotifications();
  }

  // Load notifications from Firestore for a specific user
  Future<void> loadNotificationsFromFirestore(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get notifications from Firestore
      final firestoreNotifications = await FCMService.getUserNotifications(userId);

      // Merge with local notifications (avoid duplicates)
      final existingIds = _notifications.map((n) => n.id).toSet();
      final newNotifications = firestoreNotifications
          .where((n) => !existingIds.contains(n.id))
          .toList();

      // Add new notifications
      _notifications.addAll(newNotifications);

      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Keep only the last 100 notifications
      if (_notifications.length > 100) {
        _notifications = _notifications.take(100).toList();
      }

      _isLoading = false;
      notifyListeners();
      await _saveNotifications();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load notifications from server: $e';
      notifyListeners();
    }
  }

  // Add sample notifications for demo
  void _addSampleNotifications() {
    final sampleNotifications = [
      InAppNotification.create(
        id: 'sample_1',
        title: 'Expense Added Successfully',
        message: 'Your grocery expense of ₹450 has been added to your account.',
        type: NotificationType.transactionSuccess,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      InAppNotification.create(
        id: 'sample_2',
        title: 'Group Expense Settled',
        message: 'John settled the dinner expense of ₹800 in "Weekend Trip" group.',
        type: NotificationType.splitSettlement,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      InAppNotification.create(
        id: 'sample_3',
        title: 'Budget Goal Achieved! 🎉',
        message: 'Congratulations! You stayed within your monthly food budget.',
        type: NotificationType.budgetMilestone,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      InAppNotification.create(
        id: 'sample_4',
        title: 'Friend Activity',
        message: 'Sarah added a new expense in your shared group "Office Lunch".',
        type: NotificationType.friendActivity,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      InAppNotification.create(
        id: 'sample_5',
        title: 'Payment Received',
        message: 'Mike paid you ₹300 for the movie tickets.',
        type: NotificationType.paymentReceived,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Only add sample notifications if there are no existing notifications
    if (_notifications.isEmpty) {
      _notifications.addAll(sampleNotifications);
      notifyListeners();
      _saveNotifications();
    }
  }

  // Helper methods for creating specific notification types
  Future<void> addTransactionSuccessNotification({
    required String expenseTitle,
    required double amount,
  }) async {
    final notification = InAppNotification.create(
      id: 'transaction_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Expense Added Successfully',
      message: 'Your $expenseTitle expense of ₹${amount.toStringAsFixed(0)} has been added.',
      type: NotificationType.transactionSuccess,
    );
    await addNotification(notification);
  }

  Future<void> addSplitSettlementNotification({
    required String friendName,
    required String groupName,
    required double amount,
  }) async {
    final notification = InAppNotification.create(
      id: 'split_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Group Expense Settled',
      message: '$friendName settled ₹${amount.toStringAsFixed(0)} in "$groupName" group.',
      type: NotificationType.splitSettlement,
    );
    await addNotification(notification);
  }

  Future<void> addBudgetMilestoneNotification({
    required String category,
    required String achievement,
  }) async {
    final notification = InAppNotification.create(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Budget Achievement! 🎉',
      message: '$achievement for $category category.',
      type: NotificationType.budgetMilestone,
    );
    await addNotification(notification);
  }

  Future<void> addFriendActivityNotification({
    required String friendName,
    required String activity,
  }) async {
    final notification = InAppNotification.create(
      id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Friend Activity',
      message: '$friendName $activity',
      type: NotificationType.friendActivity,
    );
    await addNotification(notification);
  }
}
