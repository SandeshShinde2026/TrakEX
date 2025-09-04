import 'package:flutter/material.dart';
import '../services/smart_budget_alerts_service.dart';

class SmartBudgetAlertDialog extends StatelessWidget {
  final SmartBudgetAlert alert;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;

  const SmartBudgetAlertDialog({
    super.key,
    required this.alert,
    this.onProceed,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildBudgetProgress(),
              const SizedBox(height: 16),
              _buildContextualMessage(),
              const SizedBox(height: 16),
              _buildSpendingStats(),
              if (alert.alternatives.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildAlternatives(),
              ],
              if (alert.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRecommendations(),
              ],
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    Color color;
    String title;

    switch (alert.alertLevel) {
      case BudgetAlertLevel.critical:
        icon = Icons.error;
        color = Colors.red;
        title = 'Budget Alert - Critical';
        break;
      case BudgetAlertLevel.warning:
        icon = Icons.warning;
        color = Colors.orange;
        title = 'Budget Alert - Warning';
        break;
      case BudgetAlertLevel.caution:
        icon = Icons.info;
        color = Colors.blue;
        title = 'Budget Alert - Caution';
        break;
      case BudgetAlertLevel.info:
        icon = Icons.lightbulb;
        color = Colors.green;
        title = 'Budget Update';
        break;
      case BudgetAlertLevel.none:
        icon = Icons.check;
        color = Colors.grey;
        title = 'Budget Status';
        break;
    }

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                alert.category,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetProgress() {
    final progress = (alert.currentSpending / alert.budgetAmount).clamp(0.0, 1.0);
    final progressColor = alert.isOverBudget 
        ? Colors.red 
        : progress > 0.8 
            ? Colors.orange 
            : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget Progress'),
            Text(
              '${alert.usagePercentage.toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ₹${alert.currentSpending.toInt()}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Budget: ₹${alert.budgetAmount.toInt()}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextualMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        alert.contextualMessage,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildSpendingStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow('Days left in month', '${alert.daysLeftInMonth} days'),
          _buildStatRow('Daily spending rate', '₹${alert.spendingVelocity.toInt()}/day'),
          _buildStatRow('Projected month-end', '₹${alert.projectedMonthEnd.toInt()}'),
          if (alert.remainingBudget > 0)
            _buildStatRow('Remaining budget', '₹${alert.remainingBudget.toInt()}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternatives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consider these alternatives:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...alert.alternatives.map((alternative) => _buildAlternativeItem(alternative)),
      ],
    );
  }

  Widget _buildAlternativeItem(BudgetAlternative alternative) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alternative.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alternative.effort,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            alternative.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save ₹${alternative.potentialSavings.toInt()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Recommendations:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...alert.recommendations.map((rec) => _buildRecommendationItem(rec)),
      ],
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: const Text('Review Later'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onProceed?.call();
            },
            child: Text(
              alert.alertLevel == BudgetAlertLevel.critical 
                  ? 'Proceed Anyway' 
                  : 'Continue',
            ),
          ),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context,
    SmartBudgetAlert alert, {
    VoidCallback? onProceed,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmartBudgetAlertDialog(
        alert: alert,
        onProceed: () {
          onProceed?.call();
          Navigator.of(context).pop(true);
        },
        onCancel: () {
          onCancel?.call();
          Navigator.of(context).pop(false);
        },
      ),
    );
  }
}