import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class SpendingHabitsInsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate comprehensive spending insights
  Future<SpendingInsights> generateInsights(String userId) async {
    try {
      // Get last 3 months of expenses for better analysis
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      
      final query = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo))
          .orderBy('date', descending: false)
          .get();

      final expenses = query.docs.map((doc) => ExpenseData.fromFirestore(doc)).toList();

      if (expenses.isEmpty) {
        return SpendingInsights.empty();
      }

      return SpendingInsights(
        timeBasedInsights: _analyzeTimeBasedPatterns(expenses),
        categoryInsights: _analyzeCategoryPatterns(expenses),
        behavioralInsights: _analyzeBehavioralPatterns(expenses),
        financialHealthScore: _calculateFinancialHealthScore(expenses),
        predictions: _generatePredictions(expenses),
        recommendations: _generateRecommendations(expenses),
      );
    } catch (e) {
      print('Error generating insights: $e');
      return SpendingInsights.empty();
    }
  }

  // Time-based pattern analysis
  TimeBasedInsights _analyzeTimeBasedPatterns(List<ExpenseData> expenses) {
    final weekdaySpending = <int, double>{};
    final hourlySpending = <int, double>{};
    final monthlyTrends = <String, double>{};
    
    for (var expense in expenses) {
      final date = expense.date;
      final weekday = date.weekday;
      final hour = date.hour;
      final monthKey = DateFormat('MMM yyyy').format(date);
      
      // Weekday analysis
      weekdaySpending[weekday] = (weekdaySpending[weekday] ?? 0) + expense.amount;
      
      // Hourly analysis
      hourlySpending[hour] = (hourlySpending[hour] ?? 0) + expense.amount;
      
      // Monthly trends
      monthlyTrends[monthKey] = (monthlyTrends[monthKey] ?? 0) + expense.amount;
    }

    // Find peak spending day and time
    final peakSpendingDay = weekdaySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final peakSpendingHour = hourlySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    // Calculate weekend vs weekday ratio
    final weekendSpending = (weekdaySpending[6] ?? 0) + (weekdaySpending[7] ?? 0);
    final weekdaySpendingTotal = weekdaySpending.entries
        .where((e) => e.key >= 1 && e.key <= 5)
        .fold(0.0, (sum, e) => sum + e.value);
    
    final weekendRatio = weekendSpending / (weekendSpending + weekdaySpendingTotal);

    return TimeBasedInsights(
      peakSpendingDay: _getDayName(peakSpendingDay.key),
      peakSpendingHour: peakSpendingHour.key,
      weekendSpendingRatio: weekendRatio,
      monthlyTrends: monthlyTrends,
      insights: _generateTimeInsights(weekendRatio, peakSpendingDay.key, peakSpendingHour.key),
    );
  }

  // Category-based pattern analysis
  CategoryInsights _analyzeCategoryPatterns(List<ExpenseData> expenses) {
    final categorySpending = <String, CategoryData>{};
    
    for (var expense in expenses) {
      if (!categorySpending.containsKey(expense.category)) {
        categorySpending[expense.category] = CategoryData(
          category: expense.category,
          totalAmount: 0,
          frequency: 0,
          averageAmount: 0,
          trend: SpendingTrend.stable,
        );
      }
      
      categorySpending[expense.category]!.totalAmount += expense.amount;
      categorySpending[expense.category]!.frequency += 1;
    }

    // Calculate averages and trends
    for (var data in categorySpending.values) {
      data.averageAmount = data.totalAmount / data.frequency;
      data.trend = _calculateCategoryTrend(expenses, data.category);
    }

    // Sort by spending amount
    final sortedCategories = categorySpending.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return CategoryInsights(
      topCategories: sortedCategories.take(5).toList(),
      categoryDistribution: categorySpending,
      insights: _generateCategoryInsights(sortedCategories),
    );
  }

  // Behavioral pattern analysis
  BehavioralInsights _analyzeBehavioralPatterns(List<ExpenseData> expenses) {
    final moodSpending = <String?, double>{};
    final impulseBuying = _detectImpulseBuying(expenses);
    final routineExpenses = _identifyRoutineExpenses(expenses);
    
    for (var expense in expenses) {
      moodSpending[expense.mood] = (moodSpending[expense.mood] ?? 0) + expense.amount;
    }

    return BehavioralInsights(
      moodSpendingPatterns: moodSpending,
      impulseBuyingScore: impulseBuying,
      routineExpensePercentage: routineExpenses,
      insights: _generateBehavioralInsights(moodSpending, impulseBuying),
    );
  }

  // Calculate financial health score (0-100)
  double _calculateFinancialHealthScore(List<ExpenseData> expenses) {
    if (expenses.isEmpty) return 50.0;

    double score = 100.0;
    
    // Factor 1: Spending consistency (lower variance = better)
    final amounts = expenses.map((e) => e.amount).toList();
    final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance = amounts.map((x) => (x - avgAmount) * (x - avgAmount)).reduce((a, b) => a + b) / amounts.length;
    final consistency = 1 / (1 + variance / (avgAmount * avgAmount));
    score *= consistency;

    // Factor 2: Category diversification
    final categories = expenses.map((e) => e.category).toSet().length;
    final diversification = (categories / 10).clamp(0.5, 1.0); // Normalize to 0.5-1.0
    score *= diversification;

    // Factor 3: Impulse buying penalty
    final impulseBuying = _detectImpulseBuying(expenses);
    score *= (1 - impulseBuying);

    return score.clamp(0.0, 100.0);
  }

  // Generate spending predictions
  List<SpendingPrediction> _generatePredictions(List<ExpenseData> expenses) {
    final predictions = <SpendingPrediction>[];
    
    // Predict next month spending by category
    final categorySpending = <String, List<double>>{};
    final now = DateTime.now();
    
    for (var expense in expenses) {
      final monthsAgo = now.difference(expense.date).inDays ~/ 30;
      if (monthsAgo < 3) {
        categorySpending.putIfAbsent(expense.category, () => []);
        categorySpending[expense.category]!.add(expense.amount);
      }
    }

    for (var entry in categorySpending.entries) {
      final amounts = entry.value;
      final avgMonthly = amounts.reduce((a, b) => a + b) / 3; // 3 months average
      
      predictions.add(SpendingPrediction(
        category: entry.key,
        predictedAmount: avgMonthly,
        confidence: _calculatePredictionConfidence(amounts),
        timeframe: 'Next Month',
      ));
    }

    return predictions;
  }

  // Generate personalized recommendations
  List<String> _generateRecommendations(List<ExpenseData> expenses) {
    final recommendations = <String>[];
    
    // Analyze spending patterns for recommendations
    final categorySpending = <String, double>{};
    final totalSpending = expenses.fold(0.0, (sum, e) => sum + e.amount);
    
    for (var expense in expenses) {
      categorySpending[expense.category] = (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Food & Dining recommendations
    final foodSpending = categorySpending['Food & Dining'] ?? 0;
    if (foodSpending > totalSpending * 0.4) {
      recommendations.add('🍽️ Consider cooking at home more often. Your food expenses are ${((foodSpending/totalSpending)*100).toInt()}% of total spending.');
    }

    // Transportation recommendations
    final transportSpending = categorySpending['Transportation'] ?? 0;
    if (transportSpending > totalSpending * 0.25) {
      recommendations.add('🚌 Try using public transport or carpooling to reduce transportation costs.');
    }

    // Shopping recommendations
    final shoppingSpending = categorySpending['Shopping'] ?? 0;
    if (shoppingSpending > totalSpending * 0.2) {
      recommendations.add('🛍️ Create a shopping list and stick to it to avoid impulse purchases.');
    }

    // Entertainment recommendations
    final entertainmentSpending = categorySpending['Entertainment'] ?? 0;
    if (entertainmentSpending > totalSpending * 0.15) {
      recommendations.add('🎬 Look for free entertainment options like parks, museums, or community events.');
    }

    // General recommendations
    if (recommendations.isEmpty) {
      recommendations.add('✨ Great job! Your spending seems well-balanced across categories.');
    }

    return recommendations;
  }

  // Helper methods
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  List<String> _generateTimeInsights(double weekendRatio, int peakDay, int peakHour) {
    final insights = <String>[];
    
    if (weekendRatio > 0.6) {
      insights.add('You tend to spend 60% more on weekends. Consider setting weekend budgets.');
    } else if (weekendRatio < 0.3) {
      insights.add('You\'re disciplined with weekend spending! Keep it up.');
    }

    insights.add('Your peak spending time is ${_getDayName(peakDay)} at ${peakHour}:00');
    
    if (peakHour >= 12 && peakHour <= 14) {
      insights.add('Most expenses occur during lunch hours. Pack lunch to save money.');
    }

    return insights;
  }

  List<String> _generateCategoryInsights(List<CategoryData> categories) {
    final insights = <String>[];
    
    if (categories.isNotEmpty) {
      final topCategory = categories.first;
      insights.add('Your biggest expense category is ${topCategory.category} (₹${topCategory.totalAmount.toInt()})');
      
      final trendingUp = categories.where((c) => c.trend == SpendingTrend.increasing).length;
      if (trendingUp > 0) {
        insights.add('$trendingUp categories are trending upward this month');
      }
    }

    return insights;
  }

  List<String> _generateBehavioralInsights(Map<String?, double> moodSpending, double impulseBuying) {
    final insights = <String>[];
    
    if (moodSpending.isNotEmpty) {
      final sortedMoods = moodSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (sortedMoods.first.key != null) {
        insights.add('You spend most when feeling "${sortedMoods.first.key}"');
      }
    }

    if (impulseBuying > 0.3) {
      insights.add('High impulse buying detected. Try the 24-hour rule before purchases.');
    }

    return insights;
  }

  double _detectImpulseBuying(List<ExpenseData> expenses) {
    // Detect expenses added within short time intervals
    expenses.sort((a, b) => a.date.compareTo(b.date));
    
    int impulseCount = 0;
    for (int i = 1; i < expenses.length; i++) {
      final timeDiff = expenses[i].date.difference(expenses[i-1].date);
      if (timeDiff.inMinutes < 30 && expenses[i].category == 'Shopping') {
        impulseCount++;
      }
    }

    return impulseCount / expenses.length;
  }

  double _identifyRoutineExpenses(List<ExpenseData> expenses) {
    final routineCategories = {'Transportation', 'Food & Dining', 'Utilities'};
    final routineExpenses = expenses.where((e) => routineCategories.contains(e.category)).length;
    return routineExpenses / expenses.length;
  }

  SpendingTrend _calculateCategoryTrend(List<ExpenseData> expenses, String category) {
    final categoryExpenses = expenses.where((e) => e.category == category).toList();
    if (categoryExpenses.length < 2) return SpendingTrend.stable;

    // Split into two halves and compare
    final midPoint = categoryExpenses.length ~/ 2;
    final firstHalf = categoryExpenses.take(midPoint);
    final secondHalf = categoryExpenses.skip(midPoint);

    final firstAvg = firstHalf.fold(0.0, (sum, e) => sum + e.amount) / firstHalf.length;
    final secondAvg = secondHalf.fold(0.0, (sum, e) => sum + e.amount) / secondHalf.length;

    if (secondAvg > firstAvg * 1.2) return SpendingTrend.increasing;
    if (secondAvg < firstAvg * 0.8) return SpendingTrend.decreasing;
    return SpendingTrend.stable;
  }

  double _calculatePredictionConfidence(List<double> amounts) {
    if (amounts.length < 2) return 0.5;
    
    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance = amounts.map((x) => (x - avg) * (x - avg)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = variance.sqrt();
    
    // Lower standard deviation = higher confidence
    return (1 / (1 + stdDev / avg)).clamp(0.1, 0.9);
  }
}

// Data classes
class SpendingInsights {
  final TimeBasedInsights timeBasedInsights;
  final CategoryInsights categoryInsights;
  final BehavioralInsights behavioralInsights;
  final double financialHealthScore;
  final List<SpendingPrediction> predictions;
  final List<String> recommendations;

  SpendingInsights({
    required this.timeBasedInsights,
    required this.categoryInsights,
    required this.behavioralInsights,
    required this.financialHealthScore,
    required this.predictions,
    required this.recommendations,
  });

  factory SpendingInsights.empty() {
    return SpendingInsights(
      timeBasedInsights: TimeBasedInsights.empty(),
      categoryInsights: CategoryInsights.empty(),
      behavioralInsights: BehavioralInsights.empty(),
      financialHealthScore: 50.0,
      predictions: [],
      recommendations: ['Add more expenses to get personalized insights'],
    );
  }
}

class TimeBasedInsights {
  final String peakSpendingDay;
  final int peakSpendingHour;
  final double weekendSpendingRatio;
  final Map<String, double> monthlyTrends;
  final List<String> insights;

  TimeBasedInsights({
    required this.peakSpendingDay,
    required this.peakSpendingHour,
    required this.weekendSpendingRatio,
    required this.monthlyTrends,
    required this.insights,
  });

  factory TimeBasedInsights.empty() {
    return TimeBasedInsights(
      peakSpendingDay: '',
      peakSpendingHour: 0,
      weekendSpendingRatio: 0.0,
      monthlyTrends: {},
      insights: [],
    );
  }
}

class CategoryInsights {
  final List<CategoryData> topCategories;
  final Map<String, CategoryData> categoryDistribution;
  final List<String> insights;

  CategoryInsights({
    required this.topCategories,
    required this.categoryDistribution,
    required this.insights,
  });

  factory CategoryInsights.empty() {
    return CategoryInsights(
      topCategories: [],
      categoryDistribution: {},
      insights: [],
    );
  }
}

class BehavioralInsights {
  final Map<String?, double> moodSpendingPatterns;
  final double impulseBuyingScore;
  final double routineExpensePercentage;
  final List<String> insights;

  BehavioralInsights({
    required this.moodSpendingPatterns,
    required this.impulseBuyingScore,
    required this.routineExpensePercentage,
    required this.insights,
  });

  factory BehavioralInsights.empty() {
    return BehavioralInsights(
      moodSpendingPatterns: {},
      impulseBuyingScore: 0.0,
      routineExpensePercentage: 0.0,
      insights: [],
    );
  }
}

class CategoryData {
  final String category;
  double totalAmount;
  int frequency;
  double averageAmount;
  SpendingTrend trend;

  CategoryData({
    required this.category,
    required this.totalAmount,
    required this.frequency,
    required this.averageAmount,
    required this.trend,
  });
}

class SpendingPrediction {
  final String category;
  final double predictedAmount;
  final double confidence;
  final String timeframe;

  SpendingPrediction({
    required this.category,
    required this.predictedAmount,
    required this.confidence,
    required this.timeframe,
  });
}

class ExpenseData {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String? mood;

  ExpenseData({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.mood,
  });

  factory ExpenseData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseData(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] as String?,
    );
  }
}

enum SpendingTrend { increasing, decreasing, stable }

extension on double {
  double sqrt() => math.sqrt(this);
}