import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/storage_service.dart';
import '../services/budget_service.dart';
import '../providers/budget_provider.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  final StorageService _storageService = StorageService();
  final BudgetService _budgetService = BudgetService();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  bool _isLoading = false;
  String? _error;
  String _currentFilter = 'all'; // 'all', 'category', 'date', 'mood'
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMood;

  // Debounce mechanism to prevent duplicate submissions
  bool _isAddingExpense = false;
  DateTime? _lastExpenseAddedTime;

  List<ExpenseModel> get expenses => _expenses;
  List<ExpenseModel> get filteredExpenses => _filteredExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;
  String? get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedMood => _selectedMood;

  // Load user expenses
  Future<void> loadUserExpenses(String userId) async {
    debugPrint('ExpenseProvider: Starting to load expenses for user $userId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Set a timeout to force loading state to false after 20 seconds
    Future.delayed(const Duration(seconds: 20), () {
      if (_isLoading) {
        debugPrint('ExpenseProvider: Force ending loading state after timeout');
        _isLoading = false;
        if (_error == null) {
          _error = 'Failed to get real-time updates: Failed to load expenses: Connection timeout. Please check your internet connection.';
        }
        notifyListeners();
      }
    });

    try {
      // First, check if the user exists and has access to the expenses collection
      debugPrint('ExpenseProvider: Checking if user document exists');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get()
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw 'Connection timeout while checking user document. Please check your internet connection.';
      });

      if (!userDoc.exists) {
        debugPrint('ExpenseProvider: User document not found');
        _isLoading = false;
        _error = 'User document not found. Please try logging in again.';
        notifyListeners();
        return;
      }

      // Use a one-time get instead of a stream for initial loading
      debugPrint('ExpenseProvider: Fetching expenses from Firestore');
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw 'Connection timeout while fetching expenses. Please check your internet connection.';
      });

      debugPrint('ExpenseProvider: Processing ${snapshot.docs.length} expenses');
      _expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromDocument(doc))
          .toList();

      _applyFilters();
      _isLoading = false;
      notifyListeners();
      debugPrint('ExpenseProvider: Initial expenses loaded successfully');

      // Set up the stream for real-time updates after initial load
      // Use a try-catch block to handle stream creation errors
      try {
        debugPrint('ExpenseProvider: Setting up real-time updates stream');
        _expenseService.getUserExpenses(userId).listen(
          (expenses) {
            debugPrint('ExpenseProvider: Received ${expenses.length} expenses from stream');
            _expenses = expenses;
            _applyFilters();
            _isLoading = false; // Ensure loading is set to false
            _error = null; // Clear any previous errors
            notifyListeners();
          },
          onError: (e) {
            debugPrint('ExpenseProvider: Error in expense stream: $e');
            _error = 'Failed to get real-time updates: ${e.toString()}';
            _isLoading = false;
            notifyListeners();
          },
          onDone: () {
            // This is called when the stream is closed
            debugPrint('ExpenseProvider: Expense stream closed');
            _isLoading = false;
            notifyListeners();
          },
        );
      } catch (streamError) {
        debugPrint('ExpenseProvider: Error setting up stream: $streamError');
        // Don't set error here as we already have the initial data
      }
    } catch (e) {
      debugPrint('ExpenseProvider: Error loading expenses: $e');
      _isLoading = false;
      _error = 'Failed to load expenses: ${e.toString()}';
      // Initialize with empty list to avoid null errors
      _expenses = [];
      _filteredExpenses = [];
      notifyListeners();
    }
  }

  // Add a new expense
  Future<bool> addExpense(ExpenseModel expense, List<File>? images, {BuildContext? context}) async {
    try {
      // Check for duplicate submission
      final now = DateTime.now();
      if (_isAddingExpense) {
        debugPrint('ExpenseProvider: Already adding an expense, preventing duplicate submission');
        return false;
      }

      // Check if we've added an expense in the last 2 seconds
      if (_lastExpenseAddedTime != null) {
        final timeSinceLastAdd = now.difference(_lastExpenseAddedTime!).inSeconds;
        if (timeSinceLastAdd < 2) {
          debugPrint('ExpenseProvider: Expense added too recently (${timeSinceLastAdd}s ago), preventing potential duplicate');
          return false;
        }
      }

      // Set flags to prevent duplicate submissions
      _isAddingExpense = true;
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('ExpenseProvider: Adding expense with userId: ${expense.userId}');

      try {
        // Upload images if any
        List<String>? imageUrls;
        if (images != null && images.isNotEmpty) {
          debugPrint('ExpenseProvider: Uploading ${images.length} images');
          try {
            imageUrls = await _storageService.uploadExpenseImages(expense.userId, images)
                .timeout(const Duration(seconds: 15));
            debugPrint('ExpenseProvider: Images uploaded successfully');
          } catch (imageError) {
            debugPrint('ExpenseProvider: Error uploading images: $imageError');
            // Continue without images if there's an error
            imageUrls = null;
          }
        }

        // Create expense with image URLs
        final newExpense = expense.copyWith(imageUrls: imageUrls);

        debugPrint('ExpenseProvider: Saving expense to Firestore');
        final savedExpense = await _expenseService.addExpense(newExpense)
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw 'Connection timeout while adding expense. Please check your internet connection.';
        });

        debugPrint('ExpenseProvider: Expense saved to Firestore successfully');

        // Update budget spent amount
        try {
          await _budgetService.updateBudgetSpent(savedExpense);
          debugPrint('ExpenseProvider: Budget updated successfully');

          // Check if this expense has triggered a budget alert
          if (context != null && context.mounted) {
            // Get the BudgetProvider
            final budgetProvider = context.read<BudgetProvider>();

            // Check if there's a budget alert for this category
            debugPrint('ExpenseProvider: Checking for budget alerts for category: ${savedExpense.category}');
            budgetProvider.showBudgetAlertDialog(context, savedExpense.category);
          }
        } catch (budgetError) {
          // Don't fail the whole operation if budget update fails
          debugPrint('ExpenseProvider: Error updating budget: $budgetError');
        }

        // Don't add the expense to our local list since the Firestore stream will update it
        // This prevents duplicate expenses from appearing in the UI
        // The UI will update when the Firestore stream sends the update

        // Ensure we notify listeners to update the UI
        _isLoading = false;
        _isAddingExpense = false;
        _lastExpenseAddedTime = DateTime.now();
        notifyListeners();
        return true;
      } catch (firestoreError) {
        debugPrint('ExpenseProvider: Firestore error: $firestoreError');

        // Check if it's a permission error
        if (firestoreError.toString().contains('permission-denied')) {
          _error = 'Firebase permission denied: The current user does not have permission to add expenses. Please check your Firestore security rules.';
        } else {
          _error = 'Failed to add expense: ${firestoreError.toString()}';
        }

        _isLoading = false;
        _isAddingExpense = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('ExpenseProvider: General error adding expense: $e');
      _isLoading = false;
      _isAddingExpense = false;
      _error = 'Failed to add expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update an expense
  Future<bool> updateExpense(ExpenseModel expense, List<File>? newImages, {BuildContext? context}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('ExpenseProvider: Updating expense with id: ${expense.id}');

      try {
        // Find the existing expense
        final existingExpense = _expenses.firstWhere((e) => e.id == expense.id);

        // Handle images
        List<String>? updatedImageUrls = existingExpense.imageUrls;

        if (newImages != null && newImages.isNotEmpty) {
          // Upload new images
          debugPrint('ExpenseProvider: Uploading ${newImages.length} new images');
          final newImageUrls = await _storageService.uploadExpenseImages(expense.userId, newImages);

          // Combine with existing images
          if (updatedImageUrls != null) {
            updatedImageUrls = [...updatedImageUrls, ...newImageUrls];
          } else {
            updatedImageUrls = newImageUrls;
          }
        }

        // Update expense with new image URLs
        final updatedExpense = expense.copyWith(imageUrls: updatedImageUrls);
        await _expenseService.updateExpense(updatedExpense);
        debugPrint('ExpenseProvider: Expense updated in Firestore successfully');

        // Update budget spent amount if amount changed
        if (existingExpense.amount != updatedExpense.amount ||
            existingExpense.category != updatedExpense.category) {
          try {
            // If category changed, we need to update both budgets
            if (existingExpense.category != updatedExpense.category) {
              // First, subtract from old category budget
              final negativeExpense = existingExpense.copyWith(amount: -existingExpense.amount);
              await _budgetService.updateBudgetSpent(negativeExpense);

              // Then add to new category budget
              await _budgetService.updateBudgetSpent(updatedExpense);
            } else {
              // Just update the amount difference
              final amountDiff = updatedExpense.amount - existingExpense.amount;
              final diffExpense = updatedExpense.copyWith(amount: amountDiff);
              await _budgetService.updateBudgetSpent(diffExpense);
            }

            debugPrint('ExpenseProvider: Budget updated successfully');

            // Check if this expense has triggered a budget alert
            if (context != null && context.mounted) {
              // Get the BudgetProvider
              final budgetProvider = context.read<BudgetProvider>();

              // Check if there's a budget alert for this category
              debugPrint('ExpenseProvider: Checking for budget alerts for category: ${updatedExpense.category}');
              budgetProvider.showBudgetAlertDialog(context, updatedExpense.category);

              // If category changed, also check the old category
              if (existingExpense.category != updatedExpense.category) {
                debugPrint('ExpenseProvider: Checking for budget alerts for old category: ${existingExpense.category}');
                budgetProvider.showBudgetAlertDialog(context, existingExpense.category);
              }
            }
          } catch (budgetError) {
            // Don't fail the whole operation if budget update fails
            debugPrint('ExpenseProvider: Error updating budget: $budgetError');
          }
        }

        // Manually update the expense in our local list for immediate UI update
        final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);
        if (index != -1) {
          _expenses[index] = updatedExpense;
          _applyFilters(); // Re-apply any active filters
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (firestoreError) {
        debugPrint('ExpenseProvider: Firestore error: $firestoreError');
        _isLoading = false;
        _error = 'Failed to update expense: ${firestoreError.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('ExpenseProvider: General error updating expense: $e');
      _isLoading = false;
      _error = 'Failed to update expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Delete an expense
  Future<bool> deleteExpense(String expenseId, {BuildContext? context}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('ExpenseProvider: Deleting expense with id: $expenseId');

      try {
        // Find the expense to get image URLs
        final expense = _expenses.firstWhere((e) => e.id == expenseId);

        // Delete images if any
        if (expense.imageUrls != null && expense.imageUrls!.isNotEmpty) {
          debugPrint('ExpenseProvider: Deleting ${expense.imageUrls!.length} images');
          await _storageService.deleteImages(expense.imageUrls!);
        }

        // Delete the expense from Firestore
        await _expenseService.deleteExpense(expenseId);
        debugPrint('ExpenseProvider: Expense deleted from Firestore successfully');

        // Update budget spent amount (subtract the expense amount)
        try {
          // Create a negative expense to subtract from budget
          final negativeExpense = expense.copyWith(amount: -expense.amount);
          await _budgetService.updateBudgetSpent(negativeExpense);
          debugPrint('ExpenseProvider: Budget updated successfully');

          // Check if this expense has triggered a budget alert
          if (context != null && context.mounted) {
            // Get the BudgetProvider
            final budgetProvider = context.read<BudgetProvider>();

            // Check if there's a budget alert for this category
            debugPrint('ExpenseProvider: Checking for budget alerts for category: ${expense.category}');
            budgetProvider.showBudgetAlertDialog(context, expense.category);
          }
        } catch (budgetError) {
          // Don't fail the whole operation if budget update fails
          debugPrint('ExpenseProvider: Error updating budget: $budgetError');
        }

        // Manually remove the expense from our local list for immediate UI update
        _expenses.removeWhere((e) => e.id == expenseId);
        _applyFilters(); // Re-apply any active filters

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (firestoreError) {
        debugPrint('ExpenseProvider: Firestore error: $firestoreError');
        _isLoading = false;
        _error = 'Failed to delete expense: ${firestoreError.toString()}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('ExpenseProvider: General error deleting expense: $e');
      _isLoading = false;
      _error = 'Failed to delete expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Filter expenses by category
  void filterByCategory(String category) {
    _currentFilter = 'category';
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Filter expenses by date range
  void filterByDateRange(DateTime start, DateTime end) {
    _currentFilter = 'date';
    _startDate = start;
    _endDate = end;
    _applyFilters();
    notifyListeners();
  }

  // Filter expenses by mood
  void filterByMood(String mood) {
    _currentFilter = 'mood';
    _selectedMood = mood;
    _applyFilters();
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _currentFilter = 'all';
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    _selectedMood = null;
    _filteredExpenses = _expenses;
    notifyListeners();
  }

  // Apply current filters
  void _applyFilters() {
    switch (_currentFilter) {
      case 'category':
        if (_selectedCategory != null) {
          _filteredExpenses = _expenses
              .where((expense) => expense.category == _selectedCategory)
              .toList();
        }
        break;
      case 'date':
        if (_startDate != null && _endDate != null) {
          // Normalize dates to compare only year, month, day (not time)
          final normalizedStartDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          // Add 1 day to end date to include the entire end date
          final normalizedEndDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

          _filteredExpenses = _expenses
              .where((expense) {
                // Normalize expense date to compare only year, month, day
                final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
                // Include expenses on the exact start and end dates
                return (expenseDate.isAtSameMomentAs(normalizedStartDate) ||
                        expenseDate.isAfter(normalizedStartDate)) &&
                       (expenseDate.isBefore(normalizedEndDate) ||
                        expenseDate.isAtSameMomentAs(DateTime(normalizedEndDate.year, normalizedEndDate.month, normalizedEndDate.day)));
              })
              .toList();
        }
        break;
      case 'mood':
        if (_selectedMood != null) {
          _filteredExpenses = _expenses
              .where((expense) => expense.mood == _selectedMood)
              .toList();
        }
        break;
      default:
        _filteredExpenses = _expenses;
    }
  }

  // Get total expenses for a period
  double getTotalExpenses(DateTime start, DateTime end) {
    // Filter out direct debt transactions
    double total = 0.0;

    for (var expense in _expenses) {
      // Skip direct debt transactions
      if (expense.isDirectDebt) {
        continue;
      }

      // Check if expense is within date range
      if (expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)))) {
        total += expense.effectiveAmount;
      }
    }

    debugPrint('ExpenseProvider: Calculated total expenses: $total for period ${start.toString()} to ${end.toString()}');
    return total;
  }

  // Get expenses by category for a period
  Map<String, double> getExpensesByCategory(DateTime start, DateTime end) {
    final Map<String, double> categoryTotals = {};

    for (var expense in _expenses) {
      // Skip direct debt transactions
      if (expense.isDirectDebt) {
        continue;
      }

      // Check if expense is within date range
      if (expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)))) {
        categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.effectiveAmount;
      }
    }

    debugPrint('ExpenseProvider: Calculated category expenses: ${categoryTotals.toString()} for period ${start.toString()} to ${end.toString()}');
    return categoryTotals;
  }

  // Get expenses by mood for a period
  Map<String, double> getExpensesByMood(DateTime start, DateTime end) {
    final Map<String, double> moodTotals = {};

    for (var expense in _expenses) {
      // Skip direct debt transactions
      if (expense.isDirectDebt) {
        continue;
      }

      // Check if expense is within date range and has a mood
      if (expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1))) &&
          expense.mood != null) {
        moodTotals[expense.mood!] = (moodTotals[expense.mood!] ?? 0) + expense.effectiveAmount;
      }
    }

    debugPrint('ExpenseProvider: Calculated mood expenses: ${moodTotals.toString()} for period ${start.toString()} to ${end.toString()}');
    return moodTotals;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Force reset the provider state
  void forceReset() {
    debugPrint('ExpenseProvider: Force resetting provider state');
    _isLoading = false;
    _error = null;
    _expenses = [];
    _filteredExpenses = [];
    _currentFilter = 'all';
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    _selectedMood = null;
    notifyListeners();
  }

  // Reset all expenses for a user (delete all expenses from Firestore)
  Future<bool> resetAllExpenses(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('ExpenseProvider: Resetting all expenses for user: $userId');

      // Delete all expenses from Firestore
      final success = await _expenseService.deleteAllExpenses(userId);

      if (success) {
        // Clear local expenses list
        _expenses = [];
        _filteredExpenses = [];
        debugPrint('ExpenseProvider: All expenses reset successfully');
      } else {
        _error = 'Failed to reset expenses';
        debugPrint('ExpenseProvider: Failed to reset expenses');
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('ExpenseProvider: Error resetting expenses: $e');
      _isLoading = false;
      _error = 'Error resetting expenses: $e';
      notifyListeners();
      return false;
    }
  }

  // Load group expenses
  Future<void> loadGroupExpenses(String groupId) async {
    // For now, we'll filter existing expenses
    // In a real app, you might want to add a specific query for group expenses
    debugPrint('ExpenseProvider: Loading expenses for group: $groupId');
    // The expenses are already loaded, so we don't need to do anything special here
    // Group expenses will be filtered in the UI based on participants
  }

  // Clear all data
  void clearData() {
    _expenses.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
