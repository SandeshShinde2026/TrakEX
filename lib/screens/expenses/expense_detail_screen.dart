import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/currency_amount_display.dart';
import 'edit_expense_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  Map<String, String> _userIdToName = {};

  @override
  void initState() {
    super.initState();
    _loadFriendNames();
  }

  Future<void> _loadFriendNames() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);

      if (authProvider.isAuthenticated) {
        // Load friends if not already loaded
        if (friendProvider.friends.isEmpty) {
          await friendProvider.loadFriends(authProvider.userModel!.id);
        }

        // Create a map of user IDs to names
        final Map<String, String> idToName = {};
        for (var friend in friendProvider.friends) {
          idToName[friend.id] = friend.name;
        }

        if (mounted) {
          setState(() {
            _userIdToName = idToName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading friend names: $e');
    }
  }

  // Extract friend name from reimbursement description
  String _getReimbursementDescription() {
    if (widget.expense.category != 'Reimbursement') {
      return widget.expense.description;
    }

    // Try to extract the friend name from the description
    final description = widget.expense.description;

    // Check if description contains "from" (for reimbursements)
    if (description.contains('from')) {
      // Extract the part after "from" and before the colon
      final fromIndex = description.indexOf('from') + 5;
      final colonIndex = description.indexOf(':', fromIndex);

      if (colonIndex > fromIndex) {
        final friendId = description.substring(fromIndex, colonIndex).trim();

        // Try to find the friend name in our map
        if (_userIdToName.containsKey(friendId)) {
          // Replace the ID with the name
          return description.replaceRange(
            fromIndex,
            colonIndex,
            _userIdToName[friendId]!
          );
        }
      }
    }

    return description;
  }

  IconData _getCategoryIcon() {
    final category = AppConstants.expenseCategories.firstWhere(
      (cat) => cat['name'] == widget.expense.category,
      orElse: () => AppConstants.expenseCategories.last,
    );
    return category['icon'];
  }

  IconData? _getMoodIcon() {
    if (widget.expense.mood == null) return null;

    final mood = AppConstants.moodOptions.firstWhere(
      (m) => m['name'] == widget.expense.mood,
      orElse: () => {'icon': Icons.mood},
    );
    return mood['icon'];
  }

  Future<void> _deleteExpense(BuildContext ctx) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Store the provider before the async gap
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final expenseId = widget.expense.id;

    final success = await expenseProvider.deleteExpense(
      expenseId,
      context: null, // Don't pass context across async gap
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expenseProvider.error ?? 'Failed to delete expense'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Get participant name from user ID
  String _getParticipantName(String userId) {
    return _userIdToName[userId] ?? userId;
  }

  // Navigate to edit screen with proper context handling
  Future<void> _navigateToEditScreen(ExpenseModel expense) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    );

    // Check mounted again after the async gap
    if (!mounted) return;

    // If the expense was successfully updated, return true to the previous screen
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expense = widget.expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _navigateToEditScreen(expense);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteExpense(context),
          ),
        ],
      ),
      body: expenseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount and Category
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCategoryIcon(),
                                size: 32,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: AppTheme.smallSpacing),
                              Text(
                                expense.category,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          CurrencyAmountDisplay(
                            expense: expense,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: expense.effectiveAmount < 0 ? Colors.green : null,
                            ),
                            showConversionInfo: true, // Show full conversion info in detail screen
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          Text(
                            DateFormat(AppConstants.dateFormat).format(expense.date),
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),

                  // Currency Information (if converted)
                  if (expense.isConverted) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Currency Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Original Amount:'),
                                Text(
                                  '${expense.currency.symbol}${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Converted Amount:'),
                                Text(
                                  '${expense.convertedAmount?.toStringAsFixed(2)} ${expense.convertedCurrencyCode}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (expense.exchangeRate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Exchange Rate:'),
                                  Text(
                                    '1 ${expense.currencyCode} = ${expense.exchangeRate?.toStringAsFixed(4)} ${expense.convertedCurrencyCode}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                  ],

                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          Text(_getReimbursementDescription()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),

                  // Mood
                  if (expense.mood != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mood',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            Row(
                              children: [
                                Icon(_getMoodIcon()),
                                const SizedBox(width: AppTheme.smallSpacing),
                                Text(expense.mood!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                  ],

                  // Group Expense Details
                  if (expense.isGroupExpense && expense.participants.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Group Expense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            const Text('Participants:'),
                            const SizedBox(height: AppTheme.smallSpacing),
                            ...expense.participants.map((participant) {
                              final userId = participant['userId'] as String;
                              final participantName = _getParticipantName(userId);

                              // Check if this participant is the current user
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final isCurrentUser = authProvider.userModel != null &&
                                                   userId == authProvider.userModel!.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$participantName${isCurrentUser ? ' (you)' : ''}'),
                                    Text(
                                      '${AppConstants.currencySymbol}${(participant['share'] as num).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                  ],

                  // Payment Notes (for group expenses)
                  if (expense.isGroupExpense && expense.paymentNotes != null && expense.paymentNotes!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppTheme.smallSpacing),
                            ...expense.paymentNotes!.map((payment) {
                              final amount = (payment['amount'] as num).toDouble();
                              final date = (payment['date'] as Timestamp).toDate();
                              final description = payment['description'] as String;
                              final payerId = payment['payerId'] as String;
                              final payerName = _getParticipantName(payerId);

                              // Check if this payer is the current user
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final isCurrentUser = authProvider.userModel != null &&
                                                   payerId == authProvider.userModel!.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$payerName${isCurrentUser ? ' (you)' : ''}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${amount >= 0 ? '+' : '-'}${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: amount >= 0 ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      description,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      DateFormat('MMM d, yyyy h:mm a').format(date),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                  ],

                  // Images
                  if (expense.imageUrls != null && expense.imageUrls!.isNotEmpty) ...[
                    const Text(
                      'Receipt Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: expense.imageUrls!.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // Show full-screen image
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(),
                                    body: Center(
                                      child: Image.network(
                                        expense.imageUrls![index],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: AppTheme.smallSpacing),
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(expense.imageUrls![index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
