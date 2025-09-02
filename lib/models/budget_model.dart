import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final String period; // 'weekly', 'monthly'
  final DateTime startDate;
  final DateTime endDate;
  final double spent;
  final bool alertEnabled;
  final double alertThreshold; // Percentage (0-100) at which to alert

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
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
      'category': category,
      'amount': amount,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'spent': spent,
      'alertEnabled': alertEnabled,
      'alertThreshold': alertThreshold,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      period: map['period'] ?? 'monthly',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      spent: (map['spent'] ?? 0.0).toDouble(),
      alertEnabled: map['alertEnabled'] ?? true,
      alertThreshold: (map['alertThreshold'] ?? 80.0).toDouble(),
    );
  }

  factory BudgetModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel.fromMap(data);
  }

  // Check if this is a dynamically added category (no limit)
  bool get isDynamicCategory => amount >= 999999;

  double get percentageUsed => isDynamicCategory ? 0 : (spent / amount) * 100;

  bool get isOverBudget => !isDynamicCategory && spent > amount;

  bool get isNearThreshold => !isDynamicCategory && percentageUsed >= alertThreshold && !isOverBudget;

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    double? spent,
    bool? alertEnabled,
    double? alertThreshold,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spent: spent ?? this.spent,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }
}
