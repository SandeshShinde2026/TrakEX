import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/budget_model.dart';

class BudgetStatusCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onTap;

  const BudgetStatusCard({
    super.key,
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a dynamically added category
    final isDynamicCategory = budget.isDynamicCategory;

    // Calculate percentage used
    final percentUsed = budget.percentageUsed;
    final isOverBudget = budget.isOverBudget;
    final isNearThreshold = budget.isNearThreshold;

    // Determine status color
    Color statusColor;
    if (isDynamicCategory) {
      statusColor = Colors.grey; // Use grey for dynamic categories
    } else if (isOverBudget) {
      statusColor = Colors.red;
    } else if (isNearThreshold) {
      statusColor = Colors.orange;
    } else if (percentUsed > 50) {
      statusColor = Colors.amber;
    } else {
      statusColor = Colors.green;
    }

    // Find category icon
    final categoryInfo = AppConstants.expenseCategories.firstWhere(
      (c) => c['name'] == budget.category,
      orElse: () => {'name': budget.category, 'icon': Icons.category},
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.smallSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category and status
              Row(
                children: [
                  Icon(
                    categoryInfo['icon'] as IconData,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      budget.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isDynamicCategory
                          ? 'No Limit'
                          : isOverBudget
                              ? 'Exceeded'
                              : isNearThreshold
                                  ? 'Near Limit'
                                  : '${percentUsed.toInt()}% Used',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.smallSpacing),

              // Progress bar
              LinearProgressIndicator(
                value: isDynamicCategory ? 0.0 : (budget.spent / budget.amount).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),

              // Amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${AppConstants.currencySymbol}${budget.spent.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOverBudget ? Colors.red : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    isDynamicCategory
                        ? 'Budget: No Limit'
                        : 'Budget: ${AppConstants.currencySymbol}${budget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[700],
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
