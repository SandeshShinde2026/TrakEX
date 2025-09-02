import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../models/expense_model.dart';

class SmartInsightsWidget extends StatefulWidget {
  const SmartInsightsWidget({super.key});

  @override
  State<SmartInsightsWidget> createState() => _SmartInsightsWidgetState();
}

class _SmartInsightsWidgetState extends State<SmartInsightsWidget> {
  final PageController _pageController = PageController();
  int _currentInsightIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, BudgetProvider>(
      builder: (context, expenseProvider, budgetProvider, child) {
        final insights = _generateInsights(expenseProvider, budgetProvider);
        
        if (insights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (insights.length > 1)
                        Text(
                          '${_currentInsightIndex + 1}/${insights.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Insights carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentInsightIndex = index;
                      });
                    },
                    itemCount: insights.length,
                    itemBuilder: (context, index) {
                      return _buildInsightCard(insights[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
          duration: const Duration(milliseconds: 500),
        ).slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  Widget _buildInsightCard(SmartInsight insight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.mediumSpacing),
      child: Row(
        children: [
          // Insight icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.mediumSpacing),
          
          // Insight content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Action button
          if (insight.actionLabel != null)
            TextButton(
              onPressed: insight.onAction,
              style: TextButton.styleFrom(
                foregroundColor: insight.color,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                insight.actionLabel!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  List<SmartInsight> _generateInsights(
    ExpenseProvider expenseProvider,
    BudgetProvider budgetProvider,
  ) {
    final insights = <SmartInsight>[];
    final now = DateTime.now();
    final expenses = expenseProvider.expenses;

    // Weekend spending pattern
    final weekendExpenses = _getWeekendExpenses(expenses);
    final weekdayExpenses = _getWeekdayExpenses(expenses);
    if (weekendExpenses.isNotEmpty && weekdayExpenses.isNotEmpty) {
      final weekendAvg = weekendExpenses.fold<double>(0, (sum, e) => sum + e.amount) / weekendExpenses.length;
      final weekdayAvg = weekdayExpenses.fold<double>(0, (sum, e) => sum + e.amount) / weekdayExpenses.length;
      
      if (weekendAvg > weekdayAvg * 1.4) {
        insights.add(SmartInsight(
          title: 'Weekend Spending Alert',
          description: 'You spend ${((weekendAvg / weekdayAvg - 1) * 100).toInt()}% more on weekends',
          icon: Icons.weekend,
          color: AppTheme.warningColor,
          actionLabel: 'View Tips',
          onAction: () => _showSpendingTips(context),
        ));
      }
    }

    // Top spending category
    final categorySpending = _getCategorySpending(expenses);
    if (categorySpending.isNotEmpty) {
      final topCategory = categorySpending.entries.first;
      final totalSpending = categorySpending.values.fold<double>(0, (sum, amount) => sum + amount);
      final percentage = (topCategory.value / totalSpending * 100).toInt();
      
      if (percentage > 40) {
        insights.add(SmartInsight(
          title: 'Top Spending Category',
          description: '${topCategory.key} accounts for $percentage% of your expenses',
          icon: Icons.pie_chart,
          color: AppTheme.primaryColor,
          actionLabel: 'Analyze',
          onAction: () => _showCategoryAnalysis(context, topCategory.key),
        ));
      }
    }

    // Budget alerts
    final budgets = budgetProvider.budgets;
    final overBudgetCategories = budgets.where((b) => b.isOverBudget).toList();
    if (overBudgetCategories.isNotEmpty) {
      insights.add(SmartInsight(
        title: 'Budget Exceeded',
        description: '${overBudgetCategories.length} ${overBudgetCategories.length == 1 ? 'category has' : 'categories have'} exceeded budget',
        icon: Icons.warning,
        color: AppTheme.errorColor,
        actionLabel: 'Review',
        onAction: () => _showBudgetReview(context),
      ));
    }

    // Spending streak
    final consecutiveDays = _getConsecutiveSpendingDays(expenses);
    if (consecutiveDays >= 5) {
      insights.add(SmartInsight(
        title: 'Spending Streak',
        description: 'You\'ve spent money for $consecutiveDays consecutive days',
        icon: Icons.trending_up,
        color: AppTheme.warningColor,
        actionLabel: 'Take Break',
        onAction: () => _showSpendingBreakTips(context),
      ));
    }

    // Monthly comparison
    final thisMonthExpenses = _getThisMonthExpenses(expenses);
    final lastMonthExpenses = _getLastMonthExpenses(expenses);
    if (thisMonthExpenses.isNotEmpty && lastMonthExpenses.isNotEmpty) {
      final thisMonthTotal = thisMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final lastMonthTotal = lastMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      final change = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100);
      
      if (change.abs() > 20) {
        insights.add(SmartInsight(
          title: 'Monthly Comparison',
          description: 'Spending ${change > 0 ? 'increased' : 'decreased'} by ${change.abs().toInt()}% vs last month',
          icon: change > 0 ? Icons.trending_up : Icons.trending_down,
          color: change > 0 ? AppTheme.errorColor : AppTheme.successColor,
          actionLabel: 'Details',
          onAction: () => _showMonthlyComparison(context),
        ));
      }
    }

    // Savings opportunity
    final dailyAverage = _getDailyAverageSpending(expenses);
    if (dailyAverage > 0) {
      final potentialSavings = dailyAverage * 0.1 * 30; // 10% savings for a month
      insights.add(SmartInsight(
        title: 'Savings Opportunity',
        description: 'Save ${AppConstants.currencySymbol}${potentialSavings.toInt()} by reducing daily spending by 10%',
        icon: Icons.savings,
        color: AppTheme.successColor,
        actionLabel: 'Plan',
        onAction: () => _showSavingsPlan(context),
      ));
    }

    return insights;
  }

  // Helper methods for calculations
  List<ExpenseModel> _getWeekendExpenses(List<ExpenseModel> expenses) {
    return expenses.where((e) => e.date.weekday >= 6).toList();
  }

  List<ExpenseModel> _getWeekdayExpenses(List<ExpenseModel> expenses) {
    return expenses.where((e) => e.date.weekday < 6).toList();
  }

  Map<String, double> _getCategorySpending(List<ExpenseModel> expenses) {
    final categorySpending = <String, double>{};
    for (final expense in expenses) {
      categorySpending[expense.category] = 
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }
    return Map.fromEntries(
      categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  int _getConsecutiveSpendingDays(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return 0;
    
    final sortedExpenses = expenses.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int consecutiveDays = 0;
    DateTime? lastDate;
    
    for (final expense in sortedExpenses) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (lastDate == null) {
        lastDate = expenseDate;
        consecutiveDays = 1;
      } else {
        final difference = lastDate.difference(expenseDate).inDays;
        if (difference == 1) {
          consecutiveDays++;
          lastDate = expenseDate;
        } else {
          break;
        }
      }
    }
    
    return consecutiveDays;
  }

  List<ExpenseModel> _getThisMonthExpenses(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    return expenses.where((e) => 
      e.date.year == now.year && e.date.month == now.month
    ).toList();
  }

  List<ExpenseModel> _getLastMonthExpenses(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return expenses.where((e) => 
      e.date.year == lastMonth.year && e.date.month == lastMonth.month
    ).toList();
  }

  double _getDailyAverageSpending(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return 0;
    
    final totalSpending = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final daysDifference = DateTime.now().difference(expenses.last.date).inDays + 1;
    return totalSpending / daysDifference;
  }

  // Action methods
  void _showSpendingTips(BuildContext context) {
    // Implementation for showing spending tips
  }

  void _showCategoryAnalysis(BuildContext context, String category) {
    // Implementation for showing category analysis
  }

  void _showBudgetReview(BuildContext context) {
    // Implementation for showing budget review
  }

  void _showSpendingBreakTips(BuildContext context) {
    // Implementation for showing spending break tips
  }

  void _showMonthlyComparison(BuildContext context) {
    // Implementation for showing monthly comparison
  }

  void _showSavingsPlan(BuildContext context) {
    // Implementation for showing savings plan
  }
}

class SmartInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SmartInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onAction,
  });
}
