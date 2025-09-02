import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/debt_model.dart';
import '../widgets/budget_alert_dialog.dart';

// Simplified notification service without actual notifications for now
class NotificationService {
  // Initialize notification service
  Future<void> initialize() async {
    // This is a placeholder for actual notification initialization
    debugPrint('NotificationService initialized');
  }

  // Show immediate notification (placeholder)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // This is a placeholder for actual notification
    debugPrint('Notification: ID=$id, Title=$title, Body=$body');
  }

  // Schedule a notification (placeholder)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // This is a placeholder for actual scheduled notification
    debugPrint('Scheduled Notification: ID=$id, Title=$title, Body=$body, Date=$scheduledDate');
  }

  // Cancel a notification (placeholder)
  Future<void> cancelNotification(int id) async {
    // This is a placeholder for actual notification cancellation
    debugPrint('Notification cancelled: ID=$id');
  }

  // Cancel all notifications (placeholder)
  Future<void> cancelAllNotifications() async {
    // This is a placeholder for actual notification cancellation
    debugPrint('All notifications cancelled');
  }

  // Show budget alert notification
  Future<void> showBudgetAlert(BudgetModel budget) async {
    final int id = budget.id.hashCode;
    String title;
    String body;

    if (budget.isOverBudget) {
      title = 'Budget Exceeded!';
      body = 'You have exceeded your ${budget.category} budget by \$${(budget.spent - budget.amount).toStringAsFixed(2)}.';
    } else {
      title = 'Budget Alert';
      body = 'You have used ${budget.percentageUsed.toStringAsFixed(0)}% of your ${budget.category} budget.';
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
    );
  }

  // Show in-app budget alert dialog
  void showBudgetAlertDialog(BuildContext context, BudgetModel budget) {
    // Only show alert if budget alert is enabled and threshold is reached or exceeded
    if (!budget.alertEnabled) return;

    if (budget.isOverBudget || budget.isNearThreshold) {
      debugPrint('NotificationService: Showing budget alert dialog for ${budget.category}');

      // Show the dialog
      showDialog(
        context: context,
        builder: (context) => BudgetAlertDialog(budget: budget),
      );
    }
  }

  // Schedule debt reminder notification
  Future<void> scheduleDebtReminder(DebtModel debt) async {
    if (debt.dueDate == null) return;

    final int id = debt.id.hashCode;

    // Schedule reminder 1 day before due date
    final reminderDate = debt.dueDate!.subtract(const Duration(days: 1));

    // Only schedule if reminder date is in the future
    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Payment Due Tomorrow',
        body: 'Your payment of ${debt.remainingAmount.toStringAsFixed(2)} for "${debt.description}" is due tomorrow.',
        scheduledDate: reminderDate,
      );
    }

    // Schedule reminder on due date
    if (debt.dueDate!.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id + 1, // Different ID for different notification
        title: 'Payment Due Today',
        body: 'Your payment of ${debt.remainingAmount.toStringAsFixed(2)} for "${debt.description}" is due today.',
        scheduledDate: debt.dueDate!,
      );
    }
  }

  // Cancel debt reminder notifications
  Future<void> cancelDebtReminders(DebtModel debt) async {
    final int id = debt.id.hashCode;
    await cancelNotification(id);
    await cancelNotification(id + 1);
  }

  // Show daily spending summary notification
  Future<void> showDailySpendingSummary(double totalSpent, double budgetRemaining) async {
    String title = 'Daily Spending Summary';
    String body;

    if (budgetRemaining >= 0) {
      body = 'Today you spent ₹${totalSpent.toStringAsFixed(2)}. Budget remaining: ₹${budgetRemaining.toStringAsFixed(2)}';
    } else {
      body = 'Today you spent ₹${totalSpent.toStringAsFixed(2)}. You are ₹${(-budgetRemaining).toStringAsFixed(2)} over budget!';
    }

    await showNotification(
      id: 1001, // Fixed ID for daily summary
      title: title,
      body: body,
    );
  }

  // Show simple budget alert
  Future<void> showSimpleBudgetAlert(String category, double spent, double budget) async {
    final percentage = (spent / budget * 100).round();

    String title = 'Budget Alert';
    String body = '$category: ₹${spent.toStringAsFixed(2)} spent ($percentage% of budget)';

    if (spent > budget) {
      title = 'Budget Exceeded!';
      body = '$category: Over budget by ₹${(spent - budget).toStringAsFixed(2)}';
    }

    await showNotification(
      id: category.hashCode,
      title: title,
      body: body,
    );
  }

  // Show friend payment reminder
  Future<void> showFriendPaymentReminder(String friendName, double amount, String type) async {
    String title = 'Payment Reminder';
    String body;

    if (type == 'owe') {
      body = 'You owe ₹${amount.toStringAsFixed(2)} to $friendName';
    } else {
      body = '$friendName owes you ₹${amount.toStringAsFixed(2)}';
    }

    await showNotification(
      id: friendName.hashCode + type.hashCode,
      title: title,
      body: body,
    );
  }
}
