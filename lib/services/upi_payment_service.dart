import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_transaction_model.dart';
import '../models/debt_model.dart';
import '../utils/upi_validator.dart';

class UpiPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Launch UPI payment using Intent URI format
  Future<bool> launchUpiPayment({
    required String upiId,
    required String name,
    required double amount,
    required String note,
    String? referenceId,
  }) async {
    try {
      // Validate UPI ID first
      if (!UpiValidator.isValidUpiId(upiId)) {
        final errorMessage = UpiValidator.getUpiIdErrorMessage(upiId);
        debugPrint('UpiPaymentService: Invalid UPI ID: $upiId - $errorMessage');
        return false;
      }

      // Generate a reference ID if not provided
      final String txnRef = referenceId ?? _uuid.v4();

      // Generate a transaction ID (tid) - unique for each transaction
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();

      // Properly encode parameters for the UPI URL
      final String encodedName = Uri.encodeComponent(name);
      final String encodedNote = Uri.encodeComponent(note);
      final String amountStr = amount.toStringAsFixed(2);

      // Format the UPI Intent URI with full parameters
      // pa: Payee UPI ID
      // pn: Payee name
      // tn: Transaction note
      // am: Amount
      // cu: Currency (INR)
      // tr: Transaction reference
      // tid: Transaction ID
      final String intentUri = 'intent://pay?pa=$upiId&pn=$encodedName&am=$amountStr&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid#Intent;scheme=upi;package=upi;end';

      debugPrint('UpiPaymentService: Launching UPI payment with Intent URI: $intentUri');

      // Launch the Intent URI
      final Uri uri = Uri.parse(intentUri);

      // Try to launch the Intent URI
      bool launched = false;

      // Try with external application mode
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        if (launched) {
          debugPrint('UpiPaymentService: Successfully launched UPI Intent URI');

          // Record the payment attempt in Firestore for verification
          await _recordPaymentAttempt(txnRef, upiId, name, amount, note, tid: tid);

          return true;
        }
      }

      // If Intent URI fails, try with standard UPI URI
      if (!launched) {
        debugPrint('UpiPaymentService: Intent URI failed, trying standard UPI URI');

        final String upiUrl = 'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid';
        final Uri standardUri = Uri.parse(upiUrl);

        if (await canLaunchUrl(standardUri)) {
          launched = await launchUrl(
            standardUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );

          if (launched) {
            debugPrint('UpiPaymentService: Successfully launched standard UPI URI');

            // Record the payment attempt in Firestore for verification
            await _recordPaymentAttempt(txnRef, upiId, name, amount, note, tid: tid);

            return true;
          }
        }
      }

      // If all attempts fail, try specific UPI apps
      if (!launched) {
        debugPrint('UpiPaymentService: Trying specific UPI apps with Intent URI');
        launched = await _trySpecificUpiAppsWithIntent(upiId, encodedName, amountStr, encodedNote, txnRef, tid);

        if (launched) {
          // Record the payment attempt in Firestore for verification
          await _recordPaymentAttempt(txnRef, upiId, name, amount, note, tid: tid);
        }
      }

      // If all attempts fail
      if (!launched) {
        debugPrint('UpiPaymentService: Could not launch UPI payment with any method');
        return false;
      }

      return launched;
    } catch (e) {
      debugPrint('UpiPaymentService: Error launching UPI payment: $e');
      return false;
    }
  }

  // Record payment attempt for verification
  Future<void> _recordPaymentAttempt(
    String txnRef,
    String upiId,
    String name,
    double amount,
    String note,
    {String? tid}
  ) async {
    try {
      await _firestore.collection('payment_attempts').doc(txnRef).set({
        'referenceId': txnRef,
        'upiId': upiId,
        'payeeName': name,
        'amount': amount,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'verified': false,
        'transactionId': tid,
      });
      debugPrint('UpiPaymentService: Recorded payment attempt with reference ID: $txnRef');
    } catch (e) {
      debugPrint('UpiPaymentService: Error recording payment attempt: $e');
    }
  }

  // Try launching specific UPI apps with Intent URI
  Future<bool> _trySpecificUpiAppsWithIntent(
    String upiId,
    String encodedName,
    String amount,
    String encodedNote,
    String txnRef,
    String tid
  ) async {
    try {
      // List of common UPI apps with their package names
      final List<Map<String, String>> upiApps = [
        {'name': 'Google Pay', 'package': 'com.google.android.apps.nbu.paisa.user'},
        {'name': 'PhonePe', 'package': 'com.phonepe.app'},
        {'name': 'Paytm', 'package': 'net.one97.paytm'},
        {'name': 'Amazon Pay', 'package': 'in.amazon.mShop.android.shopping'},
        {'name': 'BHIM UPI', 'package': 'in.org.npci.upiapp'},
        {'name': 'WhatsApp Pay', 'package': 'com.whatsapp'},
        {'name': 'ICICI iMobile', 'package': 'com.csam.icici.bank.imobile'},
        {'name': 'HDFC PayZapp', 'package': 'com.hdfc.payzapp'},
        {'name': 'SBI Pay', 'package': 'com.sbi.upi'},
        {'name': 'Axis Mobile', 'package': 'com.axis.mobile'},
      ];

      // Try each UPI app with Intent URI
      for (final Map<String, String> app in upiApps) {
        // Format the Intent URI with specific package
        final String intentUri = 'intent://pay?pa=$upiId&pn=$encodedName&am=$amount&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid#Intent;scheme=upi;package=${app['package']};end';
        final Uri uri = Uri.parse(intentUri);

        debugPrint('UpiPaymentService: Trying ${app['name']} with Intent URI: $intentUri');

        if (await canLaunchUrl(uri)) {
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );

          if (launched) {
            debugPrint('UpiPaymentService: Successfully launched ${app['name']} with Intent URI');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('UpiPaymentService: Error trying specific UPI apps with Intent URI: $e');
      return false;
    }
  }

  // Try launching specific UPI apps with standard URI (fallback)
  Future<bool> _trySpecificUpiApps(
    String upiId,
    String encodedName,
    String amount,
    String encodedNote,
    String txnRef,
    String tid
  ) async {
    try {
      // List of common UPI apps with their scheme names
      final List<String> upiApps = [
        'phonepe', // PhonePe
        'gpay',    // Google Pay
        'paytm',   // Paytm
        'amazonpay', // Amazon Pay
        'bhim',    // BHIM UPI
        'upi',     // Generic UPI
      ];

      // Try each UPI app
      for (final String app in upiApps) {
        // Format the UPI URL with full parameters
        final String upiUrl = '$app://pay?pa=$upiId&pn=$encodedName&am=$amount&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid';
        final Uri uri = Uri.parse(upiUrl);

        debugPrint('UpiPaymentService: Trying $app app with URL: $upiUrl');

        if (await canLaunchUrl(uri)) {
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );

          if (launched) {
            debugPrint('UpiPaymentService: Successfully launched $app app');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('UpiPaymentService: Error trying specific UPI apps: $e');
      return false;
    }
  }

  // Launch a specific UPI app by package name using Intent URI
  Future<bool> launchSpecificUpiApp({
    required String upiId,
    required String name,
    required double amount,
    required String note,
    required String packageName,
    String? referenceId,
  }) async {
    try {
      // Validate UPI ID first
      if (!UpiValidator.isValidUpiId(upiId)) {
        final errorMessage = UpiValidator.getUpiIdErrorMessage(upiId);
        debugPrint('UpiPaymentService: Invalid UPI ID: $upiId - $errorMessage');
        return false;
      }

      // Generate a reference ID if not provided
      final String txnRef = referenceId ?? _uuid.v4();

      // Generate a transaction ID (tid) - unique for each transaction
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();

      // Properly encode parameters for the UPI URL
      final String encodedName = Uri.encodeComponent(name);
      final String encodedNote = Uri.encodeComponent(note);
      final String amountStr = amount.toStringAsFixed(2);

      debugPrint('UpiPaymentService: Launching specific UPI app with package: $packageName');

      // Format the Intent URI with specific package
      // pa: Payee UPI ID
      // pn: Payee name
      // tn: Transaction note
      // am: Amount
      // cu: Currency (INR)
      // tr: Transaction reference
      // tid: Transaction ID
      final String intentUri = 'intent://pay?pa=$upiId&pn=$encodedName&am=$amountStr&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid#Intent;scheme=upi;package=$packageName;end';
      final Uri uri = Uri.parse(intentUri);

      debugPrint('UpiPaymentService: Launching Intent URI: $intentUri');

      // Launch the app with Intent URI
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (launched) {
        debugPrint('UpiPaymentService: Successfully launched UPI app with Intent URI');

        // Record the payment attempt in Firestore for verification
        await _recordPaymentAttempt(txnRef, upiId, name, amount, note, tid: tid);

        return true;
      } else {
        // If Intent URI fails, try with standard UPI URI as fallback
        debugPrint('UpiPaymentService: Intent URI failed, trying standard UPI URI');

        // Get the scheme based on package name
        String scheme = 'upi';
        switch (packageName) {
          case 'com.google.android.apps.nbu.paisa.user':
            scheme = 'gpay';
            break;
          case 'com.phonepe.app':
            scheme = 'phonepe';
            break;
          case 'net.one97.paytm':
            scheme = 'paytm';
            break;
          case 'in.amazon.mShop.android.shopping':
            scheme = 'amazonpay';
            break;
          case 'in.org.npci.upiapp':
            scheme = 'bhim';
            break;
          case 'com.whatsapp':
            scheme = 'whatsapp';
            break;
        }

        final String upiUrl = '$scheme://pay?pa=$upiId&pn=$encodedName&am=$amountStr&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid';
        final Uri standardUri = Uri.parse(upiUrl);

        launched = await launchUrl(
          standardUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        if (launched) {
          debugPrint('UpiPaymentService: Successfully launched UPI app with standard URI');

          // Record the payment attempt in Firestore for verification
          await _recordPaymentAttempt(txnRef, upiId, name, amount, note, tid: tid);

          return true;
        }

        debugPrint('UpiPaymentService: Failed to launch UPI app with any method');
        return false;
      }
    } catch (e) {
      debugPrint('UpiPaymentService: Error launching specific UPI app: $e');
      return false;
    }
  }

  // Launch UPI payment using URL launcher
  Future<Map<String, dynamic>> initiateUpiTransaction({
    required String upiId,
    required String name,
    required double amount,
    required String note,
    String? referenceId,
  }) async {
    try {
      // Generate a reference ID if not provided
      final String txnRef = referenceId ?? _uuid.v4();

      // Generate a transaction ID (tid) - unique for each transaction
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('UpiPaymentService: Initiating UPI transaction with Intent URI');

      // Properly encode parameters for the UPI URL
      final String encodedName = Uri.encodeComponent(name);
      final String encodedNote = Uri.encodeComponent(note);
      final String amountStr = amount.toStringAsFixed(2);

      // Format the Intent URI with full parameters
      final String intentUri = 'intent://pay?pa=$upiId&pn=$encodedName&am=$amountStr&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid#Intent;scheme=upi;package=upi;end';

      // Launch the Intent URI
      final Uri uri = Uri.parse(intentUri);
      bool launched = false;

      // Try with Intent URI first
      if (await canLaunchUrl(uri)) {
        // Try with external non-browser application mode for better handling
        launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);

        // If that fails, try platform default mode
        if (!launched) {
          debugPrint('UpiPaymentService: Intent URI failed, trying platform default mode');
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }

      // If Intent URI fails, try with standard UPI URI
      if (!launched) {
        debugPrint('UpiPaymentService: Intent URI failed, trying standard UPI URI');

        final String upiUrl = 'upi://pay?pa=$upiId&pn=$encodedName&am=$amountStr&tn=$encodedNote&cu=INR&tr=$txnRef&tid=$tid';
        final Uri standardUri = Uri.parse(upiUrl);

        if (await canLaunchUrl(standardUri)) {
          launched = await launchUrl(standardUri, mode: LaunchMode.externalNonBrowserApplication);
        }
      }

      // If all standard methods fail, try specific UPI apps with Intent URI
      if (!launched) {
        debugPrint('UpiPaymentService: Standard methods failed, trying specific UPI apps with Intent URI');
        launched = await _trySpecificUpiAppsWithIntent(upiId, encodedName, amountStr, encodedNote, txnRef, tid);

        // If Intent URI fails, try with standard UPI URI as fallback
        if (!launched) {
          debugPrint('UpiPaymentService: Intent URI for specific apps failed, trying standard UPI URI');
          launched = await _trySpecificUpiApps(upiId, encodedName, amountStr, encodedNote, txnRef, tid);
        }
      }

      debugPrint('UpiPaymentService: UPI URL launched: $launched');

      // Record the payment attempt in Firestore for verification
      if (launched) {
        await _recordPaymentAttempt(txnRef, upiId, name, amount, note, tid: tid);
      }

      // Return result
      final Map<String, dynamic> result = {
        'success': launched,
        'status': launched ? 'initiated' : 'failed',
        'transactionId': tid,
        'txnRef': txnRef,
        'message': launched ? 'UPI payment initiated successfully' : 'Failed to launch UPI payment app',
      };

      return result;
    } catch (e) {
      debugPrint('UpiPaymentService: Error initiating UPI transaction: $e');
      final String errorTxnRef = referenceId ?? _uuid.v4();
      final String errorTid = DateTime.now().millisecondsSinceEpoch.toString();

      return {
        'success': false,
        'status': 'failed',
        'message': 'Error: ${e.toString()}',
        'transactionId': errorTid,
        'txnRef': errorTxnRef,
      };
    }
  }

  // Record a payment transaction in Firestore
  Future<PaymentTransactionModel> recordPaymentTransaction({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String description,
    required PaymentStatus status,
    required PaymentMethod method,
    String? debtId,
    String? expenseId,
    String? upiTransactionId,
    String? upiReferenceId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final String id = _uuid.v4();

      final PaymentTransactionModel transaction = PaymentTransactionModel(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        status: status,
        method: method,
        debtId: debtId,
        expenseId: expenseId,
        upiTransactionId: upiTransactionId,
        upiReferenceId: upiReferenceId,
        additionalData: additionalData,
      );

      await _firestore.collection('payments').doc(id).set(transaction.toMap());

      return transaction;
    } catch (e) {
      debugPrint('UpiPaymentService: Error recording payment transaction: $e');
      rethrow;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? upiTransactionId,
    String? upiReferenceId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': _paymentStatusToString(status),
        'timestamp': Timestamp.fromDate(DateTime.now()),
      };

      if (upiTransactionId != null) {
        updateData['upiTransactionId'] = upiTransactionId;
      }

      if (upiReferenceId != null) {
        updateData['upiReferenceId'] = upiReferenceId;
      }

      if (additionalData != null) {
        updateData['additionalData'] = additionalData;
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      debugPrint('UpiPaymentService: Error updating payment status: $e');
      rethrow;
    }
  }

  // Get payment transactions for a user
  Future<List<PaymentTransactionModel>> getUserPayments(String userId) async {
    try {
      final sentPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final receivedPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('toUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final List<PaymentTransactionModel> payments = [];

      for (final doc in sentPaymentsSnapshot.docs) {
        payments.add(PaymentTransactionModel.fromDocument(doc));
      }

      for (final doc in receivedPaymentsSnapshot.docs) {
        payments.add(PaymentTransactionModel.fromDocument(doc));
      }

      // Sort by timestamp (newest first)
      payments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return payments;
    } catch (e) {
      debugPrint('UpiPaymentService: Error getting user payments: $e');
      rethrow;
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

  // Verify payment status by reference ID
  Future<Map<String, dynamic>> verifyPaymentStatus(String referenceId) async {
    try {
      // Check if the payment attempt exists
      final paymentAttemptDoc = await _firestore.collection('payment_attempts').doc(referenceId).get();

      if (!paymentAttemptDoc.exists) {
        return {
          'success': false,
          'message': 'Payment attempt not found',
          'status': 'unknown',
          'verified': false,
        };
      }

      // Get the payment attempt data
      final paymentAttemptData = paymentAttemptDoc.data() as Map<String, dynamic>;

      // Check if the payment has already been verified
      if (paymentAttemptData['verified'] == true) {
        return {
          'success': true,
          'message': 'Payment already verified',
          'status': paymentAttemptData['status'],
          'verified': true,
          'data': paymentAttemptData,
        };
      }

      // Check if there's a corresponding transaction in the payment_transactions collection
      final transactionsQuery = await _firestore
          .collection('payment_transactions')
          .where('upiReferenceId', isEqualTo: referenceId)
          .limit(1)
          .get();

      if (transactionsQuery.docs.isNotEmpty) {
        final transactionDoc = transactionsQuery.docs.first;
        final transactionData = transactionDoc.data();

        // Update the payment attempt with the transaction status
        await _firestore.collection('payment_attempts').doc(referenceId).update({
          'status': transactionData['status'],
          'verified': true,
          'transactionId': transactionDoc.id,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Payment verified successfully',
          'status': transactionData['status'],
          'verified': true,
          'data': {
            ...paymentAttemptData,
            'status': transactionData['status'],
            'verified': true,
            'transactionId': transactionDoc.id,
          },
        };
      }

      // If no transaction found, update the attempt status to 'pending_verification'
      await _firestore.collection('payment_attempts').doc(referenceId).update({
        'status': 'pending_verification',
        'lastCheckedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Payment is pending verification',
        'status': 'pending_verification',
        'verified': false,
        'data': {
          ...paymentAttemptData,
          'status': 'pending_verification',
        },
      };
    } catch (e) {
      debugPrint('UpiPaymentService: Error verifying payment status: $e');
      return {
        'success': false,
        'message': 'Error verifying payment: ${e.toString()}',
        'status': 'error',
        'verified': false,
      };
    }
  }

  // Manually mark a payment as verified (for testing or manual verification)
  Future<bool> manuallyVerifyPayment(String referenceId, PaymentStatus status) async {
    try {
      // Check if the payment attempt exists
      final paymentAttemptDoc = await _firestore.collection('payment_attempts').doc(referenceId).get();

      if (!paymentAttemptDoc.exists) {
        debugPrint('UpiPaymentService: Payment attempt not found for manual verification');
        return false;
      }

      // Update the payment attempt status
      await _firestore.collection('payment_attempts').doc(referenceId).update({
        'status': _paymentStatusToString(status),
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verificationMethod': 'manual',
      });

      debugPrint('UpiPaymentService: Payment manually verified with status: ${_paymentStatusToString(status)}');
      return true;
    } catch (e) {
      debugPrint('UpiPaymentService: Error manually verifying payment: $e');
      return false;
    }
  }
}
