import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/currency_constants.dart';
import 'currency_model.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String category;
  final String description;
  final double amount; // Original amount in original currency
  final String currencyCode; // Original currency code (e.g., 'USD', 'INR', 'EUR')
  final double? convertedAmount; // Amount converted to user's default currency
  final String? convertedCurrencyCode; // User's default currency code
  final double? exchangeRate; // Exchange rate used for conversion
  final DateTime date;
  final String? mood;
  final GeoPoint? location;
  final bool isGroupExpense;
  final String? groupId; // ID of the specific group this expense belongs to
  final bool isReimbursement; // Flag to identify reimbursements
  final bool isDirectDebt; // Flag to identify direct debt transactions
  final List<Map<String, dynamic>> participants; // List of {userId, share}
  final List<String>? imageUrls;
  final List<Map<String, dynamic>>? paymentNotes; // List of payment records

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.amount,
    this.currencyCode = 'INR', // Default to Indian Rupee for backward compatibility
    this.convertedAmount,
    this.convertedCurrencyCode,
    this.exchangeRate,
    required this.date,
    this.mood,
    this.location,
    this.isGroupExpense = false,
    this.groupId,
    this.isReimbursement = false,
    this.isDirectDebt = false,
    this.participants = const [],
    this.imageUrls,
    this.paymentNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'description': description,
      'amount': amount,
      'currencyCode': currencyCode,
      'convertedAmount': convertedAmount,
      'convertedCurrencyCode': convertedCurrencyCode,
      'exchangeRate': exchangeRate,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'location': location,
      'isGroupExpense': isGroupExpense,
      'groupId': groupId,
      'isReimbursement': isReimbursement,
      'isDirectDebt': isDirectDebt,
      'participants': participants,
      'imageUrls': imageUrls,
      'paymentNotes': paymentNotes,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currencyCode: map['currencyCode'] ?? 'INR', // Default to INR for backward compatibility
      convertedAmount: map['convertedAmount']?.toDouble(),
      convertedCurrencyCode: map['convertedCurrencyCode'],
      exchangeRate: map['exchangeRate']?.toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      mood: map['mood'],
      location: map['location'],
      isGroupExpense: map['isGroupExpense'] ?? false,
      groupId: map['groupId'],
      isReimbursement: map['isReimbursement'] ?? false,
      isDirectDebt: map['isDirectDebt'] ?? false,
      participants: List<Map<String, dynamic>>.from(map['participants'] ?? []),
      imageUrls: map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      paymentNotes: map['paymentNotes'] != null ? List<Map<String, dynamic>>.from(map['paymentNotes']) : null,
    );
  }

  factory ExpenseModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel.fromMap(data);
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? description,
    double? amount,
    String? currencyCode,
    double? convertedAmount,
    String? convertedCurrencyCode,
    double? exchangeRate,
    DateTime? date,
    String? mood,
    GeoPoint? location,
    bool? isGroupExpense,
    String? groupId,
    bool? isReimbursement,
    bool? isDirectDebt,
    List<Map<String, dynamic>>? participants,
    List<String>? imageUrls,
    List<Map<String, dynamic>>? paymentNotes,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      convertedCurrencyCode: convertedCurrencyCode ?? this.convertedCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      location: location ?? this.location,
      isGroupExpense: isGroupExpense ?? this.isGroupExpense,
      groupId: groupId ?? this.groupId,
      isReimbursement: isReimbursement ?? this.isReimbursement,
      isDirectDebt: isDirectDebt ?? this.isDirectDebt,
      participants: participants ?? this.participants,
      imageUrls: imageUrls ?? this.imageUrls,
      paymentNotes: paymentNotes ?? this.paymentNotes,
    );
  }

  // Currency helper methods

  // Get currency model for this expense
  CurrencyModel get currency {
    return CurrencyConstants.getCurrencyByCode(currencyCode) ?? CurrencyConstants.defaultCurrency;
  }

  // Format amount with currency symbol
  String get formattedAmount {
    return currency.formatAmount(amount);
  }

  // Convert amount to another currency
  double convertAmountTo(String targetCurrencyCode) {
    final targetCurrency = CurrencyConstants.getCurrencyByCode(targetCurrencyCode);
    if (targetCurrency == null) return amount;
    return currency.convertTo(amount, targetCurrency);
  }

  // Get formatted amount in another currency
  String getFormattedAmountIn(String targetCurrencyCode) {
    final targetCurrency = CurrencyConstants.getCurrencyByCode(targetCurrencyCode);
    if (targetCurrency == null) return formattedAmount;
    final convertedAmount = convertAmountTo(targetCurrencyCode);
    return targetCurrency.formatAmount(convertedAmount);
  }

  // Get the display amount (converted amount if available, otherwise original)
  double get displayAmount {
    return convertedAmount ?? amount;
  }

  // Get the display currency code (converted currency if available, otherwise original)
  String get displayCurrencyCode {
    return convertedCurrencyCode ?? currencyCode;
  }

  // Get the display currency model
  CurrencyModel get displayCurrency {
    return CurrencyConstants.getCurrencyByCode(displayCurrencyCode) ?? currency;
  }

  // Get formatted display amount
  String get formattedDisplayAmount {
    return displayCurrency.formatAmount(displayAmount);
  }

  // Get conversion info text (e.g., "₹100 (≈$1.20)")
  String get conversionInfoText {
    if (convertedAmount == null || convertedCurrencyCode == null || currencyCode == displayCurrencyCode) {
      return formattedAmount;
    }

    final originalCurrency = CurrencyConstants.getCurrencyByCode(currencyCode);
    final convertedCurrency = CurrencyConstants.getCurrencyByCode(convertedCurrencyCode!);

    if (originalCurrency == null || convertedCurrency == null) {
      return formattedAmount;
    }

    final originalText = originalCurrency.formatAmount(amount);
    final convertedText = convertedCurrency.formatAmount(convertedAmount!);

    return '$originalText (≈$convertedText)';
  }

  // Check if this expense has been converted
  bool get isConverted {
    return convertedAmount != null &&
           convertedCurrencyCode != null &&
           convertedCurrencyCode != currencyCode;
  }

  // Get exchange rate info text
  String? get exchangeRateText {
    if (exchangeRate == null || !isConverted) return null;

    final originalCurrency = CurrencyConstants.getCurrencyByCode(currencyCode);
    final convertedCurrency = CurrencyConstants.getCurrencyByCode(convertedCurrencyCode!);

    if (originalCurrency == null || convertedCurrency == null) return null;

    return '1 ${originalCurrency.code} = ${exchangeRate!.toStringAsFixed(4)} ${convertedCurrency.code}';
  }

  // Utility methods for expense calculations and filtering

  // Get the effective amount after considering payment notes and currency conversion
  double get effectiveAmount {
    // Use converted amount if available, otherwise use original amount
    final baseAmount = convertedAmount ?? amount;

    // For regular expenses or if there are no payment notes, just return the base amount
    if (!isGroupExpense || paymentNotes == null || paymentNotes!.isEmpty) {
      return baseAmount;
    }

    // For group expenses, we need to consider the base amount
    // We don't subtract payment notes because we want to keep the original expense amount
    // The reimbursements are already tracked as separate negative expenses
    return baseAmount;
  }

  // Get the user's share of a group expense
  double getUserShare(String userId) {
    // If it's not a group expense, return 0 (user's share should be shown in regular expenses)
    if (!isGroupExpense) return 0;

    // If this user created the expense (paid for everyone), return the full amount
    if (this.userId == userId) {
      // Find the user's participant entry to get their actual share
      final userParticipant = participants.firstWhere(
        (p) => p['userId'] == userId,
        orElse: () => {'share': 0.0},
      );

      // Get the original share amount
      final originalShare = userParticipant['share'] as double? ?? 0.0;

      // If we have conversion data, convert the share proportionally
      if (convertedAmount != null && amount != 0) {
        final conversionRatio = convertedAmount! / amount;
        return originalShare * conversionRatio;
      }

      // Return only the user's share, not the full amount
      return originalShare;
    }

    // If the user is a participant but didn't create the expense
    final userParticipant = participants.firstWhere(
      (p) => p['userId'] == userId,
      orElse: () => {'share': 0.0},
    );

    final originalShare = userParticipant['share'] as double? ?? 0.0;

    // If we have conversion data, convert the share proportionally
    if (convertedAmount != null && amount != 0) {
      final conversionRatio = convertedAmount! / amount;
      return originalShare * conversionRatio;
    }

    return originalShare;
  }

  // Calculate total amount for a list of expenses
  static double calculateTotal(List<ExpenseModel> expenses) {
    return expenses.fold(0, (total, expense) => total + expense.effectiveAmount);
  }

  // Calculate total amount for a specific category
  static double calculateCategoryTotal(
      List<ExpenseModel> expenses, String category) {
    return expenses
        .where((expense) => expense.category == category)
        .fold(0, (total, expense) => total + expense.effectiveAmount);
  }

  // Calculate total amount for a specific date range
  static double calculateDateRangeTotal(
      List<ExpenseModel> expenses, DateTime startDate, DateTime endDate) {
    return expenses
        .where((expense) =>
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold(0, (total, expense) => total + expense.effectiveAmount);
  }

  // Calculate total amount for a specific mood
  static double calculateMoodTotal(List<ExpenseModel> expenses, String mood) {
    return expenses
        .where((expense) => expense.mood == mood)
        .fold(0, (total, expense) => total + expense.effectiveAmount);
  }

  // Get expenses for a specific time period (daily, weekly, monthly, yearly)
  static List<ExpenseModel> getExpensesForPeriod(
      List<ExpenseModel> expenses, String period, DateTime date) {
    switch (period) {
      case 'daily':
        return expenses.where((expense) {
          return expense.date.year == date.year &&
              expense.date.month == date.month &&
              expense.date.day == date.day;
        }).toList();

      case 'weekly':
        // Get the start of the week (Monday)
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return expenses.where((expense) {
          return expense.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

      case 'monthly':
        return expenses.where((expense) {
          return expense.date.year == date.year &&
              expense.date.month == date.month;
        }).toList();

      case 'yearly':
        return expenses.where((expense) {
          return expense.date.year == date.year;
        }).toList();

      default:
        return expenses;
    }
  }
}
