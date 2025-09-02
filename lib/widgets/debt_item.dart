import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/debt_model.dart';
import '../providers/auth_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/in_app_notification_provider.dart';
import '../screens/home/add_debt_screen.dart';
import '../services/reminder_service.dart';
import '../widgets/payment_button.dart';

class DebtItem extends StatelessWidget {
  final DebtModel debt;
  final UserModel friend;
  final VoidCallback onStatusChanged;

  const DebtItem({
    super.key,
    required this.debt,
    required this.friend,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Determine if current user is the creditor or debtor
    final isCreditor = debt.creditorId == authProvider.userModel!.id;

    // Set colors and icons based on debt direction
    final Color statusColor = isCreditor ? Colors.green : Colors.red;
    final IconData directionIcon = isCreditor ? Icons.arrow_downward : Icons.arrow_upward;

    // Format date
    final formattedDate = DateFormat('MMM d, yyyy').format(debt.createdAt);

    // Payment method icon
    IconData paymentMethodIcon;
    switch (debt.paymentMethod) {
      case PaymentMethod.cash:
        paymentMethodIcon = Icons.money;
        break;
      case PaymentMethod.upi:
        paymentMethodIcon = Icons.phone_android;
        break;
      case PaymentMethod.bankTransfer:
        paymentMethodIcon = Icons.account_balance;
        break;
      case PaymentMethod.other:
        paymentMethodIcon = Icons.payments;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: InkWell(
        onTap: () {
          _showDebtOptions(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with amount and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Direction and amount
                  Row(
                    children: [
                      Icon(
                        directionIcon,
                        color: statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Debt type indicator
                      _buildDebtTypeChip(context),
                    ],
                  ),

                  // Payment status chip
                  _buildStatusChip(context),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                debt.description,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              // Footer with date, payment method, and pay button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),

                  // Payment method
                  Row(
                    children: [
                      Icon(
                        paymentMethodIcon,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getPaymentMethodText(debt.paymentMethod),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Add Pay button if the debt is pending and user is the debtor
              if (debt.status == PaymentStatus.pending && !isCreditor) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PaymentButton(
                      friend: friend,
                      amount: debt.amount,
                      description: 'Payment for: ${debt.description}',
                      debt: debt,
                      isSmall: true,
                      isOutlined: true,
                    ),
                  ],
                ),
              ],

              // Add Send Reminder button if the debt is pending and user is the creditor
              if (debt.status == PaymentStatus.pending && isCreditor) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _sendReminder(context),
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text('Send Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    String statusText;

    switch (debt.status) {
      case PaymentStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case PaymentStatus.paid:
      case PaymentStatus.completed:
        chipColor = Colors.green;
        statusText = 'Paid';
        break;
      case PaymentStatus.failed:
        chipColor = Colors.red;
        statusText = 'Failed';
        break;
      case PaymentStatus.cancelled:
        chipColor = Colors.grey;
        statusText = 'Cancelled';
        break;
      case PaymentStatus.verifying:
        chipColor = Colors.blue;
        statusText = 'Verifying';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDebtTypeChip(BuildContext context) {
    Color chipColor;
    String typeText;
    IconData typeIcon;

    switch (debt.debtType) {
      case DebtType.direct:
        chipColor = Colors.blue;
        typeText = 'Direct';
        typeIcon = Icons.person;
        break;
      case DebtType.groupExpense:
        chipColor = Colors.purple;
        typeText = 'Group';
        typeIcon = Icons.group;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeIcon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 2),
          Text(
            typeText,
            style: TextStyle(
              fontSize: 10,
              color: chipColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  void _showDebtOptions(BuildContext context) {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCreditor = debt.creditorId == authProvider.userModel!.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.mediumRadius),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Transaction Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.mediumSpacing),

            // Send Reminder option (only for creditors with pending debts)
            if (debt.status == PaymentStatus.pending && isCreditor)
              ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.orange),
                title: const Text('Send Payment Reminder'),
                subtitle: Text('Notify ${friend.name} about this pending payment'),
                onTap: () {
                  Navigator.pop(context);
                  _sendReminder(context);
                },
              ),

            // Edit option
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Transaction'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDebtScreen(
                      friend: friend,
                      existingDebt: debt,
                    ),
                  ),
                ).then((_) => onStatusChanged());
              },
            ),

            // Toggle status option
            ListTile(
              leading: Icon(
                debt.status == PaymentStatus.pending
                    ? Icons.check_circle
                    : Icons.pending_actions,
              ),
              title: Text(
                debt.status == PaymentStatus.pending
                    ? 'Mark as Paid'
                    : 'Mark as Pending',
              ),
              onTap: () async {
                Navigator.pop(context);

                final newStatus = debt.status == PaymentStatus.pending
                    ? PaymentStatus.paid
                    : PaymentStatus.pending;

                debugPrint('DebtItem: Updating debt status to ${newStatus.toString()}');

                final success = await debtProvider.updateDebtStatus(
                  debtId: debt.id,
                  newStatus: newStatus,
                  friend: friend,
                );

                if (success) {
                  debugPrint('DebtItem: Status updated successfully');
                } else {
                  debugPrint('DebtItem: Failed to update status');
                }

                // Call the callback to refresh the parent screen
                onStatusChanged();
              },
            ),

            // Delete option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Transaction', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await debtProvider.deleteDebt(debt.id);
              onStatusChanged();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Send reminder to friend about pending payment
  void _sendReminder(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final inAppProvider = Provider.of<InAppNotificationProvider>(context, listen: false);
    final reminderService = ReminderService();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending reminder...'),
          ],
        ),
      ),
    );

    try {
      bool success;

      if (debt.debtType == DebtType.groupExpense) {
        success = await reminderService.sendGroupExpenseReminder(
          groupDebt: debt,
          friend: friend,
          currentUser: authProvider.userModel!,
          inAppProvider: inAppProvider,
        );
      } else {
        success = await reminderService.sendDebtReminder(
          debt: debt,
          friend: friend,
          currentUser: authProvider.userModel!,
          inAppProvider: inAppProvider,
        );
      }

      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show result message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                ? '📱 Reminder sent to ${friend.name}!'
                : 'Failed to send reminder. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reminder: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
