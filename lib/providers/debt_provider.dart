import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../services/debt_service.dart';
import '../services/expense_service.dart';
import '../services/notification_service.dart';
import '../services/budget_service.dart';

class DebtProvider extends ChangeNotifier {
  final DebtService _debtService = DebtService();
  final ExpenseService _expenseService = ExpenseService();
  final NotificationService _notificationService = NotificationService();
  final BudgetService _budgetService = BudgetService();

  List<DebtModel> _lentDebts = [];
  List<DebtModel> _borrowedDebts = [];
  List<DebtModel> _friendDebts = []; // Debts between current user and selected friend
  List<DebtModel> _directFriendDebts = []; // Direct transaction debts between current user and selected friend
  List<DebtModel> _groupExpenseFriendDebts = []; // Group expense debts between current user and selected friend
  bool _isLoading = false;
  String? _error;
  String? _selectedFriendId;

  List<DebtModel> get lentDebts => _lentDebts;
  List<DebtModel> get borrowedDebts => _borrowedDebts;
  List<DebtModel> get friendDebts => _friendDebts;
  List<DebtModel> get directFriendDebts => _directFriendDebts;
  List<DebtModel> get groupExpenseFriendDebts => _groupExpenseFriendDebts;
  List<DebtModel> get debts => _friendDebts; // Alias for friendDebts to match FriendDetailScreen
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedFriendId => _selectedFriendId;

