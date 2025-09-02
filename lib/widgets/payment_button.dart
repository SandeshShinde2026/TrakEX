import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/debt_model.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../screens/payments/payment_confirmation_screen.dart';
import '../screens/payments/payment_verification_screen.dart';

class PaymentButton extends StatelessWidget {
  final UserModel friend;
  final double amount;
  final String description;
  final DebtModel? debt;
  final String? expenseId;
  final bool isSmall;
  final bool isOutlined;
  final Color? color;

  const PaymentButton({
    super.key,
    required this.friend,
    required this.amount,
    required this.description,
    this.debt,
    this.expenseId,
    this.isSmall = false,
    this.isOutlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userModel;

    // Disable button if no UPI ID is available
    final bool friendHasUpiId = friend.upiId != null && friend.upiId!.isNotEmpty;
    final bool currentUserHasUpiId = currentUser != null && currentUser.upiId != null && currentUser.upiId!.isNotEmpty;
    final bool isEnabled = friendHasUpiId && currentUserHasUpiId;

    // Button style
    final ButtonStyle buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color ?? AppTheme.primaryColor,
            side: BorderSide(color: color ?? AppTheme.primaryColor),
            padding: isSmall
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color ?? AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: isSmall
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          );

    // Button text
    final String buttonText = isSmall
        ? 'Pay'
        : 'Pay ${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';

    // Button tooltip
    final String tooltip = !isEnabled
        ? friendHasUpiId
            ? 'You need to add your UPI ID in profile settings'
            : '${friend.name} has not provided a UPI ID'
        : 'Pay ${AppConstants.currencySymbol}${amount.toStringAsFixed(2)} to ${friend.name}';

    return Tooltip(
      message: tooltip,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: isEnabled ? () => _handlePayment(context) : null,
              style: buttonStyle,
              icon: const Icon(Icons.payment, size: 18),
              label: Text(buttonText),
            )
          : ElevatedButton.icon(
              onPressed: isEnabled ? () => _handlePayment(context) : null,
              style: buttonStyle,
              icon: const Icon(Icons.payment, size: 18),
              label: Text(buttonText),
            ),
    );
  }

  void _handlePayment(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final currentUser = authProvider.userModel;

    if (currentUser == null) return;

    // Show payment confirmation dialog
    final bool? confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          payer: currentUser,
          payee: friend,
          amount: amount,
          description: description,
          debt: debt,
          expenseId: expenseId,
        ),
      ),
    );

    if (confirmed == true) {
      // Initiate payment
      final success = await paymentProvider.initiateUpiPayment(
        payer: currentUser,
        payee: friend,
        amount: amount,
        description: description,
        debt: debt,
        expenseId: expenseId,
      );

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Payment failed. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: () {
                // Try again with the payment
                _handlePayment(context);
              },
            ),
          ),
        );
      } else if (success && context.mounted) {
        // Show option to verify payment
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment initiated. Verify payment status?'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Verify',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to payment verification screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentVerificationScreen(
                      upiId: friend.upiId,
                      payeeName: friend.name,
                      amount: amount,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }
}
