import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/expense_model.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/simple_calculator.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/currency_amount_display.dart';
import '../../providers/ad_provider.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';

class EnhancedExpensesScreen extends StatefulWidget {
  // Use a static method to create a key
  static final GlobalKey<_EnhancedExpensesScreenState> _stateKey = GlobalKey<_EnhancedExpensesScreenState>();

  // Constructor that ignores the passed key and uses our static key
  EnhancedExpensesScreen({Key? key}) : super(key: _stateKey);

  // Method to refresh expenses - called from HomeScreen
  void refreshExpenses() {
    _stateKey.currentState?._loadExpenses();
  }

  @override
  State<EnhancedExpensesScreen> createState() => _EnhancedExpensesScreenState();
}

class _EnhancedExpensesScreenState extends State<EnhancedExpensesScreen> with SingleTickerProviderStateMixin {
  bool _localLoading = false;
  String _currentFilter = 'all'; // 'all', 'category', 'date', 'mood'
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMood;
  DateTime _selectedCalendarDate = DateTime.now();
  bool _showCalendar = false;
  bool _showCalculator = false;

  // Tab controller for expenses and splits
  late TabController _tabController;

  // Tab indices
  static const int _allTabIndex = 0;
  static const int _expensesTabIndex = 1;
  static const int _splitsTabIndex = 2;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to update UI when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Just trigger a rebuild
        });
      }
    });

    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _localLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      await expenseProvider.loadUserExpenses(authProvider.userModel!.id);
    }

    if (mounted) {
      setState(() {
        _localLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = 'all';
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _selectedMood = null;
    });
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.expenseCategories.length,
            itemBuilder: (context, index) {
              final category = AppConstants.expenseCategories[index];
              return ListTile(
                leading: Icon(category['icon']),
                title: Text(category['name']),
                onTap: () {
                  setState(() {
                    _currentFilter = 'category';
                    _selectedCategory = category['name'];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Today'),
              onTap: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                setState(() {
                  _currentFilter = 'date';
                  _startDate = today;
                  _endDate = today;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('This Week'),
              onTap: () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 6));
                setState(() {
                  _currentFilter = 'date';
                  _startDate = startOfWeek;
                  _endDate = endOfWeek;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('This Month'),
              onTap: () {
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                final endOfMonth = DateTime(now.year, now.month + 1, 0);
                setState(() {
                  _currentFilter = 'date';
                  _startDate = startOfMonth;
                  _endDate = endOfMonth;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Custom Range'),
              onTap: () async {
                Navigator.pop(context);
                final dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
                );
                if (dateRange != null && mounted) {
                  setState(() {
                    _currentFilter = 'date';
                    _startDate = dateRange.start;
                    _endDate = dateRange.end;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Show reset confirmation dialog
  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Expenses'),
        content: const Text(
          'This will delete all your expenses and reset all budget spent amounts to zero. '
          'This action cannot be undone. Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAllExpenses();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  // Reset all expenses and budget spent amounts
  Future<void> _resetAllExpenses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    if (authProvider.userModel == null) return;

    final userId = authProvider.userModel!.id;

    // Show loading indicator
    setState(() {
      _localLoading = true;
    });

    // Reset all expenses
    final expenseSuccess = await expenseProvider.resetAllExpenses(userId);

    // Reset all budget spent amounts
    final budgetSuccess = await budgetProvider.resetAllBudgets(userId, resetSpentOnly: true);

    // Hide loading indicator
    setState(() {
      _localLoading = false;
    });

    // Show result message
    if (expenseSuccess && budgetSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All expenses and budget spent amounts have been reset'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reset expenses and budgets'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
      if (_showCalendar) {
        _showCalculator = false;
      }
    });
  }

  void _toggleCalculator() {
    setState(() {
      _showCalculator = !_showCalculator;
      if (_showCalculator) {
        _showCalendar = false;
      }
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedCalendarDate = selectedDay;
      _currentFilter = 'date';
      _startDate = selectedDay;
      _endDate = selectedDay;
      _showCalendar = false;
    });
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = ResponsiveHelper.isSmallMobile(context);
    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 14,
      smallMobileFactor: 0.85,
    );
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context) * 0.6;
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? spacing / 2 : spacing,
          vertical: isSmallScreen ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            SizedBox(width: isSmallScreen ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to ensure the widget rebuilds when the expense provider changes
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.filteredExpenses;

    // Apply filters based on current filter
    List<ExpenseModel> filteredExpenses = expenses;
    if (_currentFilter == 'category' && _selectedCategory != null) {
      filteredExpenses = expenses.where((e) => e.category == _selectedCategory).toList();
    } else if (_currentFilter == 'date' && _startDate != null && _endDate != null) {
      // Normalize dates to compare only year, month, day (not time)
      final normalizedStartDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      // Add 1 day to end date to include the entire end date
      final normalizedEndDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

      filteredExpenses = expenses.where((e) {
        // Normalize expense date to compare only year, month, day
        final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
        // Include expenses on the exact start and end dates
        return (expenseDate.isAtSameMomentAs(normalizedStartDate) ||
                expenseDate.isAfter(normalizedStartDate)) &&
              (expenseDate.isBefore(normalizedEndDate) ||
                expenseDate.isAtSameMomentAs(DateTime(normalizedEndDate.year, normalizedEndDate.month, normalizedEndDate.day)));
      }).toList();
    } else if (_currentFilter == 'mood' && _selectedMood != null) {
      filteredExpenses = expenses.where((e) => e.mood == _selectedMood).toList();
    }

    // Calculate total expenses (excluding direct debts)
    final double totalExpenseAmount = ExpenseModel.calculateTotal(
      filteredExpenses.where((e) => !e.isDirectDebt).toList()
    );

    // Prepare filtered expenses for each tab
    // Regular expenses: NOT group expenses, NOT reimbursements, and NOT direct debts
    final regularExpenses = filteredExpenses.where((e) =>
      !e.isGroupExpense &&
      !e.isReimbursement &&
      !e.isDirectDebt &&
      e.amount > 0 // Only positive amounts (actual expenses)
    ).toList();

    // Split expenses: Group expenses OR reimbursements (but NOT direct debts)
    final splitExpenses = filteredExpenses.where((e) =>
      (e.isGroupExpense || e.isReimbursement) &&
      !e.isDirectDebt
    ).toList();

    // Get responsive values
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final isSmallScreen = ResponsiveHelper.isSmallMobile(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final adProvider = Provider.of<AdProvider>(context, listen: false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          ).then((result) {
            if (result == true) {
              // Show interstitial ad after expense is added
              adProvider.onExpenseAdded();
            } else {
              _loadExpenses();
            }
          });
        },
        tooltip: _tabController.index == _allTabIndex
            ? 'Add Expense'
            : _tabController.index == _expensesTabIndex
                ? 'Add Expense'
                : _tabController.index == _splitsTabIndex
                    ? 'Add Group Expense'
                    : 'Add Expense',
        child: Icon(Icons.add, size: iconSize * 0.8),
      ),
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // Delete button in app bar for maximum visibility
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _showResetConfirmationDialog,
            tooltip: 'Reset All Expenses',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: StickyBannerAdWidget(
        adLocation: 'expenses',
        child: ResponsiveWrapper(
          padding: padding,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar with filter, calendar and calculator
            ResponsiveRowColumn(
              forceColumn: isSmallScreen,
              spacing: spacing,
              children: [
                // Filter and action buttons row
                ResponsiveRowColumn(
                  forceRow: true,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Filter buttons
                    Row(
                      children: [
                        _buildFilterButton(
                          context,
                          'Category',
                          Icons.category,
                          isSelected: _currentFilter == 'category',
                          onTap: _showCategoryFilterDialog,
                        ),
                        SizedBox(width: spacing),
                        _buildFilterButton(
                          context,
                          'Date',
                          Icons.date_range,
                          isSelected: _currentFilter == 'date',
                          onTap: _showDateFilterDialog,
                        ),
                      ],
                    ),

                    // Right side buttons
                    Wrap(
                      spacing: isSmallScreen ? spacing / 2 : spacing,
                      children: [
                        // Calendar button
                        IconButton(
                          icon: Icon(
                            Icons.calendar_month,
                            color: _showCalendar ? Theme.of(context).primaryColor : Colors.grey,
                            size: iconSize * 0.8,
                          ),
                          onPressed: _toggleCalendar,
                          tooltip: 'Calendar',
                          constraints: BoxConstraints.tightFor(
                            width: iconSize * 1.5,
                            height: iconSize * 1.5,
                          ),
                          padding: EdgeInsets.zero,
                        ),

                        // Calculator button
                        IconButton(
                          icon: Icon(
                            Icons.calculate,
                            color: _showCalculator ? Theme.of(context).primaryColor : Colors.grey,
                            size: iconSize * 0.8,
                          ),
                          onPressed: _toggleCalculator,
                          tooltip: 'Calculator',
                          constraints: BoxConstraints.tightFor(
                            width: iconSize * 1.5,
                            height: iconSize * 1.5,
                          ),
                          padding: EdgeInsets.zero,
                        ),

                        // Refresh button
                        IconButton(
                          icon: Icon(Icons.refresh, size: iconSize * 0.8),
                          onPressed: _loadExpenses,
                          tooltip: 'Refresh',
                          constraints: BoxConstraints.tightFor(
                            width: iconSize * 1.5,
                            height: iconSize * 1.5,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Calendar widget (collapsible)
            if (_showCalendar) ...[
              SizedBox(height: spacing),
              Card(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Adjust calendar style based on screen size
                    final calendarStyle = isSmallScreen
                        ? const CalendarStyle(
                            outsideDaysVisible: false,
                            isTodayHighlighted: true,
                            markersMaxCount: 3,
                            cellMargin: EdgeInsets.all(4),
                            cellPadding: EdgeInsets.all(2),
                          )
                        : const CalendarStyle();

                    final headerStyle = HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          baseFontSize: 16,
                        ),
                      ),
                    );

                    return TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _selectedCalendarDate,
                      selectedDayPredicate: (day) => isSameDay(_selectedCalendarDate, day),
                      onDaySelected: _onDaySelected,
                      calendarFormat: isSmallScreen ? CalendarFormat.week : CalendarFormat.month,
                      headerStyle: headerStyle,
                      calendarStyle: calendarStyle,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                        CalendarFormat.week: 'Week',
                      },
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 12,
                          ),
                        ),
                        weekendStyle: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 12,
                          ),
                          color: Colors.red[300],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Calculator widget (collapsible)
            if (_showCalculator) ...[
              SizedBox(height: spacing),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final calculatorHeight = ResponsiveHelper.getResponsiveValue<double>(
                      context: context,
                      smallMobile: 300,
                      mobile: 350,
                      tablet: 400,
                      desktop: 450,
                    );

                    return Container(
                      height: calculatorHeight,
                      margin: EdgeInsets.all(spacing / 2),
                      child: const SimpleCalculator(),
                    );
                  },
                ),
              ),
            ],

            // Active filters display
            if (_currentFilter != 'all') ...[
              SizedBox(height: spacing),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Active Filters: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          baseFontSize: 14,
                        ),
                      ),
                    ),
                    if (_currentFilter == 'category' && _selectedCategory != null)
                      Chip(
                        label: Text(
                          _selectedCategory!,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              baseFontSize: 12,
                            ),
                          ),
                        ),
                        deleteIcon: Icon(Icons.close, size: isSmallScreen ? 14 : 16),
                        onDeleted: _clearFilters,
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4 : 8,
                        ),
                      ),
                    if (_currentFilter == 'date' && _startDate != null && _endDate != null)
                      Chip(
                        label: Text(
                          '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              baseFontSize: 12,
                            ),
                          ),
                        ),
                        deleteIcon: Icon(Icons.close, size: isSmallScreen ? 14 : 16),
                        onDeleted: _clearFilters,
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4 : 8,
                        ),
                      ),
                    if (_currentFilter == 'mood' && _selectedMood != null)
                      Chip(
                        label: Text(
                          _selectedMood!,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              baseFontSize: 12,
                            ),
                          ),
                        ),
                        deleteIcon: Icon(Icons.close, size: isSmallScreen ? 14 : 16),
                        onDeleted: _clearFilters,
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4 : 8,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            SizedBox(height: spacing * 1.5),

            // Error message if any
            if (expenseProvider.error != null) ...[
              Container(
                padding: EdgeInsets.all(spacing),
                margin: EdgeInsets.only(bottom: spacing),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: iconSize * 0.8),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        'Error: ${expenseProvider.error}',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.red, size: iconSize * 0.8),
                      onPressed: _loadExpenses,
                      constraints: BoxConstraints.tightFor(
                        width: iconSize * 1.5,
                        height: iconSize * 1.5,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],

            // Total expenses summary
            Container(
              padding: EdgeInsets.symmetric(
                vertical: spacing,
                horizontal: spacing * 1.5,
              ),
              margin: EdgeInsets.only(bottom: spacing),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        baseFontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${totalExpenseAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        baseFontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'All',
                  icon: isSmallScreen ? null : const Icon(Icons.all_inclusive),
                  iconMargin: EdgeInsets.only(bottom: spacing / 4),
                  height: isSmallScreen ? 40 : 56,
                ),
                Tab(
                  text: 'Expenses',
                  icon: isSmallScreen ? null : const Icon(Icons.receipt_long),
                  iconMargin: EdgeInsets.only(bottom: spacing / 4),
                  height: isSmallScreen ? 40 : 56,
                ),
                Tab(
                  text: 'Splits',
                  icon: isSmallScreen ? null : const Icon(Icons.group),
                  iconMargin: EdgeInsets.only(bottom: spacing / 4),
                  height: isSmallScreen ? 40 : 56,
                ),
              ],
              labelColor: Theme.of(context).textTheme.bodyLarge?.color,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              indicatorColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  baseFontSize: 14,
                ),
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  baseFontSize: 14,
                ),
              ),
              indicatorWeight: isSmallScreen ? 2 : 3,
              labelPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? spacing / 2 : spacing,
                vertical: 0,
              ),
            ),

            SizedBox(height: spacing),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All tab - both regular expenses and user's share of group expenses
                  _buildContent(
                    expenseProvider,
                    _getAllExpenses(filteredExpenses, context),
                    isRegularTab: true,
                    isAllTab: true,
                  ),

                  // Expenses tab - only regular expenses (non-group, non-reimbursement)
                  _buildContent(
                    expenseProvider,
                    regularExpenses,
                    isRegularTab: true,
                  ),

                  // Splits tab - only group expenses and reimbursements
                  _buildContent(
                    expenseProvider,
                    splitExpenses,
                    isRegularTab: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // Get all expenses for the "All" tab
  List<ExpenseModel> _getAllExpenses(List<ExpenseModel> filteredExpenses, BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) return [];

    final userId = authProvider.userModel!.id;

    // Create a list to hold all expenses for the "All" tab
    List<ExpenseModel> allExpenses = [];

    // Add all regular expenses (non-group, non-reimbursement)
    allExpenses.addAll(filteredExpenses.where((e) =>
      !e.isGroupExpense &&
      !e.isReimbursement &&
      !e.isDirectDebt &&
      e.amount > 0
    ));

    // For group expenses, create modified expense objects with only the user's share
    final groupExpenses = filteredExpenses.where((e) =>
      e.isGroupExpense &&
      !e.isDirectDebt &&
      !e.isReimbursement
    ).toList();

    for (var expense in groupExpenses) {
      // Get the user's share of this group expense
      final userShare = expense.getUserShare(userId);

      // Only add if the user has a share in this expense
      if (userShare > 0) {
        // Create a modified expense with the user's share as the amount
        final modifiedExpense = expense.copyWith(
          // Don't modify the original amount, we'll display the user's share in the UI
          // We keep the original expense data for reference
        );

        allExpenses.add(modifiedExpense);
      }
    }

    return allExpenses;
  }

  Widget _buildContent(
    ExpenseProvider expenseProvider,
    List<ExpenseModel> expenses,
    {bool isRegularTab = true, bool isAllTab = false}
  ) {
    if (_localLoading || expenseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expenses.isEmpty) {
      // Show different empty state based on tab type
      return _buildEmptyState(
        isGroupExpense: !isRegularTab && !isAllTab,
        isAllTab: isAllTab,
      );
    }

    return _buildGroupedExpensesList(expenses, isRegularTab: isRegularTab, isAllTab: isAllTab);
  }

  Widget _buildEmptyState({required bool isGroupExpense, bool isAllTab = false}) {
    // Get responsive values
    final isSmallScreen = ResponsiveHelper.isSmallMobile(context);
    final iconSize = ResponsiveHelper.getResponsiveIconSize(context) * 3;
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 18,
    );
    final messageFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 14,
    );
    final buttonHeight = ResponsiveHelper.getResponsiveButtonHeight(context);

    String title;
    String message;
    String buttonText;
    IconData icon;

    if (isAllTab) {
      title = 'No expenses found';
      message = 'Your regular expenses and your share of group expenses will appear here';
      buttonText = 'Add Expense';
      icon = Icons.receipt_long;
    } else if (isGroupExpense) {
      title = 'No splits found';
      message = 'Group expenses and reimbursements will appear here';
      buttonText = 'Add Group Expense';
      icon = Icons.group;
    } else {
      title = 'No expenses found';
      message = 'Add your first expense to get started';
      buttonText = 'Add Expense';
      icon = Icons.receipt_long;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.grey[300],
            ),
            SizedBox(height: spacing * 1.5),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: messageFontSize,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing * 1.5),
            SizedBox(
              height: buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final adProvider = Provider.of<AdProvider>(context, listen: false);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      // Show interstitial ad after expense is added
                      adProvider.onExpenseAdded();
                    } else {
                      _loadExpenses();
                    }
                  });
                },
                icon: Icon(Icons.add, size: isSmallScreen ? 16 : 20),
                label: Text(
                  buttonText,
                  style: TextStyle(fontSize: messageFontSize),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing * 1.5,
                    vertical: spacing,
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildGroupedExpensesList(List<ExpenseModel> expenses, {bool isRegularTab = true, bool isAllTab = false}) {
    // Get responsive values
    final isSmallScreen = ResponsiveHelper.isSmallMobile(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 16,
    );

    // Group expenses by date
    final Map<String, List<ExpenseModel>> groupedExpenses = {};
    final Map<String, double> dailyTotals = {};

    // Get current user ID for the All tab
    String? currentUserId;
    if (isAllTab) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      currentUserId = authProvider.userModel?.id;
    }

    for (var expense in expenses) {
      final dateStr = DateFormat('yyyy-MM-dd').format(expense.date);
      if (!groupedExpenses.containsKey(dateStr)) {
        groupedExpenses[dateStr] = [];
      }
      groupedExpenses[dateStr]!.add(expense);

      // Calculate daily totals
      if (!dailyTotals.containsKey(dateStr)) {
        dailyTotals[dateStr] = 0;
      }

      // For the All tab, use the user's share for group expenses
      if (isAllTab && expense.isGroupExpense && currentUserId != null) {
        dailyTotals[dateStr] = dailyTotals[dateStr]! + expense.getUserShare(currentUserId);
      } else {
        dailyTotals[dateStr] = dailyTotals[dateStr]! + expense.effectiveAmount;
      }
    }

    // Sort dates in descending order
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final date = DateTime.parse(dateStr);
        final expensesForDate = groupedExpenses[dateStr]!;
        final dailyTotal = dailyTotals[dateStr]!;

        // Format date based on screen size
        final dateFormat = isSmallScreen
            ? DateFormat('MMM d, yyyy')
            : DateFormat('MMMM d, yyyy');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header - simplified
            Container(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(date),
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${dailyTotal.toStringAsFixed(2)}',
                    style: AppTheme.bodyStyle.copyWith(
                      color: dailyTotal < 0 ? Colors.green.shade200 : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Expenses for this date
            ...expensesForDate.map((expense) => _buildExpenseItem(context, expense, isRegularTab: isRegularTab, isAllTab: isAllTab)),

            // Add some space between date groups
            SizedBox(height: spacing * 1.5),
          ],
        );
      },
          ),
        ),


      ],
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseModel expense, {bool isRegularTab = true, bool isAllTab = false}) {
    // Get responsive values
    final isSmallScreen = ResponsiveHelper.isSmallMobile(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 16,
    );
    final subtitleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 14,
    );
    final smallTextFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      baseFontSize: 12,
    );
    final avatarSize = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      smallMobile: 36,
      mobile: 40,
      tablet: 48,
      desktop: 56,
    );
    final iconSize = avatarSize * 0.6;

    // Find the category icon
    final category = AppConstants.expenseCategories.firstWhere(
      (cat) => cat['name'] == expense.category,
      orElse: () => AppConstants.expenseCategories.last,
    );

    // Get current user ID and calculate user's share for group expenses in All tab
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id;
    double displayAmount = expense.effectiveAmount;

    // For the All tab, use the user's share for group expenses
    if (isAllTab && expense.isGroupExpense && currentUserId != null) {
      displayAmount = expense.getUserShare(currentUserId);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.mediumSpacing),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            expense.isGroupExpense
                ? Icons.group_outlined
                : expense.isReimbursement
                    ? Icons.swap_horiz_outlined
                    : category['icon'],
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          expense.category,
          style: AppTheme.bodyStyle,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.description,
              style: AppTheme.captionStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            if (expense.isGroupExpense && expense.participants.isNotEmpty) ...[
              // In All tab, show "Your share of group expense" instead of "Split with X people"
              if (isAllTab)
                Text(
                  'Your share of group expense',
                  style: TextStyle(
                    fontSize: smallTextFontSize,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  'Split with ${expense.participants.length} ${expense.participants.length == 1 ? 'person' : 'people'}',
                  style: TextStyle(
                    fontSize: smallTextFontSize,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              // Show participants in the Splits tab
              if (!isRegularTab && !isAllTab && expense.participants.isNotEmpty)
                Wrap(
                  spacing: spacing / 2,
                  runSpacing: spacing / 4,
                  children: expense.participants.map((participant) {
                    final userId = participant['userId'] as String;
                    final share = participant['share'] as double;
                    final name = participant['name'] as String? ?? userId.split('@').first;

                    // Check if this participant is the current user
                    final isCurrentUser = authProvider.userModel != null &&
                                         userId == authProvider.userModel!.id;

                    return Chip(
                      label: Text(
                        '$name${isCurrentUser ? ' (you)' : ''}: ${AppConstants.currencySymbol}${share.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 4 : 8,
                        vertical: 0,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
        isThreeLine: expense.isGroupExpense && expense.participants.isNotEmpty && !isAllTab,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CurrencyAmountDisplay(
              expense: expense,
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: displayAmount < 0 ? AppTheme.successColor : null,
              ),
              showConversionInfo: false, // Keep it simple in list view
            ),
            Text(
              DateFormat('h:mm a').format(expense.date),
              style: AppTheme.captionStyle,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          ).then((_) => _loadExpenses());
        },
      ),
    );
  }
}