  // Load user's lent debts
  Future<void> loadLentDebts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _debtService.getLentDebts(userId).listen((debts) {
        _lentDebts = debts;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load user's borrowed debts
  Future<void> loadBorrowedDebts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _debtService.getBorrowedDebts(userId).listen((debts) {
        _borrowedDebts = debts;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load all debts between user and friend
  Future<void> loadFriendDebts(String userId, String friendId) async {
    _isLoading = true;
    _selectedFriendId = friendId;
    notifyListeners();

    try {
      // Load all debts
      final debts = await _debtService.getDebtsBetweenUsers(userId, friendId);
      _friendDebts = debts;

      // Load direct transaction debts
      final directDebts = await _debtService.getDirectDebtsBetweenUsers(userId, friendId);
      _directFriendDebts = directDebts;

      // Load group expense debts
      final groupDebts = await _debtService.getGroupExpenseDebtsBetweenUsers(userId, friendId);
      _groupExpenseFriendDebts = groupDebts;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Alias for loadFriendDebts to match the method name used in FriendDetailScreen
  Future<void> loadDebtsBetweenUsers(String userId, String friendId) async {
    return loadFriendDebts(userId, friendId);
  }

  // Load only direct transaction debts between user and friend
  Future<void> loadDirectFriendDebts(String userId, String friendId) async {
    _isLoading = true;
    _selectedFriendId = friendId;
    notifyListeners();

    try {
      final directDebts = await _debtService.getDirectDebtsBetweenUsers(userId, friendId);
      _directFriendDebts = directDebts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load only group expense debts between user and friend
  Future<void> loadGroupExpenseFriendDebts(String userId, String friendId) async {
    _isLoading = true;
    _selectedFriendId = friendId;
    notifyListeners();

    try {
      final groupDebts = await _debtService.getGroupExpenseDebtsBetweenUsers(userId, friendId);
      _groupExpenseFriendDebts = groupDebts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add a new debt
  Future<bool> addDebt(DebtModel debt) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newDebt = await _debtService.addDebtModel(debt);

      // Schedule reminder if due date is set
      if (newDebt.dueDate != null) {
        await _notificationService.scheduleDebtReminder(newDebt);
      }

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

  // Add a new debt with parameters
  Future<bool> addDebtWithParams({
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newDebt = await _debtService.addDebt(
        creditorId: creditorId,
        debtorId: debtorId,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        status: status,
        createdAt: createdAt,
        dueDate: dueDate,
        expenseId: expenseId,
        debtType: debtType,
      );

      // Schedule reminder if due date is set
      if (newDebt.dueDate != null) {
        await _notificationService.scheduleDebtReminder(newDebt);
      }

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

  // Update a debt
  Future<bool> updateDebt(DebtModel debt) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use the original updateDebt method that takes a DebtModel
      await _debtService.updateDebt(debt);

      // Cancel existing reminders and schedule new ones if due date is set
      await _notificationService.cancelDebtReminders(debt);
      if (debt.dueDate != null) {
        await _notificationService.scheduleDebtReminder(debt);
      }

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

  // Update a debt with parameters
  Future<bool> updateDebtWithParams({
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
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedDebt = await _debtService.updateDebtWithParams(
        debtId: debtId,
        creditorId: creditorId,
        debtorId: debtorId,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        status: status,
        createdAt: createdAt,
        dueDate: dueDate,
        expenseId: expenseId,
        debtType: debtType,
      );

      // Cancel existing reminders and schedule new ones if due date is set
      await _notificationService.cancelDebtReminders(updatedDebt);
      if (updatedDebt.dueDate != null) {
        await _notificationService.scheduleDebtReminder(updatedDebt);
      }

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

  // Delete a debt
  Future<bool> deleteDebt(String debtId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Find the debt to cancel reminders
      DebtModel? debt;
      try {
        debt = _lentDebts.firstWhere((d) => d.id == debtId);
      } catch (_) {
        try {
          debt = _borrowedDebts.firstWhere((d) => d.id == debtId);
        } catch (_) {
          try {
            debt = _friendDebts.firstWhere((d) => d.id == debtId);
          } catch (_) {
            // Debt not found in any list
          }
        }
      }

      if (debt != null) {
        await _notificationService.cancelDebtReminders(debt);
      }

      await _debtService.deleteDebt(debtId);

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

  // Add a repayment
  Future<bool> addRepayment(String debtId, double amount, DateTime date) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _debtService.addRepayment(debtId, amount, date);

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

  // Get total amount lent (only pending debts, all types)
  double getTotalLent() {
    return _lentDebts
        .where((debt) => debt.status == PaymentStatus.pending)
        .fold(0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get total amount borrowed (only pending debts, all types)
  double getTotalBorrowed() {
    return _borrowedDebts
        .where((debt) => debt.status == PaymentStatus.pending)
        .fold(0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get total amount lent for direct debts only
  double getTotalDirectLent() {
    return _lentDebts
        .where((debt) =>
            debt.status == PaymentStatus.pending &&
            debt.debtType == DebtType.direct)
        .fold(0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get total amount borrowed for direct debts only
  double getTotalDirectBorrowed() {
    return _borrowedDebts
        .where((debt) =>
            debt.status == PaymentStatus.pending &&
            debt.debtType == DebtType.direct)
        .fold(0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get total amount lent for group expenses only
  double getTotalGroupExpenseLent() {
    return _lentDebts
        .where((debt) =>
            debt.status == PaymentStatus.pending &&
            debt.debtType == DebtType.groupExpense)
        .fold(0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get total amount borrowed for group expenses only
  double getTotalGroupExpenseBorrowed() {
    return _borrowedDebts
        .where((debt) =>
            debt.status == PaymentStatus.pending &&
            debt.debtType == DebtType.groupExpense)
        .fold(0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get net balance for group expenses
  double getGroupExpenseNetBalance() {
    return getTotalGroupExpenseLent() - getTotalGroupExpenseBorrowed();
  }

  // Get net balance for direct debts
  double getDirectDebtNetBalance() {
    return getTotalDirectLent() - getTotalDirectBorrowed();
  }

  // Get net balance with a friend
  Future<double> getNetBalance(String userId, String friendId) async {
    try {
      return await _debtService.getNetBalance(userId, friendId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // Clear all transaction history with a friend
  Future<bool> clearTransactionHistory(String userId, String friendId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _debtService.clearTransactionHistory(userId, friendId);

      if (success) {
        // Clear local lists
        _friendDebts = [];
        _directFriendDebts = [];
        _groupExpenseFriendDebts = [];

        // Reload lent and borrowed debts to keep them in sync
        loadLentDebts(userId);
        loadBorrowedDebts(userId);
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

  // Update debt status
  Future<bool> updateDebtStatus({
    required String debtId,
    required PaymentStatus newStatus,
    UserModel? friend,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('DebtProvider: Updating debt status to ${newStatus.toString()}');

      final updatedDebt = await _debtService.updateDebtStatus(
        debtId: debtId,
        newStatus: newStatus,
      );

      // Update the debt in the local lists
      _updateDebtInLists(updatedDebt);

      // If the debt is being marked as paid and it's not associated with an expense,
      // create a new expense to track this payment
      if (newStatus == PaymentStatus.paid && updatedDebt.expenseId == null && friend != null) {
        await _createExpenseFromDebtPayment(updatedDebt, friend);
      }

      // Force a reload of all debts to ensure everything is in sync
      if (_selectedFriendId != null) {
        // We'll reload the debts in the next UI cycle
        Future.delayed(const Duration(milliseconds: 100), () {
          loadFriendDebts(_selectedFriendId!, _selectedFriendId!);
        });
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DebtProvider: Error updating debt status: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Create an expense record from a debt payment
  Future<void> _createExpenseFromDebtPayment(DebtModel debt, UserModel friend) async {
    try {
      if (debt.debtorId == debt.creditorId) return; // Skip if it's a self-debt

      // Try to get the original expense category if this is a group expense
      String? originalCategory;
      if (debt.expenseId != null && debt.debtType == DebtType.groupExpense) {
        try {
          final expenseDoc = await _expenseService.getExpense(debt.expenseId!);
          if (expenseDoc != null) {
            originalCategory = expenseDoc.category;
          }
        } catch (e) {
          debugPrint('DebtProvider: Error getting original expense: $e');
        }
      }

      // If this is a payment from the debtor
      {
        final String category = 'Friends';
        final String description = 'Payment to ${friend.name}: ${debt.description}';

        // Create a new expense for this payment
        final expense = ExpenseModel(
          id: '', // Will be set by the service
          userId: debt.debtorId, // The person who paid (debtor)
          category: category,
          description: description,
          amount: debt.amount,
          date: DateTime.now(),
          isGroupExpense: false,
          isDirectDebt: debt.debtType == DebtType.direct, // Mark as direct debt if it's a direct debt
          participants: [],
        );

        // Add the expense to Firestore
        await _expenseService.addExpense(expense);
        debugPrint('DebtProvider: Created expense for debt payment: ${expense.description}');
      }

      // If this is a reimbursement to the creditor
      {
        // Use the original expense category if available, otherwise use 'Reimbursement'
        final String category = originalCategory ?? 'Reimbursement';
        final String description = '${friend.name} paid back: ${debt.description}';

        // Create a new negative expense for this reimbursement
        final reimbursement = ExpenseModel(
          id: '', // Will be set by the service
          userId: debt.creditorId, // The person who received payment (creditor)
          category: category, // Use original category to update that category's budget
          description: description,
          amount: -debt.amount, // Negative amount to reduce total expenses
          date: DateTime.now(),
          isGroupExpense: false,
          isReimbursement: true, // Mark as reimbursement to show in Splits tab
          isDirectDebt: debt.debtType == DebtType.direct, // Mark as direct debt if it's a direct debt
          participants: [],
        );

        // Add the reimbursement to Firestore
        final savedReimbursement = await _expenseService.addExpense(reimbursement);
        debugPrint('DebtProvider: Created reimbursement for debt payment: ${reimbursement.description}');

        // Explicitly update the budget for this reimbursement
        try {
          await _budgetService.updateBudgetSpent(savedReimbursement);
          debugPrint('DebtProvider: Budget updated for reimbursement: ${savedReimbursement.category} with amount ${savedReimbursement.amount}');
        } catch (e) {
          debugPrint('DebtProvider: Error updating budget for reimbursement: $e');
        }
      }
    } catch (e) {
      debugPrint('DebtProvider: Error creating expense from debt payment: $e');
      // Don't rethrow - we don't want to fail the debt status update
      // if the expense creation fails
    }
  }

  // Helper method to update a debt in all lists
  void _updateDebtInLists(DebtModel updatedDebt) {
    // Update in lent debts
    final lentIndex = _lentDebts.indexWhere((d) => d.id == updatedDebt.id);
    if (lentIndex >= 0) {
      _lentDebts[lentIndex] = updatedDebt;
    }

    // Update in borrowed debts
    final borrowedIndex = _borrowedDebts.indexWhere((d) => d.id == updatedDebt.id);
    if (borrowedIndex >= 0) {
      _borrowedDebts[borrowedIndex] = updatedDebt;
    }

    // Update in friend debts
    final friendIndex = _friendDebts.indexWhere((d) => d.id == updatedDebt.id);
    if (friendIndex >= 0) {
      _friendDebts[friendIndex] = updatedDebt;
    }
  }

  // Get overdue debts
  List<DebtModel> getOverdueBorrowedDebts() {
    final now = DateTime.now();
    return _borrowedDebts
        .where((debt) =>
            debt.status != PaymentStatus.paid &&
            debt.dueDate != null &&
            debt.dueDate!.isBefore(now))
        .toList();
  }

  // Get upcoming due debts (due in the next 7 days)
  List<DebtModel> getUpcomingBorrowedDebts() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _borrowedDebts
        .where((debt) =>
            debt.status != PaymentStatus.paid &&
            debt.dueDate != null &&
            debt.dueDate!.isAfter(now) &&
            debt.dueDate!.isBefore(nextWeek))
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Force clear all cached data (useful when friends are removed)
  void forceClearCache() {
    debugPrint('DebtProvider: Force clearing all cached debt data');
    _lentDebts.clear();
    _borrowedDebts.clear();
    _friendDebts.clear();
    _directFriendDebts.clear();
    _groupExpenseFriendDebts.clear();
    _selectedFriendId = null;
    _error = null;
    notifyListeners();
    debugPrint('DebtProvider: Cache cleared successfully');
  }
}
