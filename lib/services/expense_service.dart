import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../models/debt_model.dart';
import '../services/budget_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final BudgetService _budgetService = BudgetService();

  // Add a new expense
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      // Check for potential duplicate expenses (same user, amount, category, and description)
      final now = DateTime.now();
      final tenSecondsAgo = now.subtract(const Duration(seconds: 10));

      // Convert to Timestamp for Firestore query
      final tenSecondsAgoTimestamp = Timestamp.fromDate(tenSecondsAgo);

      debugPrint('Checking for duplicates with userId: ${expense.userId}, category: ${expense.category}, amount: ${expense.amount}, description: ${expense.description}');

      // Query for recent similar expenses
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: expense.userId)
          .where('category', isEqualTo: expense.category)
          .where('amount', isEqualTo: expense.amount)
          .where('date', isGreaterThanOrEqualTo: tenSecondsAgoTimestamp)
          .get();

      // If we found a similar recent expense, check if it's a potential duplicate
      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('Found ${querySnapshot.docs.length} potential duplicates');

        for (var doc in querySnapshot.docs) {
          final existingExpense = ExpenseModel.fromDocument(doc);

          // Check if description matches too
          if (existingExpense.description == expense.description) {
            final timeDifference = now.difference(existingExpense.date).inSeconds;

            // If the expense was created in the last 10 seconds, consider it a duplicate
            if (timeDifference < 10) {
              debugPrint('Duplicate expense detected. Skipping addition. Time difference: $timeDifference seconds');
              return existingExpense;
            }
          }
        }

        debugPrint('No exact duplicates found within time window');
      }

      // Generate a unique ID for the expense
      final String id = _uuid.v4();
      final newExpense = expense.copyWith(id: id);

      await _firestore.collection('expenses').doc(id).set(newExpense.toMap());

      // If it's a group expense, create debt records
      if (newExpense.isGroupExpense && newExpense.participants.isNotEmpty) {
        await _createDebtRecords(newExpense);
      }

      // Explicitly update the budget for this expense
      try {
        await _budgetService.updateBudgetSpent(newExpense);
        debugPrint('ExpenseService: Budget updated for expense: ${newExpense.category} with amount ${newExpense.amount}');
      } catch (e) {
        debugPrint('ExpenseService: Error updating budget for expense: $e');
        // Don't rethrow - we don't want to fail the expense creation if budget update fails
      }

      return newExpense;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  // Create debt records for group expenses
  Future<void> _createDebtRecords(ExpenseModel expense) async {
    try {
      // The user who paid for the expense
      final String payerId = expense.userId;

      for (var participant in expense.participants) {
        final String participantId = participant['userId'];
        final double share = (participant['share'] as num).toDouble();

        // Skip if the participant is the payer
        if (participantId == payerId) continue;

        // Create a debt record
        final DebtModel debt = DebtModel(
          id: _uuid.v4(),
          creditorId: payerId,  // Payer is the creditor
          debtorId: participantId,  // Participant is the debtor
          amount: share,
          createdAt: expense.date,
          description: 'Share for: ${expense.description}',
          expenseId: expense.id,
          paymentMethod: PaymentMethod.other,  // Default payment method
          status: PaymentStatus.pending,  // Default status
          debtType: DebtType.groupExpense,  // Explicitly set as group expense
        );

        await _firestore.collection('debts').doc(debt.id).set(debt.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update an expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      // Get the existing expense to check if amount or category changed
      final existingExpenseDoc = await _firestore.collection('expenses').doc(expense.id).get();
      if (existingExpenseDoc.exists) {
        final existingExpense = ExpenseModel.fromDocument(existingExpenseDoc);

        // Update the expense in Firestore
        await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());

        // If amount or category changed, update the budget
        if (existingExpense.amount != expense.amount || existingExpense.category != expense.category) {
          try {
            // If category changed, we need to update both budgets
            if (existingExpense.category != expense.category) {
              // First, subtract from old category budget
              final negativeExpense = existingExpense.copyWith(amount: -existingExpense.amount);
              await _budgetService.updateBudgetSpent(negativeExpense);
              debugPrint('ExpenseService: Subtracted from old category budget: ${existingExpense.category}');

              // Then, add to new category budget
              await _budgetService.updateBudgetSpent(expense);
              debugPrint('ExpenseService: Added to new category budget: ${expense.category}');
            } else {
              // Just update the budget with the difference
              final diffAmount = expense.amount - existingExpense.amount;
              final diffExpense = expense.copyWith(amount: diffAmount);
              await _budgetService.updateBudgetSpent(diffExpense);
              debugPrint('ExpenseService: Updated budget with difference: $diffAmount');
            }
          } catch (budgetError) {
            debugPrint('ExpenseService: Error updating budget: $budgetError');
            // Don't rethrow - we don't want to fail the expense update if budget update fails
          }
        }
      } else {
        // If the expense doesn't exist, just update it
        await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());

        // And update the budget
        try {
          await _budgetService.updateBudgetSpent(expense);
          debugPrint('ExpenseService: Budget updated for new expense: ${expense.category}');
        } catch (budgetError) {
          debugPrint('ExpenseService: Error updating budget: $budgetError');
        }
      }
    } catch (e) {
      debugPrint('ExpenseService: Error updating expense: $e');
      rethrow;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Get the expense to update the budget
      final expenseDoc = await _firestore.collection('expenses').doc(expenseId).get();
      if (expenseDoc.exists) {
        final expense = ExpenseModel.fromDocument(expenseDoc);

        // First, check if there are any debts associated with this expense
        final debtsQuery = await _firestore
            .collection('debts')
            .where('expenseId', isEqualTo: expenseId)
            .get();

        // Delete associated debts
        for (var doc in debtsQuery.docs) {
          await _firestore.collection('debts').doc(doc.id).delete();
        }

        // Delete the expense
        await _firestore.collection('expenses').doc(expenseId).delete();

        // Update the budget (subtract the expense amount)
        try {
          // Create a negative expense to subtract from budget
          final negativeExpense = expense.copyWith(amount: -expense.amount);
          await _budgetService.updateBudgetSpent(negativeExpense);
          debugPrint('ExpenseService: Budget updated after deleting expense: ${expense.category}');
        } catch (budgetError) {
          debugPrint('ExpenseService: Error updating budget after deleting expense: $budgetError');
          // Don't rethrow - we don't want to fail the expense deletion if budget update fails
        }
      } else {
        // If the expense doesn't exist, just delete it
        await _firestore.collection('expenses').doc(expenseId).delete();
      }
    } catch (e) {
      debugPrint('ExpenseService: Error deleting expense: $e');
      rethrow;
    }
  }

  // Get all expenses for a user
  Stream<List<ExpenseModel>> getUserExpenses(String userId) {
    try {
      return _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .timeout(
            const Duration(seconds: 20), // Increased timeout to 20 seconds
            onTimeout: (sink) => sink.addError('Connection timeout. Please check your internet connection or try again later.'),
          )
          .handleError((error) {
            debugPrint('Expense service stream error: $error');
            return Stream.error('Failed to load expenses: $error');
          })
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => ExpenseModel.fromDocument(doc))
                  .toList();
            } catch (e) {
              debugPrint('Error parsing expense data: $e');
              throw 'Error parsing expense data: $e';
            }
          });
    } catch (e) {
      debugPrint('Failed to create expenses stream: $e');
      // Create a stream that immediately errors out
      return Stream.error('Failed to create expenses stream: $e');
    }
  }

  // Get expenses by category
  Stream<List<ExpenseModel>> getExpensesByCategory(String userId, String category) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromDocument(doc))
            .toList());
  }

  // Get expenses by date range
  Stream<List<ExpenseModel>> getExpensesByDateRange(
      String userId, DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromDocument(doc))
            .toList());
  }

  // Get expenses by mood
  Stream<List<ExpenseModel>> getExpensesByMood(String userId, String mood) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('mood', isEqualTo: mood)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromDocument(doc))
            .toList());
  }

  // Get group expenses
  Stream<List<ExpenseModel>> getGroupExpenses(String userId) {
    return _firestore
        .collection('expenses')
        .where('isGroupExpense', isEqualTo: true)
        .where('participants', arrayContains: {'userId': userId})
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromDocument(doc))
            .toList());
  }

  // Get a single expense by ID
  Future<ExpenseModel?> getExpense(String expenseId) async {
    try {
      final docSnapshot = await _firestore.collection('expenses').doc(expenseId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ExpenseModel.fromDocument(docSnapshot);
    } catch (e) {
      debugPrint('Error getting expense: $e');
      return null;
    }
  }

  // Delete all expenses for a user
  Future<bool> deleteAllExpenses(String userId) async {
    try {
      // Get all expenses for the user
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      if (expensesQuery.docs.isEmpty) {
        return true; // No expenses to delete
      }

      // Use a batch to delete all expenses
      final batch = _firestore.batch();

      // Add each expense to the batch for deletion
      for (var doc in expensesQuery.docs) {
        batch.delete(doc.reference);

        // Also delete any associated debts
        final debtsQuery = await _firestore
            .collection('debts')
            .where('expenseId', isEqualTo: doc.id)
            .get();

        for (var debtDoc in debtsQuery.docs) {
          batch.delete(debtDoc.reference);
        }
      }

      // Commit the batch
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting all expenses: $e');
      return false;
    }
  }
}
