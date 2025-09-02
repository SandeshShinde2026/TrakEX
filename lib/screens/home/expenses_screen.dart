import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../utils/test_data.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';

class ExpensesScreen extends StatefulWidget {
  // Use a static method to create a key
  static final GlobalKey<_ExpensesScreenState> _stateKey = GlobalKey<_ExpensesScreenState>();

  // Constructor that ignores the passed key and uses our static key
  ExpensesScreen({Key? key}) : super(key: _stateKey);

  // Method to refresh expenses - called from HomeScreen
  void refreshExpenses() {
    _stateKey.currentState?._loadExpenses();
  }

  // Method to run debug tests - called from HomeScreen
  void debugTests() {
    _stateKey.currentState?._runDebugTests();
  }

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _currentFilter = 'all';
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMood;

  bool _localLoading = false;
  bool _loadingTimedOut = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    // Cancel any existing timer
    _loadingTimer?.cancel();

    // Set local loading state
    setState(() {
      _localLoading = true;
      _loadingTimedOut = false;
    });

    // Set a shorter timeout for loading (8 seconds)
    _loadingTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        debugPrint('Loading timed out after 8 seconds');
        setState(() {
          _loadingTimedOut = true;
          _localLoading = false; // Force exit from loading state
        });
      }
    });

    // Force exit from loading state after 20 seconds no matter what
    Timer(const Duration(seconds: 20), () {
      if (mounted && _localLoading) {
        debugPrint('Force exiting loading state after 20 seconds');
        setState(() {
          _localLoading = false;
          _loadingTimedOut = true;
        });
      }
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    try {
      // Reset any existing errors
      expenseProvider.clearError();

      // First check authentication status
      debugPrint('Checking authentication status...');
      final isAuthenticated = await authProvider.checkAuthStatus();

      if (!mounted) return;
      debugPrint('Authentication status: $isAuthenticated');

      if (!isAuthenticated || authProvider.userModel == null) {
        setState(() {
          _localLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Please sign in to view expenses'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Login',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        );
        return;
      }

      // Load expenses with a timeout
      debugPrint('Loading expenses for user: ${authProvider.userModel!.id}');

      // Create a timeout for the expense loading operation
      bool expensesLoaded = false;

      // Start loading expenses
      expenseProvider.loadUserExpenses(authProvider.userModel!.id).then((_) {
        expensesLoaded = true;
        debugPrint('Expenses loaded successfully');

        if (mounted) {
          setState(() {
            _localLoading = false;
          });
          _loadingTimer?.cancel();
        }
      }).catchError((error) {
        debugPrint('Error loading expenses: $error');

        if (mounted) {
          setState(() {
            _localLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading expenses: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      // Set a timeout specifically for the expense loading
      Timer(const Duration(seconds: 5), () {
        if (!expensesLoaded && mounted) {
          debugPrint('Expense loading operation timed out');
          setState(() {
            _localLoading = false;
          });
        }
      });

    } catch (e) {
      debugPrint('Exception in _loadExpenses: $e');

      if (mounted) {
        setState(() {
          _localLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expenses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                    Navigator.pop(context);
                    setState(() {
                      _currentFilter = 'category';
                      _selectedCategory = category['name'];
                    });

                    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                    expenseProvider.filterByCategory(_selectedCategory!);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDateFilterDialog() async {
    final now = DateTime.now();
    final initialStartDate = _startDate ?? DateTime(now.year, now.month, 1);
    final initialEndDate = _endDate ?? now;

    DateTime startDate = initialStartDate;
    DateTime endDate = initialEndDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Date Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(
                      DateFormat(AppConstants.dateFormat).format(startDate),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: now,
                      );

                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(
                      DateFormat(AppConstants.dateFormat).format(endDate),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: now,
                      );

                      if (picked != null) {
                        setDialogState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _currentFilter = 'date';
        _startDate = startDate;
        _endDate = endDate;
      });

      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      expenseProvider.filterByDateRange(startDate, endDate);
    }
  }

  void _showMoodFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Mood'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppConstants.moodOptions.length,
              itemBuilder: (context, index) {
                final mood = AppConstants.moodOptions[index];
                return ListTile(
                  leading: Icon(mood['icon']),
                  title: Text(mood['name']),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentFilter = 'mood';
                      _selectedMood = mood['name'];
                    });

                    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                    expenseProvider.filterByMood(_selectedMood!);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = 'all';
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _selectedMood = null;
    });

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    expenseProvider.clearFilters();
  }

  // Debug function to test Firestore access
  Future<void> _runDebugTests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Diagnostics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing app connections...'),
          ],
        ),
      ),
    );

    // Run tests
    try {
      // Check authentication status
      final isAuthenticated = authProvider.isAuthenticated;
      final hasUserModel = authProvider.userModel != null;
      final authError = authProvider.error;

      // Check expense provider status
      final isLoading = expenseProvider.isLoading;
      final expenseError = expenseProvider.error;
      final expenseCount = expenseProvider.expenses.length;

      // Check if user document exists
      String? userId;
      bool userExists = false;
      bool expensesAccessible = false;
      bool testExpenseCreated = false;
      int directExpenseCount = 0;

      if (hasUserModel) {
        userId = authProvider.userModel!.id;
        userExists = await TestData.checkUserDocument(userId);
        expensesAccessible = await TestData.checkExpensesCollection();

        // Try to get expenses directly
        try {
          final expenses = await TestData.getExpensesForUser(userId);
          directExpenseCount = expenses.length;
          debugPrint('Direct expense count: $directExpenseCount');
        } catch (e) {
          debugPrint('Error getting expenses directly: $e');
        }

        // Create a test expense
        if (userExists && expensesAccessible) {
          await TestData.createTestExpense(userId);
          testExpenseCreated = true;
        }
      }

      // Close dialog
      if (mounted) Navigator.pop(context);

      // Show detailed results dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Diagnostic Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDiagnosticItem('Authentication', isAuthenticated ? 'Yes' : 'No', isAuthenticated),
                  _buildDiagnosticItem('User Model', hasUserModel ? 'Available' : 'Missing', hasUserModel),
                  if (authError != null)
                    _buildDiagnosticItem('Auth Error', authError, false),
                  _buildDiagnosticItem('User ID', userId ?? 'Not available', userId != null),
                  _buildDiagnosticItem('User Document', userExists ? 'Exists' : 'Not found', userExists),
                  _buildDiagnosticItem('Expenses Collection', expensesAccessible ? 'Accessible' : 'Not accessible', expensesAccessible),
                  _buildDiagnosticItem('Expense Provider', isLoading ? 'Loading' : 'Ready', !isLoading),
                  _buildDiagnosticItem('Provider Expense Count', expenseCount.toString(), true),
                  _buildDiagnosticItem('Direct Expense Count', directExpenseCount.toString(), true),
                  if (expenseError != null)
                    _buildDiagnosticItem('Expense Error', expenseError, false),
                  _buildDiagnosticItem('Test Expense', testExpenseCreated ? 'Created' : 'Not created', testExpenseCreated),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadExpenses();
                },
                child: const Text('Reload Expenses'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Force reset the provider state
                  final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                  expenseProvider.clearError();
                  expenseProvider.forceReset();

                  // Force reload with a slight delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _loadExpenses();
                    }
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Force Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running diagnostics: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildDiagnosticItem(String label, String value, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isSuccess
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87)
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.filteredExpenses.isEmpty && _currentFilter == 'all'
        ? expenseProvider.expenses
        : expenseProvider.filteredExpenses;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.smallSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFilterButton(
                      context,
                      'All',
                      Icons.list,
                      isSelected: _currentFilter == 'all',
                      onTap: _clearFilters,
                    ),
                    _buildFilterButton(
                      context,
                      'Category',
                      Icons.category,
                      isSelected: _currentFilter == 'category',
                      onTap: _showCategoryFilterDialog,
                    ),
                    _buildFilterButton(
                      context,
                      'Date',
                      Icons.calendar_today,
                      isSelected: _currentFilter == 'date',
                      onTap: _showDateFilterDialog,
                    ),
                    _buildFilterButton(
                      context,
                      'Mood',
                      Icons.mood,
                      isSelected: _currentFilter == 'mood',
                      onTap: _showMoodFilterDialog,
                    ),
                  ],
                ),
              ),
            ),

            // Active filter indicator
            if (_currentFilter != 'all') ...[
              const SizedBox(height: AppTheme.smallSpacing),
              _buildActiveFilterChip(),
            ],

            const SizedBox(height: AppTheme.mediumSpacing),

            // Error message if any
            if (expenseProvider.error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.smallSpacing),
                margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error: ${expenseProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.red),
                      onPressed: _loadExpenses,
                    ),
                  ],
                ),
              ),
            ],

            // Expenses list
            Expanded(
              child: _buildContent(expenseProvider, expenses),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 12.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ExpenseProvider expenseProvider, List<ExpenseModel> expenses) {
    // Show local loading state first
    if (_localLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading expenses...'),
            const SizedBox(height: 16),
            // Add immediate debug button
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _localLoading = false;
                });
                _runDebugTests();
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    // Show timeout message if loading took too long
    if (_loadingTimedOut && expenseProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading is taking longer than expected...'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadingTimedOut = false;
                    });
                    _loadExpenses();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _runDebugTests,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show provider loading state
    if (expenseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if any
    if (expenseProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${expenseProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadExpenses,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _runDebugTests,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show empty state or expenses list
    return expenses.isEmpty ? _buildEmptyState() : _buildExpensesList(expenses);
  }

  Widget _buildActiveFilterChip() {
    String filterText;
    IconData filterIcon;

    switch (_currentFilter) {
      case 'category':
        filterText = 'Category: $_selectedCategory';
        filterIcon = Icons.category;
        break;
      case 'date':
        filterText = 'Date: ${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}';
        filterIcon = Icons.calendar_today;
        break;
      case 'mood':
        filterText = 'Mood: $_selectedMood';
        filterIcon = Icons.mood;
        break;
      default:
        filterText = '';
        filterIcon = Icons.filter_list;
    }

    return Chip(
      avatar: Icon(filterIcon, size: 16),
      label: Text(filterText),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: _clearFilters,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          Text(
            _currentFilter == 'all'
                ? 'No expenses yet'
                : 'No expenses match your filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          Text(
            _currentFilter == 'all'
                ? 'Add your first expense'
                : 'Try changing or clearing your filter',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          // Add button for adding first expense
          if (_currentFilter == 'all') ...[
            const SizedBox(height: AppTheme.mediumSpacing),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                ).then((result) {
                  // Only reload if we didn't get a success result
                  // If success, the expense is already added to the list
                  if (result != true) {
                    _loadExpenses();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.mediumSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            // Add a button to create a test expense directly
            ElevatedButton.icon(
              onPressed: _createTestExpense,
              icon: const Icon(Icons.science),
              label: const Text('Create Test Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.mediumSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Function to create a test expense directly
  Future<void> _createTestExpense() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = authProvider.userModel!.id;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Creating Test Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating a test expense...'),
          ],
        ),
      ),
    );

    try {
      // Create a test expense
      await TestData.createTestExpense(userId);

      // Close dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test expense created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload expenses
        _loadExpenses();
      }
    } catch (e) {
      // Close dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExpensesList(List<ExpenseModel> expenses) {
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseItem(context, expense);
      },
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseModel expense) {
    // Find the category icon
    final category = AppConstants.expenseCategories.firstWhere(
      (cat) => cat['name'] == expense.category,
      orElse: () => AppConstants.expenseCategories.last,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
          child: Icon(
            category['icon'],
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(expense.category),
        subtitle: Text(expense.description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${expense.amount < 0 ? '-' : ''}${AppConstants.currencySymbol}${expense.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: expense.amount < 0 ? Colors.green : null,
              ),
            ),
            Text(
              DateFormat(AppConstants.dateFormat).format(expense.date),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey,
              ),
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
