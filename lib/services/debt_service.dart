import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../services/budget_service.dart';
import '../services/karma_service.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Add a new debt
  Future<DebtModel> addDebt({
    required String creditorId,
    required String debtorId,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required PaymentStatus status,
    required DateTime createdAt,
    DateTime? dueDate,
    String? expenseId,
    DebtType debtType = DebtType.direct,
  }) async {
    try {
      final String id = _uuid.v4();

      // If expenseId is provided, set debtType to groupExpense
      if (expenseId != null) {
        debtType = DebtType.groupExpense;
      }

      final DebtModel newDebt = DebtModel(
        id: id,
        creditorId: creditorId,
        debtorId: debtorId,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        status: status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        dueDate: dueDate,
        expenseId: expenseId,
        debtType: debtType,
      );

      await _firestore.collection('debts').doc(id).set(newDebt.toMap());

      return newDebt;
    } catch (e) {
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<DebtModel> addDebtModel(DebtModel debt) async {
    try {
      final String id = _uuid.v4();
      final newDebt = debt.copyWith(id: id);

      await _firestore.collection('debts').doc(id).set(newDebt.toMap());

      return newDebt;
    } catch (e) {
      rethrow;
    }
  }

  // Update a debt
  Future<void> updateDebt(DebtModel debt) async {
    try {
      await _firestore.collection('debts').doc(debt.id).update(debt.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update a debt with parameters
  Future<DebtModel> updateDebtWithParams({
    required String debtId,
    required String creditorId,
    required String debtorId,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required PaymentStatus status,
    required DateTime createdAt,
    DateTime? dueDate,
    String? expenseId,
    DebtType? debtType,
  }) async {
    try {
      // Get the current debt to preserve fields if not provided
      final debtDoc = await _firestore.collection('debts').doc(debtId).get();
      final currentDebt = DebtModel.fromDocument(debtDoc);

      // Determine debt type
      DebtType finalDebtType = debtType ?? currentDebt.debtType;

      // If expenseId is provided or exists in current debt, ensure debtType is groupExpense
      final String? finalExpenseId = expenseId ?? currentDebt.expenseId;
      if (finalExpenseId != null) {
        finalDebtType = DebtType.groupExpense;
      }

      final DebtModel updatedDebt = DebtModel(
        id: debtId,
        creditorId: creditorId,
        debtorId: debtorId,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        status: status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        dueDate: dueDate,
        expenseId: finalExpenseId,
        debtType: finalDebtType,
        repayments: currentDebt.repayments,
        karmaPoints: currentDebt.karmaPoints,
      );

      await _firestore.collection('debts').doc(debtId).update(updatedDebt.toMap());

      return updatedDebt;
    } catch (e) {
      rethrow;
    }
  }

  // Update debt status
  Future<DebtModel> updateDebtStatus({
    required String debtId,
    required PaymentStatus newStatus,
  }) async {
    try {
      // Get the current debt
      final debtDoc = await _firestore.collection('debts').doc(debtId).get();
      final debt = DebtModel.fromDocument(debtDoc);

      // Calculate karma points if debt is being marked as paid
      int karmaPoints = debt.karmaPoints;
      if (debt.status == PaymentStatus.pending && newStatus == PaymentStatus.paid) {
        // Get the karma service to calculate points
        final karmaService = KarmaService();
        final newPoints = karmaService.calculateKarmaPoints(debt.createdAt, DateTime.now());
        karmaPoints = newPoints;

        // Update the user's karma in the karma collection
        await karmaService.updateKarmaForRepayment(
          debt.debtorId,
          debt.id,
          debt.createdAt,
          DateTime.now()
        );

        debugPrint('DebtService: Updated karma points for debt ${debt.id}: $newPoints points');
        debugPrint('DebtService: Debt type: ${debt.debtType}, ExpenseId: ${debt.expenseId}');
      }

      // Create updated debt with new status and karma points
      final updatedDebt = debt.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        karmaPoints: karmaPoints,
      );

      // Update in Firestore
      await _firestore.collection('debts').doc(debtId).update({
        'status': _paymentStatusToString(newStatus),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'karmaPoints': karmaPoints,
      });

      // Handle expense updates based on status change
      if (debt.expenseId != null) {
        // If changing from pending to paid
        if (debt.status == PaymentStatus.pending && newStatus == PaymentStatus.paid) {
          await _updateOriginalExpenseForPaidDebt(debt);
        }
        // If changing from paid to pending
        else if (debt.status == PaymentStatus.paid && newStatus == PaymentStatus.pending) {
          await _updateOriginalExpenseForUnpaidDebt(debt);
        }
      }

      return updatedDebt;
    } catch (e) {
      debugPrint('Error updating debt status: $e');
      rethrow;
    }
  }

  // Update the original expense when a debt is paid
  Future<void> _updateOriginalExpenseForPaidDebt(DebtModel debt) async {
    try {
      // Only proceed if this debt is associated with an expense
      if (debt.expenseId == null) return;

      // Get the original expense
      final expenseDoc = await _firestore.collection('expenses').doc(debt.expenseId).get();
      if (!expenseDoc.exists) return;

      final expense = ExpenseModel.fromDocument(expenseDoc);

      // Only update group expenses
      if (!expense.isGroupExpense) return;

      // If the current user is the creditor (they paid for the expense),
      // we DO NOT reduce the expense amount anymore - we just add a payment note
      if (debt.creditorId == expense.userId) {
        // Create a transaction record to reflect the payment
        final transactionDescription = 'Payment received for: ${expense.description}';

        // Update the expense with payment notes only, NOT changing the original amount
        await _firestore.collection('expenses').doc(expense.id).update({
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'paymentNotes': FieldValue.arrayUnion([{
            'amount': debt.amount,
            'date': Timestamp.fromDate(DateTime.now()),
            'description': transactionDescription,
            'payerId': debt.debtorId,
          }]),
        });

        // Get the debtor's name from Firestore
        String debtorName = "Friend";
        try {
          final debtorDoc = await _firestore.collection('users').doc(debt.debtorId).get();
          if (debtorDoc.exists) {
            debtorName = debtorDoc.data()?['name'] ?? "Friend";
          }
        } catch (e) {
          debugPrint('Error getting debtor name: $e');
        }

        // Also create a negative expense to reflect the reimbursement
        // This will show up in the expense list and reduce the total expenses
        // Use the original expense's category to ensure the budget for that category is updated
        final reimbursementExpense = ExpenseModel(
          id: '',  // Will be set by the service
          userId: debt.creditorId,  // The person who received the payment
          category: expense.category,  // Use original expense category to update that category's budget
          description: '$debtorName paid back: ${debt.description}',
          amount: -debt.amount,  // Negative amount to reduce total expenses
          date: DateTime.now(),
          isGroupExpense: false,
          isReimbursement: true,  // Mark as reimbursement to show in Splits tab
          participants: [],
        );

        debugPrint('DebtService: Creating reimbursement expense for ${expense.category} with amount ${-debt.amount}');

        // Add the reimbursement expense to Firestore
        final reimbursementRef = _firestore.collection('expenses').doc();
        await reimbursementRef.set(reimbursementExpense.toMap());
        debugPrint('DebtService: Created reimbursement expense with ID ${reimbursementRef.id}');

        // Explicitly update the budget for this reimbursement
        try {
          // Get the budget service to update the budget
          final budgetService = BudgetService();
          await budgetService.updateBudgetSpent(reimbursementExpense);
          debugPrint('DebtService: Budget updated for reimbursement');
        } catch (e) {
          debugPrint('DebtService: Error updating budget for reimbursement: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating original expense: $e');
      // Don't rethrow - we don't want to fail the debt status update
      // if the expense update fails
    }
  }

  // Update the original expense when a debt is marked as unpaid after being paid
  Future<void> _updateOriginalExpenseForUnpaidDebt(DebtModel debt) async {
    try {
      // Only proceed if this debt is associated with an expense
      if (debt.expenseId == null) return;

      // Get the original expense
      final expenseDoc = await _firestore.collection('expenses').doc(debt.expenseId).get();
      if (!expenseDoc.exists) return;

      final expense = ExpenseModel.fromDocument(expenseDoc);

      // Only update group expenses
      if (!expense.isGroupExpense) return;

      // If the current user is the creditor (they paid for the expense),
      // we DO NOT change the expense amount - just add a payment note for the reversal
      if (debt.creditorId == expense.userId) {
        // Create a transaction record to reflect the reversal
        final transactionDescription = 'Payment reversed for: ${expense.description}';

        // Update the expense with payment notes only, NOT changing the original amount
        await _firestore.collection('expenses').doc(expense.id).update({
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'paymentNotes': FieldValue.arrayUnion([{
            'amount': -debt.amount, // Negative to indicate reversal
            'date': Timestamp.fromDate(DateTime.now()),
            'description': transactionDescription,
            'payerId': debt.debtorId,
          }]),
        });

        // Get the debtor's name from Firestore
        String debtorName = "Friend";
        try {
          final debtorDoc = await _firestore.collection('users').doc(debt.debtorId).get();
          if (debtorDoc.exists) {
            debtorName = debtorDoc.data()?['name'] ?? "Friend";
          }
        } catch (e) {
          debugPrint('Error getting debtor name: $e');
        }

        // Also create a positive expense to reflect the reversal of reimbursement
        // This will show up in the expense list and increase the total expenses
        final reversalExpense = ExpenseModel(
          id: '',  // Will be set by the service
          userId: debt.creditorId,  // The person who received the payment
          category: expense.category,  // Use original expense category to update that category's budget
          description: 'Reversed payment from $debtorName for: ${debt.description}',
          amount: debt.amount,  // Positive amount to increase total expenses
          date: DateTime.now(),
          isGroupExpense: false,
          isReimbursement: true,  // Mark as reimbursement to show in Splits tab
          participants: [],
        );

        debugPrint('DebtService: Creating reversal expense for ${expense.category} with amount ${debt.amount}');

        // Add the reversal expense to Firestore
        final reversalRef = _firestore.collection('expenses').doc();
        await reversalRef.set(reversalExpense.toMap());
        debugPrint('DebtService: Created reversal expense with ID ${reversalRef.id}');

        // Explicitly update the budget for this reversal
        try {
          // Get the budget service to update the budget
          final budgetService = BudgetService();
          await budgetService.updateBudgetSpent(reversalExpense);
          debugPrint('DebtService: Budget updated for reversal');
        } catch (e) {
          debugPrint('DebtService: Error updating budget for reversal: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating original expense for unpaid debt: $e');
      // Don't rethrow - we don't want to fail the debt status update
      // if the expense update fails
    }
  }

  // Helper method to convert PaymentStatus to string
  String _paymentStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.verifying:
        return 'verifying';
    }
  }

  // Delete a debt
  Future<void> deleteDebt(String debtId) async {
    try {
      await _firestore.collection('debts').doc(debtId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Add a repayment to a debt
  Future<void> addRepayment(String debtId, double amount, DateTime date) async {
    try {
      // Get the current debt
      final debtDoc = await _firestore.collection('debts').doc(debtId).get();
      final debt = DebtModel.fromDocument(debtDoc);

      // Create a new repayment
      final repayment = {
        'amount': amount,
        'date': Timestamp.fromDate(date),
      };

      // Add the repayment to the list
      final updatedRepayments = List<Map<String, dynamic>>.from(debt.repayments)
        ..add(repayment);

      // Calculate remaining amount
      final double totalRepaid = updatedRepayments.fold(
          0, (total, item) => total + (item['amount'] as num).toDouble());

      // Update debt status
      String newStatus;
      if (totalRepaid >= debt.amount) {
        newStatus = 'paid';
      } else if (totalRepaid > 0) {
        newStatus = 'partially_paid';
      } else {
        newStatus = 'pending';
      }

      // Calculate karma points based on repayment speed
      int karmaPoints = debt.karmaPoints;
      if (newStatus == 'paid') {
        // Get the karma service to calculate points
        final karmaService = KarmaService();
        final newPoints = karmaService.calculateKarmaPoints(debt.createdAt, date);
        karmaPoints = newPoints;

        // Update the user's karma in the karma collection
        await karmaService.updateKarmaForRepayment(
          debt.debtorId,
          debt.id,
          debt.createdAt,
          date
        );
      }

      // Update the debt
      await _firestore.collection('debts').doc(debtId).update({
        'repayments': updatedRepayments,
        'status': newStatus,
        'karmaPoints': karmaPoints,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all debts where user is the creditor (lender)
  Stream<List<DebtModel>> getLentDebts(String userId) {
    return _firestore
        .collection('debts')
        .where('creditorId', isEqualTo: userId)
        // Remove the orderBy to avoid needing a complex index
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DebtModel.fromDocument(doc))
            .toList());
  }

  // Get all debts where user is the debtor (borrower)
  Stream<List<DebtModel>> getBorrowedDebts(String userId) {
    return _firestore
        .collection('debts')
        .where('debtorId', isEqualTo: userId)
        // Remove the orderBy to avoid needing a complex index
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DebtModel.fromDocument(doc))
            .toList());
  }

  // Get all debts between two users
  Future<List<DebtModel>> getDebtsBetweenUsers(String userId1, String userId2) async {
    try {
      debugPrint('DebtService: Getting debts between $userId1 and $userId2');

      // Get all debts where either user is involved
      final allDebtsQuery = await _firestore
          .collection('debts')
          .get();

      // Filter the results manually to find debts between these two users
      final allDebts = allDebtsQuery.docs.map((doc) => DebtModel.fromDocument(doc)).toList();

      // Filter to only include debts between these two users
      final filteredDebts = allDebts.where((debt) =>
        (debt.creditorId == userId1 && debt.debtorId == userId2) ||
        (debt.creditorId == userId2 && debt.debtorId == userId1)
      ).toList();

      debugPrint('DebtService: Found ${filteredDebts.length} debts between users');

      // For debugging
      for (var debt in filteredDebts) {
        debugPrint('Debt: ${debt.id}, Amount: ${debt.amount}, Creditor: ${debt.creditorId}, Debtor: ${debt.debtorId}, ExpenseId: ${debt.expenseId}');
      }

      // Sort by date (newest first)
      filteredDebts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filteredDebts;
    } catch (e) {
      rethrow;
    }
  }

  // Get direct transaction debts between two users (not from group expenses)
  Future<List<DebtModel>> getDirectDebtsBetweenUsers(String userId1, String userId2) async {
    try {
      final allDebts = await getDebtsBetweenUsers(userId1, userId2);

      // Filter to only include direct debts
      final directDebts = allDebts.where((debt) => debt.debtType == DebtType.direct).toList();

      debugPrint('DebtService: Found ${directDebts.length} direct debts between users');

      return directDebts;
    } catch (e) {
      rethrow;
    }
  }

  // Get group expense debts between two users
  Future<List<DebtModel>> getGroupExpenseDebtsBetweenUsers(String userId1, String userId2) async {
    try {
      final allDebts = await getDebtsBetweenUsers(userId1, userId2);

      // Filter to only include group expense debts
      final groupDebts = allDebts.where((debt) => debt.debtType == DebtType.groupExpense).toList();

      debugPrint('DebtService: Found ${groupDebts.length} group expense debts between users');

      return groupDebts;
    } catch (e) {
      rethrow;
    }
  }

  // Calculate net balance between two users
  Future<double> getNetBalance(String userId1, String userId2) async {
    try {
      // Get all debts between these two users
      final debts = await getDebtsBetweenUsers(userId1, userId2);

      // Calculate total amount userId2 owes userId1
      double amountOwedToUser1 = 0;
      // Calculate total amount userId1 owes userId2
      double amountOwedToUser2 = 0;

      for (var debt in debts) {
        // Skip paid debts
        if (debt.status == PaymentStatus.paid) {
          continue;
        }

        if (debt.creditorId == userId1 && debt.debtorId == userId2) {
          // User2 owes User1
          amountOwedToUser1 += debt.remainingAmount;
        } else if (debt.creditorId == userId2 && debt.debtorId == userId1) {
          // User1 owes User2
          amountOwedToUser2 += debt.remainingAmount;
        }
      }

      // Return the net balance (positive if userId2 owes userId1, negative if userId1 owes userId2)
      return amountOwedToUser1 - amountOwedToUser2;
    } catch (e) {
      rethrow;
    }
  }

  // Clear all transaction history between two users
  Future<bool> clearTransactionHistory(String userId1, String userId2) async {
    try {
      debugPrint('DebtService: Clearing transaction history between $userId1 and $userId2');

      // Get all debts between the two users (both direct and group expense debts)
      final allDebts = await getDebtsBetweenUsers(userId1, userId2);
      final directDebts = await getDirectDebtsBetweenUsers(userId1, userId2);
      final groupExpenseDebts = await getGroupExpenseDebtsBetweenUsers(userId1, userId2);

      // Combine all debt types to ensure we don't miss any
      final Set<String> debtIds = {};
      for (var debt in [...allDebts, ...directDebts, ...groupExpenseDebts]) {
        debtIds.add(debt.id);
      }

      debugPrint('DebtService: Found ${debtIds.length} total debts to delete');

      // Delete each debt
      for (var debtId in debtIds) {
        try {
          await _firestore.collection('debts').doc(debtId).delete();
          debugPrint('DebtService: Deleted debt $debtId');
        } catch (e) {
          debugPrint('DebtService: Error deleting debt $debtId: $e');
          // Continue with other debts even if one fails
        }
      }

      // Also clear any related expense payment notes between these users
      try {
        // Query for expenses that might have payment notes involving these users
        final expenseQuery1 = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: userId1)
            .get();

        final expenseQuery2 = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: userId2)
            .get();

        // Process expenses from both users
        for (var doc in [...expenseQuery1.docs, ...expenseQuery2.docs]) {
          final data = doc.data();
          final paymentNotes = data['paymentNotes'] as List<dynamic>?;

          if (paymentNotes != null && paymentNotes.isNotEmpty) {
            // Filter out payment notes involving the removed friend
            final filteredNotes = paymentNotes.where((note) {
              final payerId = note['payerId'] as String?;
              return payerId != userId1 && payerId != userId2;
            }).toList();

            // Update the expense if payment notes were removed
            if (filteredNotes.length != paymentNotes.length) {
              await doc.reference.update({'paymentNotes': filteredNotes});
              debugPrint('DebtService: Cleaned payment notes for expense ${doc.id}');
            }
          }
        }
      } catch (e) {
        debugPrint('DebtService: Error cleaning expense payment notes: $e');
        // Don't fail the entire operation for this
      }

      debugPrint('DebtService: Successfully cleared all transaction history');
      return true;
    } catch (e) {
      debugPrint('DebtService: Error clearing transaction history: $e');
      return false;
    }
  }
}
