import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';
import '../models/user_model.dart';
import '../models/in_app_notification.dart';
import 'background_notification_service.dart';
import 'fcm_service.dart';
import '../providers/in_app_notification_provider.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackgroundNotificationService _backgroundService = BackgroundNotificationService();

  // Send reminder for a specific debt
  Future<bool> sendDebtReminder({
    required DebtModel debt,
    required UserModel friend,
    required UserModel currentUser,
    required InAppNotificationProvider inAppProvider,
  }) async {
    try {
      debugPrint('ReminderService: Sending debt reminder for debt ${debt.id}');

      // Determine who owes whom
      final bool currentUserOwes = debt.creditorId == friend.id;
      final String reminderType = currentUserOwes ? 'you_owe' : 'friend_owes';
      
      // Calculate days since debt was created
      final daysSince = DateTime.now().difference(debt.createdAt).inDays;

      // Create reminder document in Firestore
      final reminderData = {
        'debtId': debt.id,
        'senderId': currentUser.id,
        'senderName': currentUser.name,
        'receiverId': friend.id,
        'receiverName': friend.name,
        'amount': debt.amount,
        'description': debt.description,
        'reminderType': reminderType,
        'daysSince': daysSince,
        'timestamp': FieldValue.serverTimestamp(),
        'debtType': debt.debtType.toString(),
      };

      // Save reminder to Firestore
      await _firestore.collection('reminders').add(reminderData);

      // Send push notification to friend's device using FCM
      final notificationSent = await FCMService.sendReminderNotification(
        friend: friend,
        currentUser: currentUser,
        debt: debt,
        daysSince: daysSince,
        currentUserOwes: currentUserOwes,
      );

      if (!notificationSent) {
        debugPrint('ReminderService: Failed to send FCM notification, falling back to local notification');
        // Fallback to local notification for current user (for testing)
        await _sendPushNotificationToFriend(
          friend: friend,
          currentUser: currentUser,
          debt: debt,
          daysSince: daysSince,
          currentUserOwes: currentUserOwes,
        );
      }

      // Note: In-app notifications will be created when the friend opens their app
      // and sees the reminder in Firestore. We don't add it directly here because
      // inAppProvider is for the current user's session, not the friend's session.

      debugPrint('ReminderService: Reminder sent successfully');
      return true;
    } catch (e) {
      debugPrint('ReminderService: Error sending reminder: $e');
      return false;
    }
  }

  // Send push notification to friend's device
  Future<void> _sendPushNotificationToFriend({
    required UserModel friend,
    required UserModel currentUser,
    required DebtModel debt,
    required int daysSince,
    required bool currentUserOwes,
  }) async {
    try {
      // Send background notification (this will appear in notification drawer)
      await _backgroundService.showDebtReminderNotification(
        friendName: currentUser.name,
        amount: debt.amount,
        type: currentUserOwes ? 'owed' : 'owe',
        daysPending: daysSince,
      );

      debugPrint('ReminderService: Push notification sent to ${friend.name}');
    } catch (e) {
      debugPrint('ReminderService: Error sending push notification: $e');
    }
  }



  // Send reminder for group expense share
  Future<bool> sendGroupExpenseReminder({
    required DebtModel groupDebt,
    required UserModel friend,
    required UserModel currentUser,
    required InAppNotificationProvider inAppProvider,
  }) async {
    try {
      debugPrint('ReminderService: Sending group expense reminder for debt ${groupDebt.id}');

      // For group expenses, determine who owes whom
      final bool currentUserOwes = groupDebt.creditorId == friend.id;
      final daysSince = DateTime.now().difference(groupDebt.createdAt).inDays;

      // Create reminder document
      final reminderData = {
        'debtId': groupDebt.id,
        'senderId': currentUser.id,
        'senderName': currentUser.name,
        'receiverId': friend.id,
        'receiverName': friend.name,
        'amount': groupDebt.amount,
        'description': groupDebt.description,
        'reminderType': currentUserOwes ? 'group_you_owe' : 'group_friend_owes',
        'daysSince': daysSince,
        'timestamp': FieldValue.serverTimestamp(),
        'debtType': 'groupExpense',
      };

      await _firestore.collection('reminders').add(reminderData);

      // Send notifications using FCM
      final notificationSent = await FCMService.sendGroupExpenseReminderNotification(
        friend: friend,
        currentUser: currentUser,
        groupDebt: groupDebt,
        daysSince: daysSince,
        currentUserOwes: currentUserOwes,
      );

      if (!notificationSent) {
        debugPrint('ReminderService: Failed to send FCM group notification, falling back to local notification');
        // Fallback to local notification for current user (for testing)
        await _sendGroupExpensePushNotification(
          friend: friend,
          currentUser: currentUser,
          debt: groupDebt,
          daysSince: daysSince,
          currentUserOwes: currentUserOwes,
        );
      }

      // Note: In-app notifications will be created when the friend opens their app

      return true;
    } catch (e) {
      debugPrint('ReminderService: Error sending group expense reminder: $e');
      return false;
    }
  }

  // Send push notification for group expense
  Future<void> _sendGroupExpensePushNotification({
    required UserModel friend,
    required UserModel currentUser,
    required DebtModel debt,
    required int daysSince,
    required bool currentUserOwes,
  }) async {
    try {
      await _backgroundService.showDebtReminderNotification(
        friendName: currentUser.name,
        amount: debt.amount,
        type: currentUserOwes ? 'owed' : 'owe',
        daysPending: daysSince,
      );
    } catch (e) {
      debugPrint('ReminderService: Error sending group expense push notification: $e');
    }
  }



  // Get reminder history for a debt
  Future<List<Map<String, dynamic>>> getReminderHistory(String debtId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('debtId', isEqualTo: debtId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('ReminderService: Error getting reminder history: $e');
      return [];
    }
  }

  // Check for new reminders for the current user and add them as in-app notifications
  Future<void> checkAndAddNewReminders({
    required String userId,
    required InAppNotificationProvider inAppProvider,
  }) async {
    try {
      // Get reminders received by this user in the last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      final querySnapshot = await _firestore
          .collection('reminders')
          .where('receiverId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: yesterday)
          .orderBy('timestamp', descending: true)
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final reminderId = doc.id;

        // Check if we've already created an in-app notification for this reminder
        final existingNotifications = inAppProvider.notifications
            .where((n) => n.data?['reminderId'] == reminderId)
            .toList();

        if (existingNotifications.isEmpty) {
          // Create in-app notification for this reminder
          await _createInAppNotificationFromReminder(data, reminderId, inAppProvider);
        }
      }
    } catch (e) {
      debugPrint('ReminderService: Error checking for new reminders: $e');
    }
  }

  // Create in-app notification from reminder data
  Future<void> _createInAppNotificationFromReminder(
    Map<String, dynamic> reminderData,
    String reminderId,
    InAppNotificationProvider inAppProvider,
  ) async {
    try {
      final senderName = reminderData['senderName'] ?? 'Someone';
      final amount = reminderData['amount'] ?? 0.0;
      final description = reminderData['description'] ?? '';
      final reminderType = reminderData['reminderType'] ?? '';

      String title;
      String message;

      if (reminderType.contains('you_owe') || reminderType.contains('group_you_owe')) {
        title = 'Payment Reminder Received';
        message = '$senderName reminded you about ₹${amount.toStringAsFixed(0)} they owe you';
      } else {
        title = 'Payment Reminder';
        message = '$senderName reminded you about ₹${amount.toStringAsFixed(0)} you owe them';
      }

      if (description.isNotEmpty) {
        message += ' for "$description"';
      }

      // Create the in-app notification
      final notification = InAppNotification.create(
        id: '${reminderId}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: NotificationType.debtReminder,
        data: {
          'reminderId': reminderId,
          'debtId': reminderData['debtId'],
          'friendId': reminderData['senderId'],
          'friendName': senderName,
          'amount': amount,
          'reminderType': reminderType,
        },
      );

      inAppProvider.addNotification(notification);
      debugPrint('ReminderService: Created in-app notification for reminder $reminderId');
    } catch (e) {
      debugPrint('ReminderService: Error creating in-app notification from reminder: $e');
    }
  }
}
