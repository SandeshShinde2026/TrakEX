import 'package:flutter/material.dart';

class AppConstants {
  // App name
  static const String appName = 'TrakEX';

  // Expense categories - simplified monochrome icons
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_outlined},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Transportation', 'icon': Icons.directions_car_outlined},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined},
    {'name': 'Housing', 'icon': Icons.home_outlined},
    {'name': 'Utilities', 'icon': Icons.power_outlined},
    {'name': 'Health', 'icon': Icons.medical_services_outlined},
    {'name': 'Education', 'icon': Icons.school_outlined},
    {'name': 'Travel', 'icon': Icons.flight_outlined},
    {'name': 'Personal Care', 'icon': Icons.spa_outlined},
    {'name': 'Gifts & Donations', 'icon': Icons.card_giftcard_outlined},
    {'name': 'Other', 'icon': Icons.more_horiz_outlined},
  ];

  // Mood options - simplified monochrome icons
  static const List<Map<String, dynamic>> moodOptions = [
    {'name': 'Happy', 'icon': Icons.sentiment_very_satisfied_outlined},
    {'name': 'Satisfied', 'icon': Icons.sentiment_satisfied_outlined},
    {'name': 'Neutral', 'icon': Icons.sentiment_neutral_outlined},
    {'name': 'Sad', 'icon': Icons.sentiment_dissatisfied_outlined},
    {'name': 'Stressed', 'icon': Icons.sentiment_very_dissatisfied_outlined},
    {'name': 'Excited', 'icon': Icons.celebration_outlined},
    {'name': 'Bored', 'icon': Icons.mood_bad_outlined},
  ];

  // Budget periods
  static const List<String> budgetPeriods = [
    'Weekly',
    'Monthly',
  ];

  // Default budget alert threshold
  static const double defaultAlertThreshold = 80.0;

  // Debt status options
  static const Map<String, Color> debtStatusColors = {
    'pending': Colors.orange,
    'partially_paid': Colors.blue,
    'paid': Colors.green,
  };

  // Trust score levels
  static const Map<String, Map<String, dynamic>> trustScoreLevels = {
    'Low': {
      'range': [0, 30],
      'color': Colors.red,
      'description': 'Low trust level. Be cautious with lending.',
    },
    'Medium': {
      'range': [31, 70],
      'color': Colors.orange,
      'description': 'Medium trust level. Consider smaller loans.',
    },
    'High': {
      'range': [71, 100],
      'color': Colors.green,
      'description': 'High trust level. Reliable borrower.',
    },
  };

  // Karma points thresholds
  static const Map<String, Map<String, dynamic>> karmaLevels = {
    'Beginner': {
      'range': [0, 20],
      'color': Colors.grey,
      'description': 'New to the system.',
    },
    'Reliable': {
      'range': [21, 50],
      'color': Colors.blue,
      'description': 'Building a good reputation.',
    },
    'Trustworthy': {
      'range': [51, 100],
      'color': Colors.green,
      'description': 'Highly reliable with payments.',
    },
    'Elite': {
      'range': [101, double.infinity],
      'color': Colors.purple,
      'description': 'Exceptional payment history.',
    },
  };

  // Date formats
  static const String dateFormat = 'MMM d, yyyy';
  static const String timeFormat = 'h:mm a';
  static const String dateTimeFormat = 'MMM d, yyyy h:mm a';

  // Currency format
  static const String currencySymbol = '₹';

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
}
