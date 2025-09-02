import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  cash,
  upi,
  bankTransfer,
  other,
}

enum PaymentStatus {
  pending,
  paid,
  completed,
  failed,
  cancelled,
  verifying,
}

enum DebtType {
  direct,
  groupExpense,
}

class DebtModel {
  final String id;
  final String creditorId; // Person who is owed money
  final String debtorId;   // Person who owes money
  final double amount;
  final String description;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate;
  final String? expenseId; // Associated expense if any
  final List<Map<String, dynamic>> repayments; // List of {amount, date}
  final int karmaPoints; // Points earned for timely repayment
  final DebtType debtType; // Type of debt: direct or groupExpense

  DebtModel({
    required this.id,
    required this.creditorId,
    required this.debtorId,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.expenseId,
    this.repayments = const [],
    this.karmaPoints = 0,
    this.debtType = DebtType.direct, // Default to direct debt
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditorId': creditorId,
      'debtorId': debtorId,
      'amount': amount,
      'description': description,
      'paymentMethod': _paymentMethodToString(paymentMethod),
      'status': _paymentStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'expenseId': expenseId,
      'repayments': repayments,
      'karmaPoints': karmaPoints,
      'debtType': _debtTypeToString(debtType),
    };
  }

  static String _debtTypeToString(DebtType type) {
    switch (type) {
      case DebtType.direct:
        return 'direct';
      case DebtType.groupExpense:
        return 'groupExpense';
    }
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    // Handle legacy fields
    String? creditorId = map['creditorId'];
    String? debtorId = map['debtorId'];

    // If using old field names, convert them
    if (creditorId == null && map['lenderId'] != null) {
      creditorId = map['lenderId'];
    }

    if (debtorId == null && map['borrowerId'] != null) {
      debtorId = map['borrowerId'];
    }

    // Convert string status to enum
    PaymentStatus statusEnum;
    if (map['status'] is String) {
      statusEnum = _stringToPaymentStatus(map['status']);
    } else {
      statusEnum = PaymentStatus.pending;
    }

    // Convert string payment method to enum or use default
    PaymentMethod paymentMethodEnum;
    if (map['paymentMethod'] is String) {
      paymentMethodEnum = _stringToPaymentMethod(map['paymentMethod']);
    } else {
      paymentMethodEnum = PaymentMethod.cash;
    }

    // Convert string debt type to enum or use default
    DebtType debtTypeEnum;
    if (map['debtType'] is String) {
      debtTypeEnum = _stringToDebtType(map['debtType']);
    } else {
      // For backward compatibility, check if it's associated with an expense
      debtTypeEnum = map['expenseId'] != null ? DebtType.groupExpense : DebtType.direct;
    }

    return DebtModel(
      id: map['id'] ?? '',
      creditorId: creditorId ?? '',
      debtorId: debtorId ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      paymentMethod: paymentMethodEnum,
      status: statusEnum,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      expenseId: map['expenseId'],
      repayments: List<Map<String, dynamic>>.from(map['repayments'] ?? []),
      karmaPoints: map['karmaPoints'] ?? 0,
      debtType: debtTypeEnum,
    );
  }

  static DebtType _stringToDebtType(String type) {
    switch (type) {
      case 'direct':
        return DebtType.direct;
      case 'groupExpense':
        return DebtType.groupExpense;
      default:
        return DebtType.direct;
    }
  }

  factory DebtModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DebtModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  double get remainingAmount {
    double repaid = 0;
    for (var repayment in repayments) {
      repaid += (repayment['amount'] as num).toDouble();
    }
    return amount - repaid;
  }

  DebtModel copyWith({
    String? id,
    String? creditorId,
    String? debtorId,
    double? amount,
    String? description,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    String? expenseId,
    List<Map<String, dynamic>>? repayments,
    int? karmaPoints,
    DebtType? debtType,
  }) {
    return DebtModel(
      id: id ?? this.id,
      creditorId: creditorId ?? this.creditorId,
      debtorId: debtorId ?? this.debtorId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      expenseId: expenseId ?? this.expenseId,
      repayments: repayments ?? this.repayments,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      debtType: debtType ?? this.debtType,
    );
  }

  static String _paymentMethodToString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.bankTransfer:
        return 'bankTransfer';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod _stringToPaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'other':
        return PaymentMethod.other;
      default:
        return PaymentMethod.cash;
    }
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

  static PaymentStatus _stringToPaymentStatus(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
      case 'partially_paid':
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
}
