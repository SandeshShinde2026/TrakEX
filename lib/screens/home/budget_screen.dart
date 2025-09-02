import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/auth_helper.dart';
import '../../widgets/budget_alert_card.dart';
import '../../widgets/banner_ad_widget.dart';
import '../budgets/add_category_budget_screen.dart';
import '../budgets/set_total_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  // Set to store IDs of dismissed budget alerts
  final Set<String> _dismissedAlerts = {};
  bool _isRefreshing = false;

  // Animation controllers for enhanced UI
  late AnimationController _progressAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;

  // Page controller for swipeable summary cards
  final PageController _summaryPageController = PageController();
  int _currentSummaryPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // Check authentication
    final isAuthenticated = await AuthHelper.checkAuthenticated(context);

    if (!mounted) return;

    if (isAuthenticated && authProvider.userModel != null) {
      // Load budgets for the user
      await budgetProvider.loadUserBudgets(authProvider.userModel!.id);

      // Reset dismissed alerts when budgets are reloaded
      // This ensures that if a budget is updated and still exceeds the threshold,
      // the alert will show again
      setState(() {
        _dismissedAlerts.clear();
      });
    }
  }

  void _navigateToSetTotalBudgetScreen() async {
    final isAuthenticated = await AuthHelper.checkAuthenticated(context);

    if (!mounted) return;

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetTotalBudgetScreen(
            existingBudget: budgetProvider.totalBudget,
          ),
        ),
      ).then((_) => _loadBudgets()); // Refresh budgets when returning
    }
  }

  void _navigateToAddCategoryBudgetScreen() async {
    final isAuthenticated = await AuthHelper.checkAuthenticated(context);

    if (!mounted) return;

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (isAuthenticated) {
      // Check if total budget exists
      if (!budgetProvider.hasTotalBudget()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a total budget first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddCategoryBudgetScreen(),
        ),
      ).then((_) => _loadBudgets()); // Refresh budgets when returning
    }
  }

  void _navigateToEditCategoryBudget(BudgetModel budget) async {
    final isAuthenticated = await AuthHelper.checkAuthenticated(context);

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCategoryBudgetScreen(existingBudget: budget),
        ),
      ).then((_) => _loadBudgets()); // Refresh budgets when returning
    }
  }

  void _dismissAlert(String budgetId) {
    setState(() {
      _dismissedAlerts.add(budgetId);
    });
  }

  // Show reset confirmation dialog
  Future<void> _showResetConfirmationDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.userModel == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Budgets'),
        content: const Text(
          'Are you sure you want to reset all budgets? This will delete your total budget and all category budgets. This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await budgetProvider.resetAllBudgets(authProvider.userModel!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All budgets have been reset'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the screen
        _loadBudgets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(budgetProvider.error ?? 'Failed to reset budgets'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Manually sync budget spent amounts with actual expenses
  Future<void> _syncBudgetSpentAmounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      try {
        setState(() {
          _isRefreshing = true;
        });

        // Reload budgets which will trigger the sync method
        await budgetProvider.loadUserBudgets(authProvider.userModel!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget amounts synchronized successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to synchronize budget amounts: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);

    // Get total budget
    final totalBudgetModel = budgetProvider.totalBudget;

    // Calculate progress
    final progress = totalBudgetModel != null ? totalBudgetModel.spent / totalBudgetModel.amount : 0.0;

    // Get budget alerts (filtering out dismissed ones)
    final overBudgetCategories = budgetProvider.getOverBudgetCategories()
        .where((budget) => !_dismissedAlerts.contains(budget.id))
        .toList();
    final nearThresholdCategories = budgetProvider.getNearThresholdCategories()
        .where((budget) => !_dismissedAlerts.contains(budget.id))
        .toList();
    final hasAlerts = overBudgetCategories.isNotEmpty || nearThresholdCategories.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          // Sync button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync Budget Amounts',
            onPressed: _isRefreshing ? null : _syncBudgetSpentAmounts,
          ),
          // Reset button
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Reset All Budgets',
            onPressed: _showResetConfirmationDialog,
            color: Colors.red,
          ),
        ],
      ),
      body: StickyBannerAdWidget(
        adLocation: 'dashboard', // Reuse dashboard ads for budget screen
        child: budgetProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                child: ListView(
                children: [
                  // Total Budget section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Budget',
                                style: AppTheme.headingStyle,
                              ),
                              if (budgetProvider.hasTotalBudget())
                                TextButton.icon(
                                  onPressed: _navigateToSetTotalBudgetScreen,
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),

                          if (!budgetProvider.hasTotalBudget()) ...[
                            // No budget set yet
                            const SizedBox(height: AppTheme.mediumSpacing),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: AppTheme.smallSpacing),
                                  const Text(
                                    'No budget set yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.mediumSpacing),
                                  ElevatedButton(
                                    onPressed: _navigateToSetTotalBudgetScreen,
                                    child: const Text('Set Budget'),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Budget period - simplified
                            Text(
                              'Period: ${budgetProvider.totalBudget!.period.substring(0, 1).toUpperCase()}${budgetProvider.totalBudget!.period.substring(1)}',
                              style: AppTheme.captionStyle,
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),

                            // Budget progress indicator - simplified
                            LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AppTheme.lightGray,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress > 0.9 ? AppTheme.errorColor : AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),

                            // Budget amounts
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${AppConstants.currencySymbol}${totalBudgetModel!.spent.toStringAsFixed(2)} / ${AppConstants.currencySymbol}${totalBudgetModel.amount.toStringAsFixed(2)}',
                                  style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: progress > 0.9 ? AppTheme.errorColor : AppTheme.mediumGray,
                                    fontWeight: progress > 0.9 ? FontWeight.w500 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),

                  // Budget Alerts Section
                  if (hasAlerts) ...[
                    Row(
                      children: [
                        Icon(Icons.warning_outlined, color: AppTheme.errorColor),
                        const SizedBox(width: AppTheme.smallSpacing),
                        Text(
                          'Budget Alerts',
                          style: AppTheme.headingStyle.copyWith(color: AppTheme.errorColor),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // Dismiss all alerts (just a visual dismissal, not persisted)
                            setState(() {
                              // Add all alert IDs to the dismissed set
                              for (var budget in overBudgetCategories) {
                                _dismissedAlerts.add(budget.id);
                              }
                              for (var budget in nearThresholdCategories) {
                                _dismissedAlerts.add(budget.id);
                              }
                            });
                          },
                          child: const Text('Dismiss All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    // Over budget alerts
                    ...overBudgetCategories.map((budget) => BudgetAlertCard(
                      budget: budget,
                      onTap: () => _navigateToEditCategoryBudget(budget),
                      onDismiss: () => _dismissAlert(budget.id),
                    )),

                    // Near threshold alerts
                    ...nearThresholdCategories.map((budget) => BudgetAlertCard(
                      budget: budget,
                      onTap: () => _navigateToEditCategoryBudget(budget),
                      onDismiss: () => _dismissAlert(budget.id),
                    )),

                    const SizedBox(height: AppTheme.mediumSpacing),
                  ],

                  // Category budgets title with add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Budgets',
                        style: AppTheme.headingStyle,
                      ),
                      if (budgetProvider.hasTotalBudget())
                        TextButton.icon(
                          onPressed: _navigateToAddCategoryBudgetScreen,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Category'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),

                  // Category budgets list
                  budgetProvider.budgets.isEmpty
                      ? SizedBox(
                          height: 300, // Fixed height for empty state
                          child: _buildEmptyCategoryBudgetsList(),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: budgetProvider.budgets.length,
                          itemBuilder: (context, index) {
                            final budget = budgetProvider.budgets[index];
                            // For dynamically added categories (amount is 999999), don't show progress
                            final isDynamicCategory = budget.amount >= 999999;
                            final progress = isDynamicCategory ? 0.0 : (budget.amount > 0 ? budget.spent / budget.amount : 0.0);
                            final percentage = isDynamicCategory ? 0 : (progress * 100).toInt();
                            final isOverBudget = !isDynamicCategory && budget.spent > budget.amount;

                            // Find the icon for this category
                            IconData categoryIcon = Icons.category_outlined;

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to edit this budget
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddCategoryBudgetScreen(existingBudget: budget),
                                    ),
                                  ).then((_) => _loadBudgets());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                child: Icon(
                                                  categoryIcon,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: AppTheme.smallSpacing),
                                              Text(
                                                budget.category,
                                                style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            // Check if it's a dynamically added category (amount is 999999)
                                            budget.amount >= 999999
                                                ? '${AppConstants.currencySymbol}${budget.spent.toStringAsFixed(2)} / -'
                                                : '${AppConstants.currencySymbol}${budget.spent.toStringAsFixed(2)} / ${AppConstants.currencySymbol}${budget.amount.toStringAsFixed(2)}',
                                            style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.smallSpacing),

                                      // Budget progress indicator - simplified
                                      LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: AppTheme.lightGray,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOverBudget ? AppTheme.errorColor : AppTheme.successColor,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.smallSpacing),

                                      // Percentage - simplified
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: isDynamicCategory
                                            ? Text(
                                                'No limit set',
                                                style: AppTheme.captionStyle.copyWith(fontStyle: FontStyle.italic),
                                              )
                                            : Text(
                                                '$percentage%',
                                                style: AppTheme.captionStyle.copyWith(
                                                  color: isOverBudget ? AppTheme.errorColor : AppTheme.mediumGray,
                                                  fontWeight: isOverBudget ? FontWeight.w500 : FontWeight.w400,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCategoryBudgetScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyCategoryBudgetsList() {
    final budgetProvider = Provider.of<BudgetProvider>(context);

    // Empty state for category budgets list
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppTheme.mediumGray,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          Text(
            'No category budgets yet',
            style: AppTheme.headingStyle.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          if (budgetProvider.hasTotalBudget()) ...[
            Text(
              'Add category budgets to track your spending by category',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            ElevatedButton.icon(
              onPressed: _navigateToAddCategoryBudgetScreen,
              icon: const Icon(Icons.add),
              label: const Text('Add Category Budget'),
            ),
          ] else ...[
            Text(
              'Set a total budget first, then add category budgets',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            ElevatedButton.icon(
              onPressed: _navigateToSetTotalBudgetScreen,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Set Total Budget'),
            ),
          ],
        ],
      ),
    );
  }


}
