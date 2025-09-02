import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/expense_model.dart';
import 'currency_amount_display.dart';

class RecentTransactionCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;

  const RecentTransactionCard({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Find category icon
    final categoryInfo = AppConstants.expenseCategories.firstWhere(
      (c) => c['name'] == expense.category,
      orElse: () => {'name': expense.category, 'icon': Icons.category},
    );

    // Format date
    final formattedDate = DateFormat(AppConstants.dateFormat).format(expense.date);

    // Get mood icon if available
    IconData? moodIcon;
    if (expense.mood != null) {
      final moodInfo = AppConstants.moodOptions.firstWhere(
        (m) => m['name'] == expense.mood,
        orElse: () => {'name': expense.mood, 'icon': null},
      );
      moodIcon = moodInfo['icon'] as IconData?;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.smallSpacing),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryInfo['icon'] as IconData,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.smallSpacing),

              // Description and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (moodIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            moodIcon,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ],
                        if (expense.isGroupExpense) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.group,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              CurrencyAmountDisplay(
                expense: expense,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: expense.amount < 0 ? Colors.green : null,
                ),
                showConversionInfo: false, // Keep it simple in dashboard
              ),
            ],
          ),
        ),
      ),
    );
  }
}
