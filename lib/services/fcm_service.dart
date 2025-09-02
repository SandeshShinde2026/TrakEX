import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/debt_model.dart';
import '../providers/in_app_notification_provider.dart';
import '../models/in_app_notification.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize FCM
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission granted: ${settings.authorizationStatus}');

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _updateUserFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('FCM initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Update user's FCM token in Firestore
  static Future<void> _updateUserFCMToken(String token) async {
    try {
      // This should be called with the current user's ID
      // For now, we'll implement this in the auth provider
      debugPrint('FCM token needs to be updated: $token');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Update user's FCM token in Firestore (public method)
  static Future<void> updateUserFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      debugPrint('FCM token updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating FCM token for user $userId: $e');
    }
  }

  // Send reminder notification to a specific user
  static Future<bool> sendReminderNotification({
    required UserModel friend,
    required UserModel currentUser,
    required DebtModel debt,
    required int daysSince,
    required bool currentUserOwes,
  }) async {
    try {
      if (friend.fcmToken == null || friend.fcmToken!.isEmpty) {
        debugPrint('Friend ${friend.name} has no FCM token');
        return false;
      }

      String title;
      String body;

      if (currentUserOwes) {
        // Current user owes money to friend
        title = '💰 Payment Reminder';
        body = '${currentUser.name} reminded you: You are owed ₹${debt.amount.toStringAsFixed(0)}';
      } else {
        // Friend owes money to current user
        title = '💸 Payment Due';
        body = '${currentUser.name} reminded you: You owe ₹${debt.amount.toStringAsFixed(0)}';
      }

      if (daysSince > 0) {
        body += ' ($daysSince days ago)';
      }

      if (debt.description.isNotEmpty) {
        body += ' for "${debt.description}"';
      }

      // Create the notification payload
      final payload = {
        'to': friend.fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': {
          'type': 'debt_reminder',
          'debtId': debt.id,
          'senderId': currentUser.id,
          'senderName': currentUser.name,
          'amount': debt.amount.toString(),
          'reminderType': currentUserOwes ? 'owed' : 'owe',
          'daysSince': daysSince.toString(),
          'description': debt.description,
        },
      };

      // Send the notification
      final response = await _sendFCMMessage(payload);
      
      if (response) {
        // Also create an in-app notification record in Firestore
        await _createInAppNotificationRecord(
          receiverId: friend.id,
          senderId: currentUser.id,
          senderName: currentUser.name,
          title: title,
          message: body,
          type: 'debt_reminder',
          data: {
            'debtId': debt.id,
            'amount': debt.amount,
            'reminderType': currentUserOwes ? 'owed' : 'owe',
          },
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error sending reminder notification: $e');
      return false;
    }
  }

  // Send group expense reminder notification
  static Future<bool> sendGroupExpenseReminderNotification({
    required UserModel friend,
    required UserModel currentUser,
    required DebtModel groupDebt,
    required int daysSince,
    required bool currentUserOwes,
  }) async {
    try {
      if (friend.fcmToken == null || friend.fcmToken!.isEmpty) {
        debugPrint('Friend ${friend.name} has no FCM token');
        return false;
      }

      String title;
      String body;

      if (currentUserOwes) {
        title = '💰 Group Expense Reminder';
        body = '${currentUser.name} reminded you: You are owed ₹${groupDebt.amount.toStringAsFixed(0)} from group expense';
      } else {
        title = '💸 Group Expense Due';
        body = '${currentUser.name} reminded you: You owe ₹${groupDebt.amount.toStringAsFixed(0)} for group expense';
      }

      if (groupDebt.description.isNotEmpty) {
        body += ' "${groupDebt.description}"';
      }

      final payload = {
        'to': friend.fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': {
          'type': 'group_expense_reminder',
          'debtId': groupDebt.id,
          'senderId': currentUser.id,
          'senderName': currentUser.name,
          'amount': groupDebt.amount.toString(),
          'reminderType': currentUserOwes ? 'group_owed' : 'group_owe',
          'daysSince': daysSince.toString(),
          'description': groupDebt.description,
        },
      };

      final response = await _sendFCMMessage(payload);
      
      if (response) {
        await _createInAppNotificationRecord(
          receiverId: friend.id,
          senderId: currentUser.id,
          senderName: currentUser.name,
          title: title,
          message: body,
          type: 'group_expense_reminder',
          data: {
            'debtId': groupDebt.id,
            'amount': groupDebt.amount,
            'reminderType': currentUserOwes ? 'group_owed' : 'group_owe',
          },
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error sending group expense reminder: $e');
      return false;
    }
  }

  // Send FCM message using HTTP API
  static Future<bool> _sendFCMMessage(Map<String, dynamic> payload) async {
    try {
      debugPrint('FCM Payload: ${jsonEncode(payload)}');

      // Option 1: Use Firebase Functions (Recommended)
      // You would call your Firebase Function here
      // Example: await http.post('https://your-region-your-project.cloudfunctions.net/sendNotification', ...)

      // Option 2: Use your own backend server
      // Example: await http.post('https://your-backend.com/api/send-notification', ...)

      // Option 3: For testing - use FCM REST API directly (NOT recommended for production)
      // This requires your Firebase Server Key which should NEVER be in client code

      // For now, we'll create the notification record in Firestore
      // The actual push notification would be sent by your backend
      debugPrint('FCM notification would be sent in production with proper backend');

      return true; // Simulate successful send
    } catch (e) {
      debugPrint('Error sending FCM message: $e');
      return false;
    }
  }

  // Create in-app notification record in Firestore
  static Future<void> _createInAppNotificationRecord({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'receiverId': receiverId,
        'senderId': senderId,
        'senderName': senderName,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('In-app notification record created');
    } catch (e) {
      debugPrint('Error creating in-app notification record: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.notification?.title}');
    // Handle the message when app is in foreground
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Received background message: ${message.notification?.title}');
    // Handle the message when app is in background
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.data}');
    // Handle navigation when notification is tapped
  }

  // Get user's in-app notifications from Firestore
  static Future<List<InAppNotification>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return InAppNotification.create(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          type: _getNotificationType(data['type'] ?? ''),
          data: Map<String, dynamic>.from(data['data'] ?? {}),
          isRead: data['isRead'] ?? false,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  // Convert string to NotificationType
  static NotificationType _getNotificationType(String type) {
    switch (type) {
      case 'debt_reminder':
        return NotificationType.debtReminder;
      case 'group_expense_reminder':
        return NotificationType.groupExpense;
      default:
        return NotificationType.friendActivity; // Default fallback
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
