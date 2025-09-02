import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/expense_model.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_detail_screen.dart';

class SimpleExpensesScreen extends StatefulWidget {
  const SimpleExpensesScreen({Key? key}) : super(key: key);

  @override
  State<SimpleExpensesScreen> createState() => _SimpleExpensesScreenState();
}

class _SimpleExpensesScreenState extends State<SimpleExpensesScreen> {
  bool _isLoading = true;
  String? _error;
  List<ExpenseModel> _expenses = [];
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Set a timeout to force exit loading state after 10 seconds
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        debugPrint('SimpleExpensesScreen: Loading timed out after 10 seconds');
        setState(() {
          _isLoading = false;
          _error = 'Loading timed out. Please try again.';
        });
      }
    });

    try {
      debugPrint('SimpleExpensesScreen: Starting to load expenses');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('SimpleExpensesScreen: Current user: ${user?.uid}');

      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not authenticated. Please log in again.';
        });
        _loadingTimer?.cancel();
        return;
      }

      // Get expenses directly from Firestore
      debugPrint('SimpleExpensesScreen: Fetching expenses from Firestore');
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
            throw 'Connection timeout. Please check your internet connection.';
          });

      debugPrint('SimpleExpensesScreen: Got ${snapshot.docs.length} expenses');

      // Convert to expense models
      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromDocument(doc))
          .toList();

      // Cancel the timer since we're done loading
      _loadingTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });

      debugPrint('SimpleExpensesScreen: Expenses loaded successfully');

    } catch (e) {
      debugPrint('SimpleExpensesScreen: Error loading expenses: $e');

      // Cancel the timer since we're done loading
      _loadingTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Test expense functionality removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Add a refresh button at the top
            if (!_isLoading && _error == null)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadExpenses,
                  tooltip: 'Refresh expenses',
                ),
              ),

            // Main content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _expenses.isEmpty
                          ? _buildEmptyState()
                          : _buildExpensesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Loading expenses...'),
          const SizedBox(height: 8),
          const Text(
            'If loading takes too long, try canceling and retrying',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                  });
                  _loadingTimer?.cancel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
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
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Clear the error and show empty state
              setState(() {
                _error = null;
                _expenses = [];
              });
            },
            child: const Text('Clear Error'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          const Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          const Text(
            'Add your first expense',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
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
                // If success, the expense is already added to the list in the provider
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

        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
          ).then((result) {
            // Only reload if we didn't get a success result
            // If success, the expense is already updated in the provider
            if (result != true) {
              _loadExpenses();
            }
          });
        },
      ),
    );
  }
}
