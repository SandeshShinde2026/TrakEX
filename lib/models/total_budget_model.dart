import 'package:cloud_firestore/cloud_firestore.dart';

class TotalBudgetModel {
  final String id;
  final String userId;
  final double amount;
  final String period; // 'daily', 'weekly', 'monthly'
  final DateTime startDate;
  final DateTime endDate;
  final double spent; // Total amount spent
  final bool alertEnabled;
  final double alertThreshold; // Percentage (0-100) at which to alert

  TotalBudgetModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.spent = 0.0,
    this.alertEnabled = true,
    this.alertThreshold = 80.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'spent': spent,
      'alertEnabled': alertEnabled,
      'alertThreshold': alertThreshold,
    };
  }

  factory TotalBudgetModel.fromMap(Map<String, dynamic> map) {
    return TotalBudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      period: map['period'] ?? 'monthly',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      spent: (map['spent'] ?? 0.0).toDouble(),
      alertEnabled: map['alertEnabled'] ?? true,
      alertThreshold: (map['alertThreshold'] ?? 80.0).toDouble(),
    );
  }

  factory TotalBudgetModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TotalBudgetModel.fromMap(data);
  }

  TotalBudgetModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    double? spent,
    bool? alertEnabled,
    double? alertThreshold,
  }) {
    return TotalBudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spent: spent ?? this.spent,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }

  // Calculate percentage of budget used
  double get percentageUsed => amount > 0 ? (spent / amount) * 100 : 0;

  // Check if over budget
  bool get isOverBudget => spent > amount;

  // Check if near threshold
  bool get isNearThreshold => percentageUsed >= alertThreshold && !isOverBudget;
}
