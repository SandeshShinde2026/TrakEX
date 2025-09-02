import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/budget_model.dart';

class BudgetAlertCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const BudgetAlertCard({
    super.key,
    required this.budget,
    required this.onTap,
    this.onDismiss,
  });

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

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      color: isOverBudget
          ? Colors.red.shade50
          : Colors.orange.shade50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert header
              Row(
                children: [
                  Icon(
                    isOverBudget ? Icons.warning : Icons.info_outline,
                    color: isOverBudget ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOverBudget ? 'Budget Exceeded!' : 'Budget Alert',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverBudget ? Colors.red : Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onDismiss,
                      tooltip: 'Dismiss',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.smallSpacing),

              // Category and amount
              Text(
                '${budget.category} Budget',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // Alert message
              Text(
                isOverBudget
                    ? 'You have exceeded your budget by ${AppConstants.currencySymbol}${amountOver.toStringAsFixed(2)}!'
                    : 'You have used $percentUsed% of your budget.',
                style: TextStyle(
                  color: isOverBudget ? Colors.red.shade700 : Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: AppTheme.smallSpacing),

              // Progress bar
              LinearProgressIndicator(
                value: (budget.spent / budget.amount).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),

              // Budget details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${AppConstants.currencySymbol}${budget.spent.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOverBudget ? Colors.red.shade700 : null,
                    ),
                  ),
                  Text(
                    'Budget: ${AppConstants.currencySymbol}${budget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
