import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/total_budget_model.dart';
import '../services/budget_service.dart';
import '../services/notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();
  final NotificationService _notificationService = NotificationService();

  List<BudgetModel> _budgets = [];
  TotalBudgetModel? _totalBudget;
  bool _isLoading = false;
  String? _error;

  List<BudgetModel> get budgets => _budgets;
  TotalBudgetModel? get totalBudget => _totalBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user budgets
  Future<void> loadUserBudgets(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // First, synchronize all budget spent amounts with actual expenses
      await _budgetService.syncAllBudgetSpentAmounts(userId);

      // Load category budgets
      _budgetService.getUserBudgets(userId).listen((budgets) {
        _budgets = budgets;
        _checkBudgetAlerts();
        _isLoading = false;
        notifyListeners();
      });

      // Load total budget
      _budgetService.getUserTotalBudget(userId).listen((totalBudget) {
        _totalBudget = totalBudget;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add a new budget
  Future<bool> addBudget(BudgetModel budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _budgetService.addBudget(budget);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update a budget
  Future<bool> updateBudget(BudgetModel budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _budgetService.updateBudget(budget);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a budget
  Future<bool> deleteBudget(String budgetId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _budgetService.deleteBudget(budgetId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check for budget alerts (private method)
  Future<void> _checkBudgetAlerts() async {
    try {
      for (var budget in _budgets) {
        if (budget.alertEnabled && (budget.isNearThreshold || budget.isOverBudget)) {
          await _notificationService.showBudgetAlert(budget);
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check for budget alerts for a specific category (public method)
  Future<BudgetModel?> checkCategoryBudgetAlert(String category) async {
    try {
      // Find the budget for this category
      final budget = getBudgetByCategory(category);

      if (budget != null && budget.alertEnabled) {
        // Don't show alerts for dynamically added categories (amount is 999999)
        final isDynamicCategory = budget.amount >= 999999;
        if (!isDynamicCategory && (budget.isNearThreshold || budget.isOverBudget)) {
          // Send notification
          await _notificationService.showBudgetAlert(budget);
          return budget;
        }
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Show in-app budget alert dialog
  void showBudgetAlertDialog(BuildContext context, String category) {
    final budget = getBudgetByCategory(category);
    if (budget != null && budget.alertEnabled) {
      // Don't show alerts for dynamically added categories (amount is 999999)
      final isDynamicCategory = budget.amount >= 999999;
      if (!isDynamicCategory && (budget.isNearThreshold || budget.isOverBudget)) {
        _notificationService.showBudgetAlertDialog(context, budget);
      }
    }
  }

  // Generate AI budget suggestions
  Future<Map<String, double>> generateBudgetSuggestions(
      String userId, List<String> categories) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final suggestions = await _budgetService.generateBudgetSuggestions(userId, categories);

      _isLoading = false;
      notifyListeners();
      return suggestions;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Get budget by category
  BudgetModel? getBudgetByCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  // Get total budget amount (excluding dynamically added categories)
  double getTotalBudgetAmount() {
    return _budgets.fold(0, (sum, budget) =>
      // Skip dynamically added categories (amount is 999999 or higher)
      budget.amount >= 999999 ? sum : sum + budget.amount
    );
  }

  // Get total spent amount (excluding dynamically added categories)
  double getTotalSpentAmount() {
    return _budgets.fold(0, (sum, budget) =>
      // Skip dynamically added categories (amount is 999999 or higher)
      budget.amount >= 999999 ? sum : sum + budget.spent
    );
  }

  // Get percentage of total budget used
  double getTotalBudgetPercentage() {
    final total = getTotalBudgetAmount();
    if (total == 0) return 0;
    return (getTotalSpentAmount() / total) * 100;
  }

  // Get list of over-budget categories
  List<BudgetModel> getOverBudgetCategories() {
    return _budgets.where((budget) => budget.isOverBudget).toList();
  }

  // Get list of near-threshold categories
  List<BudgetModel> getNearThresholdCategories() {
    return _budgets.where((budget) => budget.isNearThreshold).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Total Budget Methods

  // Add a new total budget
  Future<bool> addTotalBudget(TotalBudgetModel budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _budgetService.addTotalBudget(budget);
      _totalBudget = budget;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update a total budget
  Future<bool> updateTotalBudget(TotalBudgetModel budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _budgetService.updateTotalBudget(budget);
      _totalBudget = budget;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a total budget
  Future<bool> deleteTotalBudget(String budgetId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _budgetService.deleteTotalBudget(budgetId);
      _totalBudget = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if total budget exists
  bool hasTotalBudget() {
    return _totalBudget != null;
  }

  // Get actual total budget amount (not the sum of category budgets)
  double getActualTotalBudgetAmount() {
    return _totalBudget?.amount ?? 0.0;
  }

  // Validate if a category budget can be added/updated
  Future<bool> validateCategoryBudget(String userId, String categoryId, double categoryAmount) async {
    if (_totalBudget == null) return true; // No total budget set, so any category budget is valid

    try {
      return await _budgetService.validateCategoryBudgets(
        userId,
        _totalBudget!.amount,
        categoryId,
        categoryAmount
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reset all budgets (total and category budgets)
  Future<bool> resetAllBudgets(String userId, {bool resetSpentOnly = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      bool success;

      if (resetSpentOnly) {
        // Only reset spent amounts, keep the budgets
        debugPrint('BudgetProvider: Resetting spent amounts for all budgets');
        success = await _budgetService.resetAllBudgets(userId);

        if (success) {
          // Update local budgets list
          for (var i = 0; i < _budgets.length; i++) {
            _budgets[i] = _budgets[i].copyWith(spent: 0.0);
          }

          // Update total budget spent amount
          if (_totalBudget != null) {
            _totalBudget = _totalBudget!.copyWith(spent: 0.0);
          }

          // Synchronize budget spent amounts with actual expenses
          await _budgetService.syncAllBudgetSpentAmounts(userId);
        }
      } else {
        // Delete all category budgets
        debugPrint('BudgetProvider: Deleting all budgets');
        success = await _budgetService.deleteAllBudgets(userId);

        // Delete total budget if it exists
        if (_totalBudget != null) {
          await _budgetService.deleteTotalBudget(_totalBudget!.id);
          _totalBudget = null;
        }

        // Clear local budgets list
        _budgets = [];
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
