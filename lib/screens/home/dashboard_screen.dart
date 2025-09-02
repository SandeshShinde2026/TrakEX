import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/currency_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/budget_status_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/recent_transaction_card.dart';
import '../../widgets/simple_calculator.dart';
import '../../widgets/banner_ad_widget.dart';


import '../../widgets/quick_action_drawer.dart';
import '../../providers/ad_provider.dart';
import '../../services/smart_notifications_service.dart';
import '../budgets/set_total_budget_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../analytics/analytics_screen.dart';
import 'add_friend_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Date range for summary data (default to current month)
  late DateTime _startDate;
  late DateTime _endDate;

  // State for calculator visibility
  bool _showCalculator = false;

  @override
  void initState() {
    super.initState();
    _initDateRange();
    _loadData();
  }

  void _initDateRange() {
    // Set date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      final userId = authProvider.userModel!.id;

      // Initialize currency provider with user ID
      await currencyProvider.initialize(userId: userId);

      // Debug exchange rates (remove in production)
      await currencyProvider.debugExchangeRates();

      // Load expenses, budgets, and debts
      await expenseProvider.loadUserExpenses(userId);
      await budgetProvider.loadUserBudgets(userId);
      await debtProvider.loadLentDebts(userId);
      await debtProvider.loadBorrowedDebts(userId);

      // Initialize ads
      adProvider.initializeAds().catchError((error) {
        debugPrint('Error initializing ads: $error');
      });

      // Initialize smart notifications
      _initializeSmartNotifications();
    }
  }

  void _navigateToAddExpense() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddExpenseScreen(),
        ),
      );

      // Show interstitial ad after expense is added
      if (result == true) {
        adProvider.onExpenseAdded();
      }
    }
  }



  void _navigateToSetBudget() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetTotalBudgetScreen(
            existingBudget: budgetProvider.totalBudget,
          ),
        ),
      );
    }
  }

  void _navigateToExpenseDetail(ExpenseModel expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }

  void _toggleCalculator() {
    setState(() {
      _showCalculator = !_showCalculator;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final debtProvider = Provider.of<DebtProvider>(context);

    final user = authProvider.userModel;

    // Calculate summary data
    final totalBudget = budgetProvider.getActualTotalBudgetAmount();

    // Use the spent amount from the total budget model if available
    // If not available, calculate from expenses
    double totalExpenses;
    if (budgetProvider.hasTotalBudget() && budgetProvider.totalBudget != null) {
      totalExpenses = budgetProvider.totalBudget!.spent;
      debugPrint('Dashboard: Using total budget spent amount: $totalExpenses');
    } else {
      totalExpenses = expenseProvider.getTotalExpenses(_startDate, _endDate);
      debugPrint('Dashboard: Calculated total expenses from expense provider: $totalExpenses');
    }

    // Only calculate budget remaining if a budget is set
    final budgetRemaining = budgetProvider.hasTotalBudget() ? totalBudget - totalExpenses : 0.0;

    // Direct debts (borrowing/lending between friends)
    final directYouOwe = debtProvider.getTotalDirectBorrowed();
    final directOwedToYou = debtProvider.getTotalDirectLent();
    final directNetBalance = debtProvider.getDirectDebtNetBalance();

    // Group expenses
    final groupYouOwe = debtProvider.getTotalGroupExpenseBorrowed();
    final groupOwedToYou = debtProvider.getTotalGroupExpenseLent();
    final groupNetBalance = debtProvider.getGroupExpenseNetBalance();

    // We're now using directYouOwe and directOwedToYou instead
    // These lines are kept for reference but commented out
    // final youOwe = debtProvider.getTotalBorrowed();
    // final owedToYou = debtProvider.getTotalLent();

    // Get recent expenses (top 5)
    final recentExpenses = expenseProvider.expenses.take(5).toList();

    // Get budget status
    final budgets = budgetProvider.budgets;

    // Loading state
    final isLoading = authProvider.isLoading ||
                      expenseProvider.isLoading ||
                      budgetProvider.isLoading ||
                      debtProvider.isLoading;

    return Scaffold(
      body: StickyBannerAdWidget(
        adLocation: 'dashboard',
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveValue<double>(
                  context: context,
                  mobile: AppTheme.mediumSpacing,
                  tablet: AppTheme.mediumSpacing * 1.2,
                  desktop: AppTheme.mediumSpacing * 1.5,
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message and date range
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${_getFirstName(user.name)}!',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    baseFontSize: 24,
                                    tabletFactor: 1.2,
                                    desktopFactor: 1.5,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_startDate),
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    baseFontSize: 14,
                                    tabletFactor: 1.1,
                                    desktopFactor: 1.2,
                                  ),
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLoading)
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: 20,
                              tablet: 24,
                              desktop: 28,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: ResponsiveHelper.getResponsiveValue<double>(
                                context: context,
                                mobile: 2,
                                tablet: 2.5,
                                desktop: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Quick Actions - Simplified
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title for Quick Actions
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          // Quick Action Buttons - Properly Spaced
                          Row(
                            children: [
                              Expanded(
                                child: QuickActionButton(
                                  icon: Icons.add_circle_outline,
                                  label: 'Add Expense',
                                  color: AppTheme.primaryColor,
                                  onTap: _navigateToAddExpense,
                                  fontSize: 14,
                                  iconSize: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.smallSpacing),
                              Expanded(
                                child: QuickActionButton(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Set Budget',
                                  color: AppTheme.successColor,
                                  onTap: _navigateToSetBudget,
                                  fontSize: 14,
                                  iconSize: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.smallSpacing),
                              Expanded(
                                child: QuickActionButton(
                                  icon: Icons.more_horiz,
                                  label: 'More Actions',
                                  color: AppTheme.warningColor,
                                  onTap: _showQuickActionDrawer,
                                  fontSize: 14,
                                  iconSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Calculator (collapsible)
                    if (_showCalculator) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Calculator',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _toggleCalculator,
                                    tooltip: 'Close Calculator',
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 350,
                              margin: const EdgeInsets.all(8),
                              child: const SimpleCalculator(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                    ],

                    // Summary Card - Simplified
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Summary',
                              style: AppTheme.headingStyle,
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            const Divider(),
                            const SizedBox(height: AppTheme.smallSpacing),
                            _buildSummaryItem(
                              context,
                              'Total Expenses',
                              '${AppConstants.currencySymbol}${totalExpenses.toStringAsFixed(2)}',
                              Icons.trending_down,
                              Colors.red,
                            ),
                            if (budgetProvider.hasTotalBudget()) ...[
                              SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                                context: context,
                                mobile: AppTheme.smallSpacing,
                                tablet: AppTheme.smallSpacing * 1.2,
                                desktop: AppTheme.smallSpacing * 1.5,
                              )),
                              _buildSummaryItem(
                                context,
                                'Budget Remaining',
                                '${AppConstants.currencySymbol}${budgetRemaining.toStringAsFixed(2)}',
                                Icons.account_balance_wallet,
                                budgetRemaining >= 0 ? Colors.green : Colors.red,
                              ),
                            ],
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing,
                              tablet: AppTheme.smallSpacing * 1.2,
                              desktop: AppTheme.smallSpacing * 1.5,
                            )),
                            // Add divider above Direct Debts section
                            Divider(
                              thickness: ResponsiveHelper.getResponsiveValue<double>(
                                context: context,
                                mobile: 1,
                                tablet: 1.5,
                                desktop: 2,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing,
                              tablet: AppTheme.smallSpacing * 1.2,
                              desktop: AppTheme.smallSpacing * 1.5,
                            )),
                            // Direct Debts Section
                            _buildSectionHeader(context, 'Direct Debts'),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing * 0.5,
                              tablet: AppTheme.smallSpacing * 0.6,
                              desktop: AppTheme.smallSpacing * 0.7,
                            )),
                            _buildSummaryItem(
                              context,
                              'You Owe (Direct)',
                              '${AppConstants.currencySymbol}${directYouOwe.toStringAsFixed(2)}',
                              Icons.arrow_upward,
                              Colors.orange,
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing * 0.5,
                              tablet: AppTheme.smallSpacing * 0.6,
                              desktop: AppTheme.smallSpacing * 0.7,
                            )),
                            _buildSummaryItem(
                              context,
                              'Owed to You (Direct)',
                              '${AppConstants.currencySymbol}${directOwedToYou.toStringAsFixed(2)}',
                              Icons.arrow_downward,
                              Colors.blue,
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing * 0.5,
                              tablet: AppTheme.smallSpacing * 0.6,
                              desktop: AppTheme.smallSpacing * 0.7,
                            )),
                            _buildSummaryItem(
                              context,
                              'Direct Net Balance',
                              '${AppConstants.currencySymbol}${directNetBalance.toStringAsFixed(2)}',
                              directNetBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                              directNetBalance >= 0 ? Colors.green : Colors.red,
                            ),

                            // Divider between sections
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing,
                              tablet: AppTheme.smallSpacing * 1.2,
                              desktop: AppTheme.smallSpacing * 1.5,
                            )),
                            Divider(
                              thickness: ResponsiveHelper.getResponsiveValue<double>(
                                context: context,
                                mobile: 1,
                                tablet: 1.5,
                                desktop: 2,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing,
                              tablet: AppTheme.smallSpacing * 1.2,
                              desktop: AppTheme.smallSpacing * 1.5,
                            )),

                            // Group Expenses Section
                            _buildSectionHeader(context, 'Group Expenses'),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing * 0.5,
                              tablet: AppTheme.smallSpacing * 0.6,
                              desktop: AppTheme.smallSpacing * 0.7,
                            )),
                            _buildSummaryItem(
                              context,
                              'You Owe (Group)',
                              '${AppConstants.currencySymbol}${groupYouOwe.toStringAsFixed(2)}',
                              Icons.group,
                              Colors.purple,
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing * 0.5,
                              tablet: AppTheme.smallSpacing * 0.6,
                              desktop: AppTheme.smallSpacing * 0.7,
                            )),
                            _buildSummaryItem(
                              context,
                              'Owed to You (Group)',
                              '${AppConstants.currencySymbol}${groupOwedToYou.toStringAsFixed(2)}',
                              Icons.group,
                              Colors.teal,
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveValue<double>(
                              context: context,
                              mobile: AppTheme.smallSpacing * 0.5,
                              tablet: AppTheme.smallSpacing * 0.6,
                              desktop: AppTheme.smallSpacing * 0.7,
                            )),
                            _buildSummaryItem(
                              context,
                              'Group Net Balance',
                              '${AppConstants.currencySymbol}${groupNetBalance.toStringAsFixed(2)}',
                              groupNetBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                              groupNetBalance >= 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),



                    // Budget Status
                    if (budgets.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget Status',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToSetBudget,
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),

                      // Show top 3 budgets
                      ...budgets.take(3).map((budget) => BudgetStatusCard(
                        budget: budget,
                        onTap: _navigateToSetBudget,
                      )),
                      const SizedBox(height: AppTheme.mediumSpacing),
                    ],



                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to all transactions
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    // Recent transactions list or empty state
                    recentExpenses.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 48,
                                      color: AppTheme.mediumGray,
                                    ),
                                    const SizedBox(height: AppTheme.smallSpacing),
                                    Text(
                                      'No recent transactions',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.mediumSpacing),
                                    ElevatedButton(
                                      onPressed: _navigateToAddExpense,
                                      child: const Text('Add Expense'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: recentExpenses.map((expense) =>
                              RecentTransactionCard(
                                expense: expense,
                                onTap: () => _navigateToExpenseDetail(expense),
                              )
                            ).toList(),
                          ),


                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(
          context,
          baseFontSize: 16,
          tabletFactor: 1.1,
          desktopFactor: 1.2,
        ),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    final iconSize = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 20,
      tablet: 24,
      desktop: 28,
    );

    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 14,
      tabletFactor: 1.1,
      desktopFactor: 1.2,
    );

    final spacing = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 8,
      tablet: 12,
      desktop: 16,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: iconSize,
            ),
            SizedBox(width: spacing),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Extract the first name from a full name
  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return '';

    // Split the name by spaces and return the first part
    final nameParts = fullName.trim().split(' ');
    return nameParts.first;
  }

  // Show quick action drawer
  void _showQuickActionDrawer() {
    showQuickActionDrawer(
      context,
      onAddExpense: _navigateToAddExpense,
      onSetBudget: _navigateToSetBudget,
      onAddFriend: _navigateToAddFriend,
      onViewAnalytics: _navigateToAnalytics,
      onCalculator: _toggleCalculator,
      onScanReceipt: _showScanReceipt,
    );
  }

  // Navigate to add friend screen
  void _navigateToAddFriend() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddFriendScreen(),
      ),
    );
  }

  // Navigate to analytics screen
  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalyticsScreen(),
      ),
    );
  }

  // Show scan receipt feature (placeholder)
  void _showScanReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt scanning feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Initialize smart notifications
  void _initializeSmartNotifications() async {
    try {
      await SmartNotificationsService().initialize();

      if (!mounted) return;

      // Analyze current data and send notifications if needed
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

      await SmartNotificationsService().analyzeAndNotify(
        expenses: expenseProvider.expenses,
        budgets: budgetProvider.budgets,
      );
    } catch (e) {
      debugPrint('Error initializing smart notifications: $e');
    }
  }


}
