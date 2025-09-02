import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_transaction_model.dart';
import '../models/debt_model.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../services/upi_payment_service.dart';
import '../services/debt_service.dart';
import '../services/expense_service.dart';
import '../constants/app_constants.dart';

class PaymentProvider extends ChangeNotifier {
  final UpiPaymentService _upiPaymentService = UpiPaymentService();
  final DebtService _debtService = DebtService();
  final ExpenseService _expenseService = ExpenseService();

  List<PaymentTransactionModel> _userPayments = [];
  PaymentTransactionModel? _currentTransaction;
  bool _isLoading = false;
  String? _error;

  List<PaymentTransactionModel> get userPayments => _userPayments;
  PaymentTransactionModel? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize payment provider
  Future<void> init(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadUserPayments(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load user payments
  Future<void> loadUserPayments(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final payments = await _upiPaymentService.getUserPayments(userId);
      _userPayments = payments;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Initiate UPI payment
  Future<bool> initiateUpiPayment({
    required UserModel payer,
    required UserModel payee,
    required double amount,
    required String description,
    required DebtModel? debt,
    String? expenseId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if payee has UPI ID
      if (payee.upiId == null || payee.upiId!.isEmpty) {
        _error = '${payee.name} has not provided a UPI ID for payments.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a reference ID
      final String referenceId = '${payer.id}_${payee.id}_${DateTime.now().millisecondsSinceEpoch}';

      // Record the payment transaction as pending
      final transaction = await _upiPaymentService.recordPaymentTransaction(
        fromUserId: payer.id,
        toUserId: payee.id,
        amount: amount,
        description: description,
        status: PaymentStatus.pending,
        method: PaymentMethod.upi,
        debtId: debt?.id,
        expenseId: expenseId,
        upiReferenceId: referenceId,
        additionalData: {
          'payerName': payer.name,
          'payeeName': payee.name,
          'payeeUpiId': payee.upiId,
          'initiatedAt': DateTime.now().toIso8601String(),
        },
      );

      _currentTransaction = transaction;
      notifyListeners();

      // Launch UPI payment
      final paymentLaunched = await _upiPaymentService.launchUpiPayment(
        upiId: payee.upiId!,
        name: payee.name,
        amount: amount,
        note: description,
        referenceId: referenceId,
      );

      if (!paymentLaunched) {
        // Update transaction status to failed
        await _upiPaymentService.updatePaymentStatus(
          paymentId: transaction.id,
          status: PaymentStatus.failed,
          additionalData: {
            'failureReason': 'Failed to launch UPI payment app',
            'failedAt': DateTime.now().toIso8601String(),
          },
        );

        _currentTransaction = _currentTransaction?.copyWith(
          status: PaymentStatus.failed,
        );

        _error = 'Failed to launch UPI payment app. Try using the "Select UPI App" option to manually choose your payment app.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update transaction status to verifying
      await _upiPaymentService.updatePaymentStatus(
        paymentId: transaction.id,
        status: PaymentStatus.verifying,
      );

      _currentTransaction = _currentTransaction?.copyWith(
        status: PaymentStatus.verifying,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PaymentProvider: Error initiating UPI payment: $e');
      _error = 'Payment initiation failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? upiTransactionId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _upiPaymentService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
        upiTransactionId: upiTransactionId,
        additionalData: additionalData,
      );

      // Update current transaction if it's the same one
      if (_currentTransaction != null && _currentTransaction!.id == paymentId) {
        _currentTransaction = _currentTransaction!.copyWith(
          status: status,
          upiTransactionId: upiTransactionId,
          additionalData: additionalData,
        );
      }

      // Reload user payments if needed
      if (_currentTransaction != null) {
        await loadUserPayments(_currentTransaction!.fromUserId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('PaymentProvider: Error updating payment status: $e');
      _error = 'Failed to update payment status: ${e.toString()}';
      notifyListeners();
    }
  }

  // Mark debt as paid
  Future<void> markDebtAsPaid(DebtModel debt, String paymentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update debt status
      await _debtService.updateDebtStatus(
        debtId: debt.id,
        newStatus: PaymentStatus.completed,
      );

      // Update payment status
      await updatePaymentStatus(
        paymentId: paymentId,
        status: PaymentStatus.completed,
        additionalData: {
          'completedAt': DateTime.now().toIso8601String(),
          'debtMarkedAsPaid': true,
        },
      );

      // Create an expense record for the payment if it's a group expense
      if (debt.debtType == DebtType.groupExpense && debt.expenseId != null) {
        await _createExpenseForGroupExpensePayment(debt);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('PaymentProvider: Error marking debt as paid: $e');
      _error = 'Failed to mark debt as paid: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create an expense record for a group expense payment
  Future<void> _createExpenseForGroupExpensePayment(DebtModel debt) async {
    try {
      // Get the original expense to get details
      final originalExpense = await _expenseService.getExpense(debt.expenseId!);
      if (originalExpense == null) {
        debugPrint('PaymentProvider: Original expense not found for debt ${debt.id}');
        return;
      }

      // Get the creditor's name (the person who paid for the original expense)
      String creditorName = "Friend";
      try {
        // Get user document from Firestore directly
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(debt.creditorId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['name'] != null) {
            creditorName = userData['name'].toString();
          }
        }
      } catch (e) {
        debugPrint('PaymentProvider: Error getting creditor name: $e');
      }

      // Create a new expense record for the payment
      final paymentExpense = ExpenseModel(
        id: '', // Will be set by the service
        userId: debt.debtorId, // The person who paid (debtor)
        category: originalExpense.category, // Use the same category as the original expense
        description: 'You paid ${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)} to $creditorName for: ${originalExpense.description}',
        amount: debt.amount, // The amount paid
        date: DateTime.now(),
        isGroupExpense: false,
        isReimbursement: true, // Mark as reimbursement to show in Splits tab
        participants: [],
      );

      // Add the expense to Firestore
      final savedExpense = await _expenseService.addExpense(paymentExpense);
      debugPrint('PaymentProvider: Created expense record for group expense payment: ${savedExpense.description}');

    } catch (e) {
      debugPrint('PaymentProvider: Error creating expense for group expense payment: $e');
      // Don't rethrow - we don't want to fail the debt status update if expense creation fails
    }
  }

  // Clear current transaction
  void clearCurrentTransaction() {
    _currentTransaction = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Verify payment status
  Future<Map<String, dynamic>> verifyPaymentStatus(String referenceId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _upiPaymentService.verifyPaymentStatus(referenceId);

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('PaymentProvider: Error verifying payment status: $e');
      _error = 'Failed to verify payment status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'Error verifying payment: ${e.toString()}',
        'status': 'error',
        'verified': false,
      };
    }
  }

  // Manually mark payment as completed
  Future<bool> markPaymentAsCompleted(String referenceId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _upiPaymentService.manuallyVerifyPayment(
        referenceId,
        PaymentStatus.completed,
      );

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      debugPrint('PaymentProvider: Error marking payment as completed: $e');
      _error = 'Failed to mark payment as completed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }
}
