import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/total_budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Add a new budget
  Future<BudgetModel> addBudget(BudgetModel budget) async {
    try {
      final String id = _uuid.v4();
      final newBudget = budget.copyWith(id: id);

      await _firestore.collection('budgets').doc(id).set(newBudget.toMap());

      return newBudget;
    } catch (e) {
      rethrow;
    }
  }

  // Update a budget
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      await _firestore.collection('budgets').doc(budget.id).update(budget.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _firestore.collection('budgets').doc(budgetId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get all budgets for a user
  Stream<List<BudgetModel>> getUserBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromDocument(doc))
            .toList());
  }

  // Get budget by category
  Stream<BudgetModel?> getBudgetByCategory(String userId, String category) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return BudgetModel.fromDocument(snapshot.docs.first);
        });
  }

  // Update budget spent amount based on new expense
  Future<void> updateBudgetSpent(ExpenseModel expense) async {
    try {
      debugPrint('BudgetService: Updating budget for category ${expense.category} with amount ${expense.amount}');

      // Find the budget for this category
      final budgetQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: expense.userId)
          .where('category', isEqualTo: expense.category)
          .get();

      if (budgetQuery.docs.isEmpty) {
        // No budget for this category - create one automatically with no limit
        debugPrint('BudgetService: No budget found for category ${expense.category}, creating default budget');
        await _createDefaultCategoryBudget(expense.userId, expense.category, expense.amount);
        return;
      }

      final budgetDoc = budgetQuery.docs.first;
      final budget = BudgetModel.fromDocument(budgetDoc);
      debugPrint('BudgetService: Found budget for ${expense.category}: current spent ${budget.spent}, limit ${budget.amount}');

      // Check if expense date is within budget period
      if (expense.date.isBefore(budget.startDate) ||
          expense.date.isAfter(budget.endDate)) {
        debugPrint('BudgetService: Expense date is outside budget period, skipping update');
        return; // Expense is outside budget period
      }

      // Update the spent amount
      // For reimbursements (negative amounts), we need to subtract from the budget spent
      final newSpent = budget.spent + expense.amount;
      debugPrint('BudgetService: Updating spent amount from ${budget.spent} to $newSpent');

      // Ensure we don't go below zero
      final finalSpent = newSpent < 0 ? 0.0 : newSpent;

      await _firestore.collection('budgets').doc(budget.id).update({
        'spent': finalSpent,
      });

      // Also update the total budget spent amount
      await updateTotalBudgetSpent(expense);

      debugPrint('BudgetService: Budget updated successfully');
    } catch (e) {
      debugPrint('BudgetService: Error updating budget: $e');
      rethrow;
    }
  }

  // Update total budget spent amount based on new expense
  Future<void> updateTotalBudgetSpent(ExpenseModel expense) async {
    try {
      debugPrint('BudgetService: Updating total budget with amount ${expense.amount}');

      // Skip direct debt transactions for budget tracking
      if (expense.isDirectDebt) {
        debugPrint('BudgetService: Skipping direct debt transaction for budget tracking');
        return;
      }

      // Find the total budget for this user
      final totalBudgetQuery = await _firestore
          .collection('total_budgets')
          .where('userId', isEqualTo: expense.userId)
          .limit(1)
          .get();

      if (totalBudgetQuery.docs.isEmpty) {
        debugPrint('BudgetService: No total budget found, skipping update');
        return; // No total budget to update
      }

      final totalBudgetDoc = totalBudgetQuery.docs.first;
      final totalBudget = TotalBudgetModel.fromDocument(totalBudgetDoc);
      debugPrint('BudgetService: Found total budget: current spent ${totalBudget.spent}, limit ${totalBudget.amount}');

      // Check if expense date is within budget period
      // For now, we'll include all expenses regardless of date to ensure the dashboard shows correct totals
      // We can add date filtering back if needed in the future
      /*
      if (expense.date.isBefore(totalBudget.startDate) ||
          expense.date.isAfter(totalBudget.endDate)) {
        debugPrint('BudgetService: Expense date is outside total budget period, skipping update');
        return; // Expense is outside budget period
      }
      */

      // Update the spent amount
      final newSpent = totalBudget.spent + expense.amount;
      debugPrint('BudgetService: Updating total spent amount from ${totalBudget.spent} to $newSpent');

      // Ensure we don't go below zero
      final finalSpent = newSpent < 0 ? 0.0 : newSpent;

      await _firestore.collection('total_budgets').doc(totalBudget.id).update({
        'spent': finalSpent,
      });

      debugPrint('BudgetService: Total budget updated successfully');
    } catch (e) {
      debugPrint('BudgetService: Error updating total budget: $e');
      // Don't rethrow - we don't want to fail the category budget update if total budget update fails
    }
  }

  // Synchronize all budget spent amounts with actual expenses
  Future<void> syncAllBudgetSpentAmounts(String userId) async {
    try {
      debugPrint('BudgetService: Synchronizing all budget spent amounts for user $userId');

      // Get all expenses for the user
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      final expenses = expensesQuery.docs.map((doc) => ExpenseModel.fromDocument(doc)).toList();
      debugPrint('BudgetService: Found ${expenses.length} expenses');

      // Get all category budgets for the user
      final budgetsQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      // Get total budget for the user
      final totalBudgetQuery = await _firestore
          .collection('total_budgets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      // Reset all category budgets to zero
      final batch = _firestore.batch();

      for (var budgetDoc in budgetsQuery.docs) {
        batch.update(budgetDoc.reference, {'spent': 0.0});
      }

      // Reset total budget to zero if it exists
      TotalBudgetModel? totalBudget;
      if (totalBudgetQuery.docs.isNotEmpty) {
        final totalBudgetDoc = totalBudgetQuery.docs.first;
        totalBudget = TotalBudgetModel.fromDocument(totalBudgetDoc);
        batch.update(totalBudgetDoc.reference, {'spent': 0.0});
      }

      // Commit the batch to reset all spent amounts
      await batch.commit();
      debugPrint('BudgetService: Reset all budget spent amounts to zero');

      // Now recalculate spent amounts for each category based on expenses
      Map<String, double> categorySpent = {};
      double totalSpent = 0.0;

      // Process each expense
      for (var expense in expenses) {
        // Skip direct debt transactions for budget tracking
        if (expense.isDirectDebt) {
          continue;
        }

        // Skip expenses outside the budget period - commented out for now to match updateTotalBudgetSpent behavior
        /*
        if (totalBudget != null && (
            expense.date.isBefore(totalBudget.startDate) ||
            expense.date.isAfter(totalBudget.endDate))) {
          continue;
        }
        */

        // Add to category total
        categorySpent[expense.category] = (categorySpent[expense.category] ?? 0.0) + expense.amount;

        // Add to total spent
        totalSpent += expense.amount;
      }

      // Update each category budget
      for (var category in categorySpent.keys) {
        final amount = categorySpent[category] ?? 0.0;
        if (amount <= 0) continue; // Skip if zero or negative

        // Find the budget for this category
        final budgetQuery = await _firestore
            .collection('budgets')
            .where('userId', isEqualTo: userId)
            .where('category', isEqualTo: category)
            .get();

        if (budgetQuery.docs.isEmpty) {
          // Create a default budget for this category
          await _createDefaultCategoryBudget(userId, category, amount);
        } else {
          // Update the existing budget
          await _firestore.collection('budgets').doc(budgetQuery.docs.first.id).update({
            'spent': amount,
          });
        }

        debugPrint('BudgetService: Updated budget for $category with spent amount $amount');
      }

      // Update total budget spent amount
      if (totalBudget != null) {
        await _firestore.collection('total_budgets').doc(totalBudget.id).update({
          'spent': totalSpent > 0 ? totalSpent : 0.0,
        });
        debugPrint('BudgetService: Updated total budget with spent amount $totalSpent');
      }

      debugPrint('BudgetService: Successfully synchronized all budget spent amounts');
    } catch (e) {
      debugPrint('BudgetService: Error synchronizing budget spent amounts: $e');
      rethrow;
    }
  }

  // Create a default category budget when a new category is used in an expense
  Future<BudgetModel> _createDefaultCategoryBudget(String userId, String category, double initialSpent) async {
    try {
      // Get the current month's start and end dates
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Create a new budget with a high amount (effectively no limit)
      final budget = BudgetModel(
        id: '', // Will be set in addBudget
        userId: userId,
        category: category,
        amount: 999999, // Very high amount (no practical limit)
        period: 'monthly', // Default to monthly
        startDate: startDate,
        endDate: endDate,
        spent: initialSpent,
        alertEnabled: false, // No alerts by default
        alertThreshold: 80, // Default threshold
      );

      // Add the budget
      return await addBudget(budget);
    } catch (e) {
      rethrow;
    }
  }

  // Reset all budgets for a user (set spent amount to 0)
  Future<bool> resetAllBudgets(String userId) async {
    try {
      // Get all budgets for the user
      final budgetsQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      // Get total budget for the user
      final totalBudgetQuery = await _firestore
          .collection('total_budgets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      // Use a batch to update all budgets
      final batch = _firestore.batch();

      // Reset spent amount to 0 for each category budget
      if (budgetsQuery.docs.isNotEmpty) {
        for (var doc in budgetsQuery.docs) {
          batch.update(doc.reference, {'spent': 0.0});
        }
      }

      // Reset spent amount to 0 for total budget if it exists
      if (totalBudgetQuery.docs.isNotEmpty) {
        batch.update(totalBudgetQuery.docs.first.reference, {'spent': 0.0});
      }

      // Commit the batch
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error resetting all budgets: $e');
      return false;
    }
  }

  // Check if any budgets are near or over threshold
  Future<List<BudgetModel>> checkBudgetAlerts(String userId) async {
    try {
      final budgetsQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('alertEnabled', isEqualTo: true)
          .get();

      final alertBudgets = <BudgetModel>[];

      for (var doc in budgetsQuery.docs) {
        final budget = BudgetModel.fromDocument(doc);

        // Check if budget is near or over threshold
        if (budget.isNearThreshold || budget.isOverBudget) {
          alertBudgets.add(budget);
        }
      }

      return alertBudgets;
    } catch (e) {
      rethrow;
    }
  }

  // Generate AI budget suggestions based on past expenses
  Future<Map<String, double>> generateBudgetSuggestions(
      String userId, List<String> categories) async {
    try {
      final suggestions = <String, double>{};

      // For each category, analyze past 3 months of expenses
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      for (var category in categories) {
        final expensesQuery = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: userId)
            .where('category', isEqualTo: category)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo))
            .get();

        if (expensesQuery.docs.isEmpty) {
          suggestions[category] = 0.0;
          continue;
        }

        // Calculate average monthly spending
        double totalSpent = 0;
        for (var doc in expensesQuery.docs) {
          final expense = ExpenseModel.fromDocument(doc);
          totalSpent += expense.amount;
        }

        // Add 10% buffer to the average
        final averageMonthly = totalSpent / 3;
        final suggestedBudget = averageMonthly * 1.1;

        suggestions[category] = suggestedBudget;
      }

      return suggestions;
    } catch (e) {
      rethrow;
    }
  }

  // Total Budget Methods

  // Add a new total budget
  Future<TotalBudgetModel> addTotalBudget(TotalBudgetModel budget) async {
    try {
      final String id = _uuid.v4();
      final newBudget = budget.copyWith(id: id);

      await _firestore.collection('total_budgets').doc(id).set(newBudget.toMap());

      return newBudget;
    } catch (e) {
      rethrow;
    }
  }

  // Update a total budget
  Future<void> updateTotalBudget(TotalBudgetModel budget) async {
    try {
      await _firestore.collection('total_budgets').doc(budget.id).update(budget.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete a total budget
  Future<void> deleteTotalBudget(String budgetId) async {
    try {
      await _firestore.collection('total_budgets').doc(budgetId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get total budget for a user
  Stream<TotalBudgetModel?> getUserTotalBudget(String userId) {
    return _firestore
        .collection('total_budgets')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return TotalBudgetModel.fromDocument(snapshot.docs.first);
        });
  }

  // Validate if category budgets exceed total budget
  Future<bool> validateCategoryBudgets(String userId, double totalBudgetAmount, String categoryId, double categoryAmount) async {
    try {
      // Get all category budgets except the one being updated
      final budgetsQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      double totalCategoryBudgets = 0;

      for (var doc in budgetsQuery.docs) {
        final budget = BudgetModel.fromDocument(doc);
        // Skip the category being updated
        if (budget.id == categoryId) continue;

        // Skip dynamically added categories (amount is 999999 or higher)
        if (budget.amount >= 999999) continue;

        totalCategoryBudgets += budget.amount;
      }

      // Add the new category amount if it's not a dynamic category
      if (categoryAmount < 999999) {
        totalCategoryBudgets += categoryAmount;
      }

      // Check if total category budgets exceed total budget
      debugPrint('BudgetService: Total category budgets: $totalCategoryBudgets, Total budget: $totalBudgetAmount');
      return totalCategoryBudgets <= totalBudgetAmount;
    } catch (e) {
      rethrow;
    }
  }

  // Delete all budgets for a user
  Future<bool> deleteAllBudgets(String userId) async {
    try {
      // Get all category budgets for the user
      final budgetsQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      // Delete each budget in a batch
      final batch = _firestore.batch();
      for (var doc in budgetsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
