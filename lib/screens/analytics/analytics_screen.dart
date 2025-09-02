import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';

// Data classes for charts
class ChartData {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

class WeeklySpendingData {
  final String week;
  final double amount;

  WeeklySpendingData({required this.week, required this.amount});
}

class SmartInsight {
  final String title;
  final String description;
  final String? recommendation;
  final IconData icon;
  final Color color;

  SmartInsight({
    required this.title,
    required this.description,
    this.recommendation,
    required this.icon,
    required this.color,
  });
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Date range for analytics
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _initDateRange();
    _loadData();
  }

  void _initDateRange() {
    // Set date range to current month by default
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      final userId = authProvider.userModel!.id;

      // Load expenses and budgets
      await expenseProvider.loadUserExpenses(userId);
      await budgetProvider.loadUserBudgets(userId);
    }
  }

  void _changeDateRange(String period) {
    final now = DateTime.now();

    setState(() {
      _selectedPeriod = period;

      switch (period) {
        case 'This Week':
          // Start from the beginning of the current week (Sunday)
          final weekday = now.weekday;
          _startDate = now.subtract(Duration(days: weekday));
          _endDate = _startDate.add(const Duration(days: 6));
          break;

        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;

        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;

        case 'Last 3 Months':
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;

        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    // Get spending data
    final totalSpending = expenseProvider.getTotalExpenses(_startDate, _endDate);
    final categorySpending = expenseProvider.getExpensesByCategory(_startDate, _endDate);
    final dailySpending = _getDailySpending(expenseProvider.expenses, _startDate, _endDate);

    // Loading state
    final isLoading = expenseProvider.isLoading || budgetProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Select Period',
            onSelected: _changeDateRange,
            itemBuilder: (context) => [
              'This Week',
              'This Month',
              'Last Month',
              'Last 3 Months',
              'This Year',
            ].map((period) => PopupMenuItem(
              value: period,
              child: Row(
                children: [
                  Icon(
                    _selectedPeriod == period ? Icons.check : Icons.calendar_today,
                    size: 16,
                    color: _selectedPeriod == period
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    period,
                    style: TextStyle(
                      fontWeight: _selectedPeriod == period
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedPeriod == period
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _buildAnalyticsContent(
                totalSpending,
                categorySpending,
                dailySpending,
              ),
      ),
    );
  }

  // New simplified analytics content
  Widget _buildAnalyticsContent(
    double totalSpending,
    Map<String, double> categorySpending,
    Map<DateTime, double> dailySpending,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.mediumSpacing,
        vertical: AppTheme.smallSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period and Total Summary Card
          _buildSummaryCard(totalSpending),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Quick Stats Row
          _buildQuickStatsRow(totalSpending, categorySpending, dailySpending),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Spending Trends Chart
          _buildSpendingTrendsCard(dailySpending),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Category Breakdown
          _buildCategoryBreakdownCard(categorySpending, totalSpending),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Recent Insights
          _buildInsightsCard(totalSpending, categorySpending, dailySpending),

          // Bottom padding for better scrolling
          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ),
    );
  }

  // Summary Card with period and total spending
  Widget _buildSummaryCard(double totalSpending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedPeriod,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Spending',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${AppConstants.currencySymbol}${totalSpending.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Stats Row
  Widget _buildQuickStatsRow(
    double totalSpending,
    Map<String, double> categorySpending,
    Map<DateTime, double> dailySpending,
  ) {
    // Calculate stats
    final avgDaily = dailySpending.isNotEmpty
        ? totalSpending / dailySpending.length
        : 0.0;

    final topCategory = categorySpending.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    final daysWithSpending = dailySpending.values.where((amount) => amount > 0).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Daily Average',
            '${AppConstants.currencySymbol}${avgDaily.toStringAsFixed(0)}',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
        const SizedBox(width: AppTheme.smallSpacing),
        Expanded(
          child: _buildStatCard(
            'Top Category',
            topCategory.length > 8 ? '${topCategory.substring(0, 8)}...' : topCategory,
            Icons.category,
            Colors.orange,
          ),
        ),
        const SizedBox(width: AppTheme.smallSpacing),
        Expanded(
          child: _buildStatCard(
            'Active Days',
            '$daysWithSpending',
            Icons.calendar_today,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }







  Map<DateTime, double> _getDailySpending(
    List<ExpenseModel> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    final Map<DateTime, double> result = {};

    // Initialize all days in the range with zero spending
    for (var day = startDate;
         day.isBefore(endDate.add(const Duration(days: 1)));
         day = day.add(const Duration(days: 1))) {
      final dateOnly = DateTime(day.year, day.month, day.day);
      result[dateOnly] = 0.0;
    }

    // Add up expenses for each day (excluding direct debt transactions)
    for (var expense in expenses) {
      if (!expense.isDirectDebt &&
          expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateOnly = DateTime(expense.date.year, expense.date.month, expense.date.day);
        result[dateOnly] = (result[dateOnly] ?? 0) + expense.amount;
      }
    }

    return result;
  }



  // Spending Trends Card
  Widget _buildSpendingTrendsCard(Map<DateTime, double> dailySpending) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Spending Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            SizedBox(
              width: double.infinity,
              height: 280, // Increased height to accommodate all elements
              child: dailySpending.isEmpty
                  ? const Center(
                      child: Text(
                        'No spending data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildSimpleBarChart(dailySpending),
            ),
          ],
        ),
      ),
    );
  }

  // Category Breakdown Card
  Widget _buildCategoryBreakdownCard(Map<String, double> categorySpending, double totalSpending) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            categorySpending.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.largeSpacing),
                    child: const Center(
                      child: Text(
                        'No category data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : _buildCategoryList(categorySpending, totalSpending),
          ],
        ),
      ),
    );
  }

  // Insights Card
  Widget _buildInsightsCard(
    double totalSpending,
    Map<String, double> categorySpending,
    Map<DateTime, double> dailySpending,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            _buildInsightsList(totalSpending, categorySpending, dailySpending),
          ],
        ),
      ),
    );
  }

  // Simple Bar Chart for Spending Trends
  Widget _buildSimpleBarChart(Map<DateTime, double> dailySpending) {
    final sortedEntries = dailySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxAmount = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minAmount = sortedEntries.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final avgAmount = sortedEntries.map((e) => e.value).reduce((a, b) => a + b) / sortedEntries.length;

    return Column(
      children: [
        // Chart Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Highest', maxAmount, Colors.red),
              _buildLegendItem('Average', avgAmount, Colors.orange),
              _buildLegendItem('Lowest', minAmount, Colors.green),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.mediumSpacing),

        // Enhanced Chart with proper sizing
        Container(
          height: 160,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: CustomPaint(
            size: const Size.fromHeight(136), // Fixed height to prevent overflow
            painter: SimpleBarChartPainter(
              data: sortedEntries,
              maxValue: maxAmount > 0 ? maxAmount * 1.1 : 100,
              avgValue: avgAmount,
              primaryColor: Theme.of(context).primaryColor,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),

        // Chart Summary
        const SizedBox(height: AppTheme.smallSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildChartSummary(sortedEntries, avgAmount),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${AppConstants.currencySymbol}${value.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSummary(List<MapEntry<DateTime, double>> sortedEntries, double avgAmount) {
    // Calculate trend
    final firstHalf = sortedEntries.take(sortedEntries.length ~/ 2).map((e) => e.value).toList();
    final secondHalf = sortedEntries.skip(sortedEntries.length ~/ 2).map((e) => e.value).toList();

    final firstAvg = firstHalf.isNotEmpty ? firstHalf.reduce((a, b) => a + b) / firstHalf.length : 0;
    final secondAvg = secondHalf.isNotEmpty ? secondHalf.reduce((a, b) => a + b) / secondHalf.length : 0;

    final trendPercentage = firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0;
    final isIncreasing = trendPercentage > 5;
    final isDecreasing = trendPercentage < -5;

    return Container(
      padding: const EdgeInsets.all(AppTheme.smallSpacing),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIncreasing
                ? Icons.trending_up
                : isDecreasing
                    ? Icons.trending_down
                    : Icons.trending_flat,
            color: isIncreasing
                ? Colors.red
                : isDecreasing
                    ? Colors.green
                    : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isIncreasing
                ? 'Spending increased by ${trendPercentage.abs().toStringAsFixed(1)}%'
                : isDecreasing
                    ? 'Spending decreased by ${trendPercentage.abs().toStringAsFixed(1)}%'
                    : 'Spending remained stable',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  // Category List
  Widget _buildCategoryList(Map<String, double> categorySpending, double totalSpending) {
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Define bright colors for categories
    final categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return Column(
      children: sortedCategories.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final categoryEntry = entry.value;
        final category = categoryEntry.key;
        final amount = categoryEntry.value;
        final percentage = totalSpending > 0 ? (amount / totalSpending) * 100 : 0;

        // Get color for this category
        final categoryColor = categoryColors[index % categoryColors.length];

        // Find category icon
        final categoryInfo = AppConstants.expenseCategories.firstWhere(
          (c) => c['name'] == category,
          orElse: () => {'name': category, 'icon': Icons.category},
        );

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryInfo['icon'] as IconData,
                  color: categoryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]
                            : Colors.grey[300],
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                categoryColor,
                                categoryColor.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Enhanced AI-Powered Insights List
  Widget _buildInsightsList(
    double totalSpending,
    Map<String, double> categorySpending,
    Map<DateTime, double> dailySpending,
  ) {
    final insights = _generateSmartInsights(totalSpending, categorySpending, dailySpending);

    return Column(
      children: insights.map((insight) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        decoration: BoxDecoration(
          color: insight.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          border: Border.all(
            color: insight.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: insight.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                insight.icon,
                color: insight.color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // Generate Top 3 Smart Insights
  List<SmartInsight> _generateSmartInsights(
    double totalSpending,
    Map<String, double> categorySpending,
    Map<DateTime, double> dailySpending,
  ) {
    final insights = <SmartInsight>[];

    if (totalSpending <= 0) {
      insights.add(SmartInsight(
        title: 'No Data',
        description: 'Start tracking expenses to get insights',
        icon: Icons.info_outline,
        color: Colors.grey,
      ));
      return insights;
    }

    final avgDaily = dailySpending.isNotEmpty ? totalSpending / dailySpending.length : 0;
    final spendingDays = dailySpending.values.where((amount) => amount > 0).length;
    final totalDays = dailySpending.length;

    // Priority 1: Spending Level Analysis
    if (avgDaily > 1000) {
      insights.add(SmartInsight(
        title: 'High Daily Spending',
        description: 'Daily average: ${AppConstants.currencySymbol}${avgDaily.toStringAsFixed(0)}',
        icon: Icons.trending_up,
        color: Colors.red,
      ));
    } else if (avgDaily < 200) {
      insights.add(SmartInsight(
        title: 'Great Control',
        description: 'Daily average: ${AppConstants.currencySymbol}${avgDaily.toStringAsFixed(0)}',
        icon: Icons.star,
        color: Colors.green,
      ));
    }

    // Priority 2: Category Concentration
    if (categorySpending.isNotEmpty) {
      final topCategory = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
      final topPercentage = (topCategory.value / totalSpending) * 100;

      if (topPercentage > 50) {
        insights.add(SmartInsight(
          title: 'Category Risk',
          description: '${topCategory.key}: ${topPercentage.toStringAsFixed(0)}% of spending',
          icon: Icons.pie_chart,
          color: Colors.orange,
        ));
      }
    }

    // Priority 3: Spending Frequency
    if (totalDays > 0) {
      final activePercentage = (spendingDays / totalDays) * 100;

      if (activePercentage > 80) {
        insights.add(SmartInsight(
          title: 'Frequent Spender',
          description: 'Expenses on ${activePercentage.toStringAsFixed(0)}% of days',
          icon: Icons.calendar_today,
          color: Colors.purple,
        ));
      } else if (activePercentage < 30) {
        insights.add(SmartInsight(
          title: 'Disciplined Spender',
          description: 'Expenses on only ${activePercentage.toStringAsFixed(0)}% of days',
          icon: Icons.savings,
          color: Colors.green,
        ));
      }
    }

    // Priority 4: Trend Analysis (if space available)
    if (insights.length < 3) {
      final sortedEntries = dailySpending.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      if (sortedEntries.length > 6) {
        final firstHalf = sortedEntries.take(sortedEntries.length ~/ 2).map((e) => e.value).toList();
        final secondHalf = sortedEntries.skip(sortedEntries.length ~/ 2).map((e) => e.value).toList();

        final firstAvg = firstHalf.isNotEmpty ? firstHalf.reduce((a, b) => a + b) / firstHalf.length : 0;
        final secondAvg = secondHalf.isNotEmpty ? secondHalf.reduce((a, b) => a + b) / secondHalf.length : 0;

        final trendPercentage = firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0;

        if (trendPercentage > 20) {
          insights.add(SmartInsight(
            title: 'Spending Up',
            description: 'Increased by ${trendPercentage.toStringAsFixed(0)}% recently',
            icon: Icons.trending_up,
            color: Colors.red,
          ));
        } else if (trendPercentage < -20) {
          insights.add(SmartInsight(
            title: 'Spending Down',
            description: 'Decreased by ${trendPercentage.abs().toStringAsFixed(0)}% recently',
            icon: Icons.trending_down,
            color: Colors.green,
          ));
        }
      }
    }

    // Return only top 3 insights
    return insights.take(3).toList();
  }


}

// Simple Bar Chart Painter
class SimpleBarChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, double>> data;
  final double maxValue;
  final double avgValue;
  final Color primaryColor;
  final bool isDarkMode;

  SimpleBarChartPainter({
    required this.data,
    required this.maxValue,
    required this.avgValue,
    required this.primaryColor,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Grid paint
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.grey).withValues(alpha: 0.15)
      ..strokeWidth = 1;

    // Average line paint
    final avgLinePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate bar dimensions
    final barWidth = size.width / data.length * 0.7; // 70% of available space
    final barSpacing = size.width / data.length * 0.3; // 30% for spacing

    // Define bright colors for bars
    final barColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final value = data[i].value;
      final normalizedHeight = maxValue > 0 ? (value / maxValue) * size.height : 0.0;

      final x = (i * size.width / data.length) + (barSpacing / 2);
      final y = size.height - normalizedHeight;

      // Create bar rectangle
      final barRect = Rect.fromLTWH(x, y, barWidth, normalizedHeight.toDouble());

      // Get color for this bar
      final barColor = barColors[i % barColors.length];

      // Draw bar with gradient
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          barColor,
          barColor.withValues(alpha: 0.7),
        ],
      );

      final gradientPaint = Paint()
        ..shader = gradient.createShader(barRect);

      // Bar border paint
      final barBorderPaint = Paint()
        ..color = barColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Draw bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        gradientPaint,
      );

      // Draw bar border
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        barBorderPaint,
      );
    }

    // Draw average line
    if (maxValue > 0) {
      final avgY = size.height - (avgValue / maxValue) * size.height;
      canvas.drawLine(Offset(0, avgY), Offset(size.width, avgY), avgLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}