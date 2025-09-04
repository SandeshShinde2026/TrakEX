import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import 'spending_habits_insights_service.dart';

class SmartBudgetAlertsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpendingHabitsInsightsService _insightsService = SpendingHabitsInsightsService();

  // Check if budget alert should be triggered with smart context
  Future<SmartBudgetAlert?> checkSmartBudgetAlert(
    String userId,
    String category,
    double newExpenseAmount,
  ) async {
    try {
      // Get current budget for the category
      final budget = await _getBudgetForCategory(userId, category);
      if (budget == null) return null;

      // Get current month spending
      final currentSpending = await _getCurrentMonthSpending(userId, category);
      final newTotal = currentSpending + newExpenseAmount;
      
      // Get spending context and insights
      final context = await _getSpendingContext(userId, category);
      
      // Calculate alert level and generate contextual message
      final alertLevel = _calculateAlertLevel(budget, currentSpending, newExpenseAmount);
      
      if (alertLevel == BudgetAlertLevel.none) return null;

      return SmartBudgetAlert(
        category: category,
        budgetAmount: budget.amount,
        currentSpending: currentSpending,
        newExpenseAmount: newExpenseAmount,
        projectedTotal: newTotal,
        alertLevel: alertLevel,
        contextualMessage: _generateContextualMessage(alertLevel, budget, context),
        recommendations: _generateSmartRecommendations(budget, context, alertLevel),
        daysLeftInMonth: _getDaysLeftInMonth(),
        spendingVelocity: _calculateSpendingVelocity(context.recentExpenses),
        projectedMonthEnd: _projectMonthEndSpending(context),
        alternatives: _suggestAlternatives(category, newExpenseAmount),
      );
    } catch (e) {
      print('Error checking smart budget alert: $e');
      return null;
    }
  }

  // Get all active budget alerts for user
  Future<List<SmartBudgetAlert>> getAllActiveAlerts(String userId) async {
    final alerts = <SmartBudgetAlert>[];
    
    try {
      final budgets = await _getUserBudgets(userId);
      
      for (var budget in budgets) {
        final alert = await checkSmartBudgetAlert(userId, budget.category, 0);
        if (alert != null && alert.alertLevel != BudgetAlertLevel.none) {
          alerts.add(alert);
        }
      }
      
      return alerts;
    } catch (e) {
      print('Error getting active alerts: $e');
      return [];
    }
  }

  // Machine learning-based alert level calculation
  BudgetAlertLevel _calculateAlertLevel(
    BudgetModel budget,
    double currentSpending,
    double newExpenseAmount,
  ) {
    final budgetAmount = budget.amount;
    final newTotal = currentSpending + newExpenseAmount;
    final usagePercentage = newTotal / budgetAmount;
    final daysLeft = _getDaysLeftInMonth();
    final totalDaysInMonth = DateTime.now().day + daysLeft;
    final daysPassed = DateTime.now().day;
    final expectedUsageByNow = daysPassed / totalDaysInMonth;

    // Smart threshold learning based on multiple factors
    if (usagePercentage >= 1.0) {
      return BudgetAlertLevel.critical; // Over budget
    } else if (usagePercentage >= 0.9) {
      return BudgetAlertLevel.warning; // 90% used
    } else if (usagePercentage >= 0.8) {
      return BudgetAlertLevel.caution; // 80% used
    } else if (usagePercentage > expectedUsageByNow * 1.5) {
      return BudgetAlertLevel.caution; // Spending too fast
    } else if (usagePercentage >= 0.5) {
      return BudgetAlertLevel.info; // Halfway point
    } else {
      return BudgetAlertLevel.none;
    }
  }

  // Generate contextual message based on spending patterns
  String _generateContextualMessage(
    BudgetAlertLevel level,
    BudgetModel budget,
    SpendingContext context,
  ) {
    final budgetAmount = budget.amount;
    final currentPercentage = (context.currentSpending / budgetAmount * 100).round();
    final daysLeft = _getDaysLeftInMonth();

    switch (level) {
      case BudgetAlertLevel.critical:
        if (context.isWeekend && context.weekendSpendingRatio > 0.6) {
          return '🚨 Budget exceeded! You tend to overspend on weekends. Consider postponing non-essential purchases.';
        } else if (context.spendingVelocity > context.averageVelocity * 2) {
          return '🚨 Budget exceeded! Your spending has doubled compared to usual. Time to pause and review.';
        } else {
          return '🚨 Budget exceeded by ₹${(context.currentSpending - budgetAmount).toInt()}! Immediate action needed.';
        }

      case BudgetAlertLevel.warning:
        if (daysLeft > 7) {
          return '⚠️ ${currentPercentage}% budget used with $daysLeft days left. You\'re spending faster than usual.';
        } else {
          return '⚠️ ${currentPercentage}% budget used. You might exceed your budget by month-end.';
        }

      case BudgetAlertLevel.caution:
        if (context.isPayday) {
          return '💡 ${currentPercentage}% budget used. Since it\'s payday, consider if this expense aligns with your priorities.';
        } else if (context.recentSimilarExpenses.length > 2) {
          return '💡 ${currentPercentage}% budget used. You\'ve made ${context.recentSimilarExpenses.length} similar purchases recently.';
        } else {
          return '💡 ${currentPercentage}% of ${budget.category} budget used. Keep an eye on upcoming expenses.';
        }

      case BudgetAlertLevel.info:
        return 'ℹ️ Halfway through your ${budget.category} budget (${currentPercentage}% used).';

      case BudgetAlertLevel.none:
        return '';
    }
  }

  // Generate smart recommendations based on context
  List<String> _generateSmartRecommendations(
    BudgetModel budget,
    SpendingContext context,
    BudgetAlertLevel level,
  ) {
    final recommendations = <String>[];

    // Context-aware recommendations
    if (level == BudgetAlertLevel.critical || level == BudgetAlertLevel.warning) {
      if (context.category == 'Food & Dining') {
        recommendations.addAll([
          '🍳 Cook meals at home for the rest of the month',
          '☕ Limit coffee shop visits to once per week',
          '🥗 Prep meals in advance to avoid impulse food purchases',
        ]);
      } else if (context.category == 'Transportation') {
        recommendations.addAll([
          '🚌 Use public transport instead of auto/taxi',
          '🚶 Walk or cycle for short distances',
          '🚗 Carpool with colleagues to save money',
        ]);
      } else if (context.category == 'Entertainment') {
        recommendations.addAll([
          '🏠 Host movie nights at home instead of cinema',
          '🌳 Explore free entertainment like parks and events',
          '📚 Use library resources for books and movies',
        ]);
      } else if (context.category == 'Shopping') {
        recommendations.addAll([
          '📝 Create a shopping list and stick to it',
          '⏰ Implement a 24-hour rule before purchases',
          '💰 Look for discounts and cashback offers',
        ]);
      }

      // General recommendations
      recommendations.addAll([
        '📊 Review your recent ${context.category} expenses',
        '🎯 Consider adjusting your budget for next month',
        '💡 Look for subscription services you can pause',
      ]);
    }

    // Behavioral recommendations
    if (context.impulseBuyingScore > 0.3) {
      recommendations.add('🧘 Practice mindful spending - ask "Do I really need this?"');
    }

    if (context.weekendSpendingRatio > 0.6 && context.isWeekend) {
      recommendations.add('📅 Set weekend spending limits to stay on track');
    }

    return recommendations.take(4).toList(); // Limit to 4 recommendations
  }

  // Suggest alternatives for the expense
  List<BudgetAlternative> _suggestAlternatives(String category, double amount) {
    final alternatives = <BudgetAlternative>[];

    if (category == 'Food & Dining') {
      if (amount > 300) {
        alternatives.addAll([
          BudgetAlternative(
            title: 'Cook at home',
            description: 'Make the same meal at home',
            potentialSavings: amount * 0.7,
            effort: 'Medium',
          ),
          BudgetAlternative(
            title: 'Order from local restaurant',
            description: 'Choose a more affordable local option',
            potentialSavings: amount * 0.4,
            effort: 'Low',
          ),
        ]);
      }
    } else if (category == 'Transportation') {
      alternatives.addAll([
        BudgetAlternative(
          title: 'Public transport',
          description: 'Use bus or metro instead',
          potentialSavings: amount * 0.6,
          effort: 'Low',
        ),
        BudgetAlternative(
          title: 'Shared ride',
          description: 'Share with others going same direction',
          potentialSavings: amount * 0.5,
          effort: 'Medium',
        ),
      ]);
    } else if (category == 'Entertainment') {
      alternatives.addAll([
        BudgetAlternative(
          title: 'Free alternative',
          description: 'Find free entertainment options',
          potentialSavings: amount,
          effort: 'Medium',
        ),
        BudgetAlternative(
          title: 'Home entertainment',
          description: 'Enjoy similar activities at home',
          potentialSavings: amount * 0.8,
          effort: 'Low',
        ),
      ]);
    }

    return alternatives;
  }

  // Calculate spending velocity (expenses per day)
  double _calculateSpendingVelocity(List<ExpenseModel> recentExpenses) {
    if (recentExpenses.isEmpty) return 0;

    final now = DateTime.now();
    final validExpenses = recentExpenses.where((e) {
      final daysDiff = now.difference(e.date).inDays;
      return daysDiff <= 7; // Last 7 days
    }).toList();

    if (validExpenses.isEmpty) return 0;

    final totalAmount = validExpenses.fold(0.0, (sum, e) => sum + e.amount);
    return totalAmount / 7; // Daily average
  }

  // Project month-end spending based on current velocity
  double _projectMonthEndSpending(SpendingContext context) {
    final daysLeft = _getDaysLeftInMonth();
    final currentVelocity = context.spendingVelocity;
    return context.currentSpending + (currentVelocity * daysLeft);
  }

  // Get comprehensive spending context
  Future<SpendingContext> _getSpendingContext(String userId, String category) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Get current month expenses for this category
    final query = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .orderBy('date', descending: true)
        .get();

    final expenses = query.docs
        .map((doc) => ExpenseModel.fromDocument(doc))
        .toList();

    final currentSpending = expenses.fold(0.0, (sum, e) => sum + e.amount);

    // Get user's general spending insights
    final insights = await _insightsService.generateInsights(userId);

    // Find recent similar expenses (same category, last 7 days)
    final recentSimilarExpenses = expenses.where((e) {
      return now.difference(e.date).inDays <= 7;
    }).toList();

    return SpendingContext(
      category: category,
      currentSpending: currentSpending,
      recentExpenses: expenses,
      recentSimilarExpenses: recentSimilarExpenses,
      isWeekend: now.weekday == 6 || now.weekday == 7,
      isPayday: _isPayday(now),
      weekendSpendingRatio: insights.timeBasedInsights.weekendSpendingRatio,
      impulseBuyingScore: insights.behavioralInsights.impulseBuyingScore,
      spendingVelocity: _calculateSpendingVelocity(expenses),
      averageVelocity: _calculateAverageVelocity(insights),
    );
  }

  // Helper methods
  Future<BudgetModel?> _getBudgetForCategory(String userId, String category) async {
    try {
      final query = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return BudgetModel.fromDocument(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  Future<List<BudgetModel>> _getUserBudgets(String userId) async {
    final query = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return query.docs.map((doc) => BudgetModel.fromDocument(doc)).toList();
  }

  Future<double> _getCurrentMonthSpending(String userId, String category) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final query = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    double sum = 0.0;
    for (var doc in query.docs) {
      final data = doc.data();
      sum += (data['amount'] as num).toDouble();
    }
    return sum;
  }

  int _getDaysLeftInMonth() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.day - now.day;
  }

  bool _isPayday(DateTime date) {
    // Assume payday is last day of month or 1st of next month
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    return date.day == lastDayOfMonth.day || date.day == 1;
  }

  double _calculateAverageVelocity(SpendingInsights insights) {
    // Calculate from monthly trends
    if (insights.timeBasedInsights.monthlyTrends.isEmpty) return 0;
    
    final monthlyAmounts = insights.timeBasedInsights.monthlyTrends.values;
    final avgMonthly = monthlyAmounts.reduce((a, b) => a + b) / monthlyAmounts.length;
    return avgMonthly / 30; // Daily average
  }
}

