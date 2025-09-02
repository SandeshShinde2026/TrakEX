import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'debt_model.dart';

class PaymentTransactionModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String description;
  final DateTime timestamp;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? debtId; // Associated debt if any
  final String? expenseId; // Associated expense if any
  final String? upiTransactionId; // UPI transaction ID if available
  final String? upiReferenceId; // UPI reference ID if available
  final Map<String, dynamic>? additionalData; // Additional payment details

  PaymentTransactionModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.method,
    this.debtId,
    this.expenseId,
    this.upiTransactionId,
    this.upiReferenceId,
    this.additionalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': _paymentStatusToString(status),
      'method': _paymentMethodToString(method),
      'debtId': debtId,
      'expenseId': expenseId,
      'upiTransactionId': upiTransactionId,
      'upiReferenceId': upiReferenceId,
      'additionalData': additionalData,
    };
  }

  static String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.verifying:
        return 'verifying';
    }
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.bankTransfer:
        return 'bankTransfer';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentStatus _stringToPaymentStatus(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'verifying':
        return PaymentStatus.verifying;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentMethod _stringToPaymentMethod(String method) {
    switch (method) {
      case 'upi':
        return PaymentMethod.upi;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'cash':
        return PaymentMethod.cash;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.other;
    }
  }

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map) {
    try {
      final String id = map['id']?.toString() ?? '';
      final String fromUserId = map['fromUserId']?.toString() ?? '';
      final String toUserId = map['toUserId']?.toString() ?? '';
      final double amount = (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : 0.0;
      final String description = map['description']?.toString() ?? '';

      // Handle timestamp
      DateTime timestamp;
      if (map['timestamp'] is Timestamp) {
        timestamp = (map['timestamp'] as Timestamp).toDate();
      } else {
        timestamp = DateTime.now();
      }

      // Parse status and method
      final PaymentStatus status = _stringToPaymentStatus(map['status']?.toString() ?? 'pending');
      final PaymentMethod method = _stringToPaymentMethod(map['method']?.toString() ?? 'other');

      // Optional fields
      final String? debtId = map['debtId']?.toString();
      final String? expenseId = map['expenseId']?.toString();
      final String? upiTransactionId = map['upiTransactionId']?.toString();
      final String? upiReferenceId = map['upiReferenceId']?.toString();

      // Additional data
      Map<String, dynamic>? additionalData;
      if (map['additionalData'] != null && map['additionalData'] is Map) {
        additionalData = Map<String, dynamic>.from(map['additionalData'] as Map);
      }

      return PaymentTransactionModel(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        description: description,
        timestamp: timestamp,
        status: status,
        method: method,
        debtId: debtId,
        expenseId: expenseId,
        upiTransactionId: upiTransactionId,
        upiReferenceId: upiReferenceId,
        additionalData: additionalData,
      );
    } catch (e) {
      debugPrint('Error parsing PaymentTransactionModel: $e');
      return PaymentTransactionModel(
        id: map['id']?.toString() ?? '',
        fromUserId: map['fromUserId']?.toString() ?? '',
        toUserId: map['toUserId']?.toString() ?? '',
        amount: 0.0,
        description: '',
        timestamp: DateTime.now(),
        status: PaymentStatus.failed,
        method: PaymentMethod.other,
      );
    }
  }

  factory PaymentTransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Map<String, dynamic> dataWithId = {
      ...data,
      'id': doc.id,
    };
    return PaymentTransactionModel.fromMap(dataWithId);
  }

  PaymentTransactionModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    double? amount,
    String? description,
    DateTime? timestamp,
    PaymentStatus? status,
    PaymentMethod? method,
    String? debtId,
    String? expenseId,
    String? upiTransactionId,
    String? upiReferenceId,
    Map<String, dynamic>? additionalData,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      method: method ?? this.method,
      debtId: debtId ?? this.debtId,
      expenseId: expenseId ?? this.expenseId,
      upiTransactionId: upiTransactionId ?? this.upiTransactionId,
      upiReferenceId: upiReferenceId ?? this.upiReferenceId,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
