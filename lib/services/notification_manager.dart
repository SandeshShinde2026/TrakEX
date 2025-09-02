import 'notification_service.dart';

class NotificationManager {
  static final NotificationService _notificationService = NotificationService();

  // Initialize notifications
  static Future<void> initialize() async {
    await _notificationService.initialize();
  }

  // Daily spending summary notification
  static Future<void> scheduleDailySpendingSummary({
    required double totalSpent,
    required double budgetLimit,
    required List<String> topCategories,
  }) async {
    final budgetRemaining = budgetLimit - totalSpent;
    String title = 'Daily Spending Summary';
    String body;

    if (budgetRemaining >= 0) {
      body = 'Today: ₹${totalSpent.toStringAsFixed(0)} spent. ₹${budgetRemaining.toStringAsFixed(0)} remaining.';
    } else {
      body = 'Today: ₹${totalSpent.toStringAsFixed(0)} spent. Over budget by ₹${(-budgetRemaining).toStringAsFixed(0)}!';
    }

    if (topCategories.isNotEmpty) {
      body += ' Top: ${topCategories.first}';
    }

    await _notificationService.showNotification(
      id: 2001,
      title: title,
      body: body,
    );
  }

  // Budget alert notifications
  static Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    String title;
    String body;

    if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body = '$category: Over by ₹${(spent - budget).toStringAsFixed(0)}';
    } else if (percentage >= 90) {
      title = '⚠️ Budget Warning';
      body = '$category: ${percentage.round()}% used (₹${spent.toStringAsFixed(0)}/₹${budget.toStringAsFixed(0)})';
    } else if (percentage >= 75) {
      title = '📊 Budget Update';
      body = '$category: ${percentage.round()}% used';
    } else {
      return; // Don't notify for low usage
    }

    await _notificationService.showNotification(
      id: category.hashCode,
      title: title,
      body: body,
    );
  }

  // Friend payment reminders
  static Future<void> showFriendPaymentReminder({
    required String friendName,
    required double amount,
    required bool youOwe,
    int? daysSince,
  }) async {
    String title;
    String body;

    if (youOwe) {
      title = '💰 Payment Reminder';
      body = 'You owe ₹${amount.toStringAsFixed(0)} to $friendName';
      if (daysSince != null && daysSince > 7) {
        body += ' ($daysSince days ago)';
      }
    } else {
      title = '💸 Payment Due';
      body = '$friendName owes you ₹${amount.toStringAsFixed(0)}';
      if (daysSince != null && daysSince > 7) {
        body += ' ($daysSince days ago)';
      }
    }

    await _notificationService.showNotification(
      id: friendName.hashCode + (youOwe ? 1 : 2),
      title: title,
      body: body,
    );
  }

  // Weekly spending summary
  static Future<void> showWeeklySpendingSummary({
    required double weeklyTotal,
    required double previousWeek,
    required Map<String, double> topCategories,
  }) async {
    final difference = weeklyTotal - previousWeek;
    final isIncrease = difference > 0;

    String title = '📈 Weekly Summary';
    String body = 'This week: ₹${weeklyTotal.toStringAsFixed(0)}';

    if (previousWeek > 0) {
      if (isIncrease) {
        body += ' (+₹${difference.toStringAsFixed(0)} vs last week)';
      } else {
        body += ' (-₹${(-difference).toStringAsFixed(0)} vs last week)';
      }
    }

    if (topCategories.isNotEmpty) {
      final topCategory = topCategories.entries.first;
      body += '. Top: ${topCategory.key} (₹${topCategory.value.toStringAsFixed(0)})';
    }

    await _notificationService.showNotification(
      id: 3001,
      title: title,
      body: body,
    );
  }

  // Monthly budget reset reminder
  static Future<void> showMonthlyBudgetReset() async {
    await _notificationService.showNotification(
      id: 4001,
      title: '🗓️ New Month Started',
      body: 'Your monthly budget has been reset. Time for a fresh start!',
    );
  }

  // Expense milestone notifications
  static Future<void> showExpenseMilestone({
    required int expenseCount,
    required double totalAmount,
  }) async {
    String title;
    String body;

    if (expenseCount == 100) {
      title = '🎉 Milestone Reached!';
      body = '100 expenses tracked! Total: ₹${totalAmount.toStringAsFixed(0)}';
    } else if (expenseCount == 500) {
      title = '🏆 Amazing Progress!';
      body = '500 expenses tracked! You\'re a budgeting pro!';
    } else if (expenseCount == 1000) {
      title = '🌟 Incredible Achievement!';
      body = '1000 expenses tracked! Master of money management!';
    } else {
      return; // Only notify for specific milestones
    }

    await _notificationService.showNotification(
      id: 5000 + expenseCount,
      title: title,
      body: body,
    );
  }

  // Savings achievement notifications
  static Future<void> showSavingsAchievement({
    required double savedAmount,
    required double budgetLimit,
  }) async {
    final savingsPercentage = (savedAmount / budgetLimit * 100).round();

    if (savingsPercentage < 10) return; // Only notify for meaningful savings

    String title = '💰 Great Savings!';
    String body = 'You saved ₹${savedAmount.toStringAsFixed(0)} this month ($savingsPercentage% of budget)!';

    await _notificationService.showNotification(
      id: 6001,
      title: title,
      body: body,
    );
  }

  // Group expense settlement reminder
  static Future<void> showGroupExpenseReminder({
    required String expenseTitle,
    required double yourShare,
    required String paidBy,
  }) async {
    await _notificationService.showNotification(
      id: expenseTitle.hashCode,
      title: '👥 Group Expense',
      body: 'Your share for "$expenseTitle": ₹${yourShare.toStringAsFixed(0)} (paid by $paidBy)',
    );
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationService.cancelNotification(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }
}