// Data classes
class SmartBudgetAlert {
  final String category;
  final double budgetAmount;
  final double currentSpending;
  final double newExpenseAmount;
  final double projectedTotal;
  final BudgetAlertLevel alertLevel;
  final String contextualMessage;
  final List<String> recommendations;
  final int daysLeftInMonth;
  final double spendingVelocity;
  final double projectedMonthEnd;
  final List<BudgetAlternative> alternatives;

  SmartBudgetAlert({
    required this.category,
    required this.budgetAmount,
    required this.currentSpending,
    required this.newExpenseAmount,
    required this.projectedTotal,
    required this.alertLevel,
    required this.contextualMessage,
    required this.recommendations,
    required this.daysLeftInMonth,
    required this.spendingVelocity,
    required this.projectedMonthEnd,
    required this.alternatives,
  });

  double get usagePercentage => (currentSpending / budgetAmount * 100);
  double get remainingBudget => budgetAmount - currentSpending;
  bool get isOverBudget => currentSpending > budgetAmount;
}

class SpendingContext {
  final String category;
  final double currentSpending;
  final List<ExpenseModel> recentExpenses;
  final List<ExpenseModel> recentSimilarExpenses;
  final bool isWeekend;
  final bool isPayday;
  final double weekendSpendingRatio;
  final double impulseBuyingScore;
  final double spendingVelocity;
  final double averageVelocity;

  SpendingContext({
    required this.category,
    required this.currentSpending,
    required this.recentExpenses,
    required this.recentSimilarExpenses,
    required this.isWeekend,
    required this.isPayday,
    required this.weekendSpendingRatio,
    required this.impulseBuyingScore,
    required this.spendingVelocity,
    required this.averageVelocity,
  });
}

class BudgetAlternative {
  final String title;
  final String description;
  final double potentialSavings;
  final String effort;

  BudgetAlternative({
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.effort,
  });
}

enum BudgetAlertLevel { none, info, caution, warning, critical }