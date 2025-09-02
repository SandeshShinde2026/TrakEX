import 'package:flutter/material.dart';

enum NotificationType {
  transactionSuccess,
  splitSettlement,
  budgetMilestone,
  friendActivity,
  debtReminder,
  paymentReceived,
  groupExpense,
  budgetAlert,
}

class InAppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final IconData icon;
  final Color color;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    required this.icon,
    required this.color,
  });

  // Factory constructor to create notification from type
  factory InAppNotification.create({
    required String id,
    required String title,
    required String message,
    required NotificationType type,
    DateTime? timestamp,
    bool isRead = false,
    Map<String, dynamic>? data,
  }) {
    final now = timestamp ?? DateTime.now();
    
    IconData icon;
    Color color;
    
    switch (type) {
      case NotificationType.transactionSuccess:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.splitSettlement:
        icon = Icons.group_work;
        color = Colors.blue;
        break;
      case NotificationType.budgetMilestone:
        icon = Icons.emoji_events;
        color = Colors.orange;
        break;
      case NotificationType.friendActivity:
        icon = Icons.people;
        color = Colors.purple;
        break;
      case NotificationType.debtReminder:
        icon = Icons.money_off;
        color = Colors.red;
        break;
      case NotificationType.paymentReceived:
        icon = Icons.payment;
        color = Colors.green;
        break;
      case NotificationType.groupExpense:
        icon = Icons.group;
        color = Colors.indigo;
        break;
      case NotificationType.budgetAlert:
        icon = Icons.warning;
        color = Colors.amber;
        break;
    }
    
    return InAppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: now,
      isRead: isRead,
      data: data,
      icon: icon,
      color: color,
    );
  }

  // Copy with method for updating notification
  InAppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    IconData? icon,
    Color? color,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'data': data,
    };
  }

  // Create from JSON
  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = NotificationType.values.firstWhere(
      (e) => e.toString() == typeString,
      orElse: () => NotificationType.transactionSuccess,
    );
    
    return InAppNotification.create(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: type,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }

  // Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
