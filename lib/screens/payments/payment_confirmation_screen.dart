import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/debt_model.dart';
import '../../widgets/upi_app_selection_dialog.dart';
import '../../services/upi_payment_service.dart';
import 'payment_verification_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final UserModel payer;
  final UserModel payee;
  final double amount;
  final String description;
  final DebtModel? debt;
  final String? expenseId;

  const PaymentConfirmationScreen({
    super.key,
    required this.payer,
    required this.payee,
    required this.amount,
    required this.description,
    this.debt,
    this.expenseId,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  bool _isLoading = false;
  bool _markDebtAsPaid = true;
  final UpiPaymentService _upiPaymentService = UpiPaymentService();

  // Method to show UPI app selection dialog
  Future<void> _selectUpiApp() async {
    if (!mounted) return;

    final String? packageName = await showDialog<String>(
      context: context,
      builder: (context) => const UpiAppSelectionDialog(),
    );

    if (packageName != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Generate a reference ID for tracking
        final String referenceId = DateTime.now().millisecondsSinceEpoch.toString();

        // Launch the selected UPI app
        final bool success = await _upiPaymentService.launchSpecificUpiApp(
          upiId: widget.payee.upiId!,
          name: widget.payee.name,
          amount: widget.amount,
          note: widget.description,
          packageName: packageName,
          referenceId: referenceId,
        );

        if (!mounted) return;

        if (success) {
          // Return true to indicate payment was initiated
          Navigator.pop(context, true);

          // After a short delay, navigate to the verification screen
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentVerificationScreen(
                  referenceId: referenceId,
                  upiId: widget.payee.upiId,
                  payeeName: widget.payee.name,
                  amount: widget.amount,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to launch UPI app. Please try another app.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error launching UPI app: $e');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment details card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      _buildDetailRow('From', widget.payer.name),
                      _buildDetailRow('To', widget.payee.name),
                      _buildDetailRow(
                        'Amount',
                        '${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(2)}',
                        valueColor: AppTheme.primaryColor,
                        valueFontWeight: FontWeight.bold,
                      ),
                      _buildDetailRow('Description', widget.description),
                      if (widget.payee.upiId != null)
                        _buildDetailRow('UPI ID', widget.payee.upiId!),
                      if (widget.debt != null) ...[
                        const SizedBox(height: AppTheme.smallSpacing),
                        const Divider(),
                        const SizedBox(height: AppTheme.smallSpacing),
                        Row(
                          children: [
                            Checkbox(
                              value: _markDebtAsPaid,
                              onChanged: (value) {
                                setState(() {
                                  _markDebtAsPaid = value ?? true;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Mark debt as paid after successful payment',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.mediumSpacing),

              // Payment method card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(
                            Icons.payment,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text('UPI Payment'),
                        subtitle: const Text(
                          'Pay directly using any UPI app (Google Pay, PhonePe, Paytm, etc.)',
                        ),
                        trailing: Radio<bool>(
                          value: true,
                          groupValue: true,
                          onChanged: (value) {},
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Having trouble with automatic UPI app launch?',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _selectUpiApp,
                              icon: const Icon(Icons.apps),
                              label: const Text('Select UPI App'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.largeSpacing),

              // Payment buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.mediumSpacing),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Proceed to Pay'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.mediumSpacing),

              // Payment note
              const Card(
                color: Color(0xFFF5F5F5),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppTheme.smallSpacing),
                      Text(
                        'You will be redirected to your UPI payment app to complete the transaction. After payment, please return to this app to confirm the payment status.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueFontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() async {
    // Check if the payee has a UPI ID
    if (widget.payee.upiId == null || widget.payee.upiId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.payee.name} has not provided a UPI ID for payments.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Generate a reference ID for tracking
    final String referenceId = DateTime.now().millisecondsSinceEpoch.toString();

    // Return true to indicate payment confirmation
    Navigator.pop(context, true);

    // After a short delay, navigate to the verification screen
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentVerificationScreen(
              referenceId: referenceId,
              upiId: widget.payee.upiId,
              payeeName: widget.payee.name,
              amount: widget.amount,
            ),
          ),
        );
      }
    }
  }
}
