import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/budget_model.dart';

class BudgetAlertDialog extends StatelessWidget {
  final BudgetModel budget;

  const BudgetAlertDialog({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    // Check if it's a dynamically added category (amount is 999999)
    final isDynamicCategory = budget.amount >= 999999;

    // For dynamic categories, we don't show alerts
    if (isDynamicCategory) {
      return const SizedBox.shrink(); // Don't show alert for dynamic categories
    }

    final isOverBudget = budget.isOverBudget;
    final percentUsed = budget.percentageUsed.toInt();
    final amountOver = budget.spent - budget.amount;

    return AlertDialog(
      title: Text(
        isOverBudget ? 'Budget Exceeded!' : 'Budget Alert',
        style: TextStyle(
          color: isOverBudget ? Colors.red : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Icon(
            isOverBudget ? Icons.warning : Icons.info_outline,
            color: isOverBudget ? Colors.red : Colors.orange,
            size: 48,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Message
          Text(
            isOverBudget
                ? 'You have exceeded your ${budget.category} budget by ${AppConstants.currencySymbol}${amountOver.toStringAsFixed(2)}!'
                : 'You have used $percentUsed% of your ${budget.category} budget.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.mediumSpacing),

          // Budget details
          Container(
            padding: const EdgeInsets.all(AppTheme.smallSpacing),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow('Budget', '${AppConstants.currencySymbol}${budget.amount.toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow('Spent', '${AppConstants.currencySymbol}${budget.spent.toStringAsFixed(2)}',
                  textColor: isOverBudget ? Colors.red : null),
                const Divider(),
                _buildDetailRow(
                  'Remaining',
                  isOverBudget
                      ? '-${AppConstants.currencySymbol}${amountOver.toStringAsFixed(2)}'
                      : '${AppConstants.currencySymbol}${(budget.amount - budget.spent).toStringAsFixed(2)}',
                  textColor: isOverBudget ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),

          // Progress bar
          const SizedBox(height: AppTheme.mediumSpacing),
          LinearProgressIndicator(
            value: (budget.spent / budget.amount).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverBudget ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentUsed% used',
            style: TextStyle(
              color: isOverBudget ? Colors.red : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to budget screen
            Navigator.pushNamed(context, '/budget');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isOverBudget ? Colors.red : Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('View Budget'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
