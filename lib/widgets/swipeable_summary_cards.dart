import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/debt_provider.dart';
import '../models/expense_model.dart';

class SwipeableSummaryCards extends StatefulWidget {
  const SwipeableSummaryCards({super.key});

  @override
  State<SwipeableSummaryCards> createState() => _SwipeableSummaryCardsState();
}

class _SwipeableSummaryCardsState extends State<SwipeableSummaryCards> {
  final PageController _pageController = PageController();
  int _currentIndex = 0; // Start with daily view

  final List<String> _periods = ['Daily', 'Weekly', 'Monthly'];
  final List<IconData> _periodIcons = [
    Icons.today,
    Icons.view_week,
    Icons.calendar_month,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Period indicators
        _buildPeriodIndicators(),
        const SizedBox(height: AppTheme.smallSpacing),

        // Swipeable cards
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _periods.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildSummaryCard(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodIndicators() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_periods.length, (index) {
        final isActive = index == _currentIndex;

        // Define colors based on theme and active state
        Color backgroundColor;
        Color textColor;
        Color iconColor;
        Color borderColor;

        if (isActive) {
          // Active state: bright/white background in dark mode, primary color in light mode
          backgroundColor = isDarkMode ? Colors.white : Theme.of(context).primaryColor;
          textColor = isDarkMode ? Colors.black87 : Colors.white;
          iconColor = isDarkMode ? Colors.black87 : Colors.white;
          borderColor = isDarkMode ? Colors.white : Theme.of(context).primaryColor;
        } else {
          // Inactive state: transparent background with appropriate border
          backgroundColor = Colors.transparent;
          textColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;
          iconColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;
          borderColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300;
        }

        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _periodIcons[index],
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _periods[index],
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ).animate().scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }),
    );
  }

  Widget _buildSummaryCard(int periodIndex) {
    return Consumer3<ExpenseProvider, BudgetProvider, DebtProvider>(
      builder: (context, expenseProvider, budgetProvider, debtProvider, child) {
        final summaryData = _calculateSummaryData(
          periodIndex,
          expenseProvider,
          budgetProvider,
          debtProvider
        );

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
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
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_periods[periodIndex]} Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _periodIcons[periodIndex],
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.mediumSpacing),

                // Summary stats
                Expanded(
                  child: Row(
                    children: [
                      // Expenses
                      Expanded(
                        child: _buildStatItem(
                          'Expenses',
                          '${AppConstants.currencySymbol}${summaryData['totalExpenses']?.toStringAsFixed(0) ?? '0'}',
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ),

                      // Budget remaining
                      Expanded(
                        child: _buildStatItem(
                          'Budget Left',
                          '${AppConstants.currencySymbol}${summaryData['budgetRemaining']?.toStringAsFixed(0) ?? '0'}',
                          Icons.account_balance_wallet,
                          (summaryData['budgetRemaining'] ?? 0.0) >= 0 ? Colors.green : Colors.red,
                        ),
                      ),

                      // Debts
                      Expanded(
                        child: _buildStatItem(
                          'Net Debt',
                          '${AppConstants.currencySymbol}${summaryData['netDebt']?.toStringAsFixed(0) ?? '0'}',
                          Icons.handshake,
                          (summaryData['netDebt'] ?? 0.0) >= 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Period info
                Text(
                  summaryData['periodInfo'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ).animate().slideX(
          begin: periodIndex > _currentIndex ? 1 : -1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateSummaryData(
    int periodIndex,
    ExpenseProvider expenseProvider,
    BudgetProvider budgetProvider,
    DebtProvider debtProvider,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    String periodInfo;

    switch (periodIndex) {
      case 0: // Daily
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        periodInfo = DateFormat('EEEE, MMM d').format(now);
        break;
      case 1: // Weekly
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        periodInfo = 'Week of ${DateFormat('MMM d').format(startDate)}';
        break;
      case 2: // Monthly
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        periodInfo = DateFormat('MMMM yyyy').format(now);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        periodInfo = DateFormat('EEEE, MMM d').format(now);
    }

    // Calculate expenses for the period
    final expenses = expenseProvider.expenses.where((expense) {
      return expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(endDate);
    }).toList();

    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    // Calculate budget remaining based on period
    double totalBudget = 0.0;
    if (budgetProvider.hasTotalBudget() && budgetProvider.totalBudget != null) {
      final monthlyBudget = budgetProvider.totalBudget!.amount;

      switch (periodIndex) {
        case 0: // Daily
          totalBudget = monthlyBudget / 30; // Approximate daily budget
          break;
        case 1: // Weekly
          totalBudget = monthlyBudget / 4; // Approximate weekly budget
          break;
        case 2: // Monthly
          totalBudget = monthlyBudget;
          break;
      }
    }
    final budgetRemaining = totalBudget - totalExpenses;

    // Calculate net debt
    final totalOwed = debtProvider.lentDebts.fold<double>(
      0.0,
      (sum, debt) => sum + debt.amount,
    );
    final totalBorrowed = debtProvider.borrowedDebts.fold<double>(
      0.0,
      (sum, debt) => sum + debt.amount,
    );
    final netDebt = totalBorrowed - totalOwed;

    return {
      'totalExpenses': totalExpenses,
      'budgetRemaining': budgetRemaining,
      'netDebt': netDebt,
      'periodInfo': periodInfo,
    };
  }
}
