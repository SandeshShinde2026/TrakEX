import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/debt_model.dart';
import '../../models/karma_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/karma_provider.dart';
import '../../widgets/debt_item.dart';
import '../../widgets/karma_badge_widget.dart';
import '../../widgets/payment_button.dart';
import 'add_debt_screen.dart';

// Enum for direct debt filter options
enum DirectDebtFilter {
  all,
  theyOwe,
  youOwe,
}

class FriendDetailScreen extends StatefulWidget {
  final UserModel friend;

  const FriendDetailScreen({
    super.key,
    required this.friend,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<DebtModel> _debts = [];
  List<DebtModel> _directDebts = [];
  List<DebtModel> _groupExpenseDebts = [];

  // Overall totals (sum of direct and group)
  double _totalOwed = 0;
  double _totalOwing = 0;
  double _netBalance = 0;

  // Direct debt filter
  DirectDebtFilter _directDebtFilter = DirectDebtFilter.all;

  // Karma badge info
  Map<String, dynamic>? _karmaBadgeInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two main tabs: Direct Debts and Group Expenses

    // Load debts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDebts();
      _loadKarmaBadgeInfo();
    });
  }

  // Load karma badge info for the friend
  Future<void> _loadKarmaBadgeInfo() async {
    try {
      final karmaProvider = Provider.of<KarmaProvider>(context, listen: false);
      final badgeInfo = await karmaProvider.getUserBadgeInfo(widget.friend.id);

      setState(() {
        _karmaBadgeInfo = badgeInfo;
      });
    } catch (e) {
      debugPrint('Error loading karma badge info: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);

      debugPrint('FriendDetailScreen: Loading debts between ${authProvider.userModel!.id} and ${widget.friend.id}');

      // Load all debts between current user and friend
      await debtProvider.loadDebtsBetweenUsers(
        authProvider.userModel!.id,
        widget.friend.id,
      );

      // Update local state
      setState(() {
        _debts = debtProvider.debts;
        _directDebts = debtProvider.directFriendDebts;
        _groupExpenseDebts = debtProvider.groupExpenseFriendDebts;

        debugPrint('FriendDetailScreen: Loaded ${_debts.length} total debts');
        debugPrint('FriendDetailScreen: Loaded ${_directDebts.length} direct debts');
        debugPrint('FriendDetailScreen: Loaded ${_groupExpenseDebts.length} group expense debts');

        _calculateTotals();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('FriendDetailScreen: Error loading debts: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading debts: $e')),
        );
      }
    }
  }

  // Variables for direct debts
  double _directTotalOwed = 0;
  double _directTotalOwing = 0;
  double _directNetBalance = 0;

  // Variables for group expenses
  double _groupTotalOwed = 0;
  double _groupTotalOwing = 0;
  double _groupNetBalance = 0;

  void _calculateTotals() {
    // Reset all totals
    _totalOwed = 0;
    _totalOwing = 0;
    _directTotalOwed = 0;
    _directTotalOwing = 0;
    _groupTotalOwed = 0;
    _groupTotalOwing = 0;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel!.id;

    // Calculate direct debt totals
    for (var debt in _directDebts) {
      // Skip paid debts when calculating totals
      if (debt.status == PaymentStatus.paid) {
        continue;
      }

      if (debt.creditorId == currentUserId) {
        // Friend owes current user
        _directTotalOwed += debt.remainingAmount;
      } else {
        // Current user owes friend
        _directTotalOwing += debt.remainingAmount;
      }
    }

    // Calculate group expense totals
    for (var debt in _groupExpenseDebts) {
      // Skip paid debts when calculating totals
      if (debt.status == PaymentStatus.paid) {
        continue;
      }

      if (debt.creditorId == currentUserId) {
        // Friend owes current user
        _groupTotalOwed += debt.remainingAmount;
      } else {
        // Current user owes friend
        _groupTotalOwing += debt.remainingAmount;
      }
    }

    // Calculate net balances
    _directNetBalance = _directTotalOwed - _directTotalOwing;
    _groupNetBalance = _groupTotalOwed - _groupTotalOwing;

    // For backward compatibility, set the overall totals
    _totalOwed = _directTotalOwed + _groupTotalOwed;
    _totalOwing = _directTotalOwing + _groupTotalOwing;
    _netBalance = _directNetBalance + _groupNetBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.friend.name),
            if (_karmaBadgeInfo != null) ...[
              const SizedBox(width: 8),
              KarmaBadgeWidget(
                badgeLevel: _karmaBadgeInfo!['badgeLevel'] ?? KarmaBadgeLevel.leastTrusted,
                badgeEmoji: _karmaBadgeInfo!['badgeEmoji'] ?? '⚫',
                nickname: _karmaBadgeInfo!['nickname'] ?? 'The Ghost Debtor 👻',
                badgeName: _karmaBadgeInfo!['badgeName'] ?? 'Least Trusted',
                totalPoints: _karmaBadgeInfo!['totalPoints'] ?? 0,
                isCompact: true,
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.pushNamed(context, '/karma_leaderboard');
            },
            tooltip: 'Karma Leaderboard',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDebts();
              _loadKarmaBadgeInfo();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearHistoryDialog,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildBalanceSummary(),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          indicatorColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          tabs: const [
                            Tab(text: 'Direct Debts'),
                            Tab(text: 'Group Expenses'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDirectDebtsTab(),
                    _buildGroupExpensesTab(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDebtScreen(friend: widget.friend),
            ),
          ).then((_) => _loadDebts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceSummary() {
    // Overall balance text and color
    final balanceText = _netBalance >= 0
        ? '${widget.friend.name} owes you'
        : 'You owe ${widget.friend.name}';

    final balanceAmount = '${AppConstants.currencySymbol}${_netBalance.abs().toStringAsFixed(2)}';

    final balanceColor = _netBalance > 0
        ? Colors.green
        : _netBalance < 0
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.all(AppTheme.mediumSpacing),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Overall balance
            Text(
              'Overall Balance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              balanceText,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              balanceAmount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceItem(
                  'Total They Owe',
                  _totalOwed,
                  Colors.green,
                ),
                _buildBalanceItem(
                  'Total You Owe',
                  _totalOwing,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Direct Debts Section
            Text(
              'Direct Debts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceItem(
                  'They owe',
                  _directTotalOwed,
                  Colors.green,
                ),
                _buildBalanceItem(
                  'You owe',
                  _directTotalOwing,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Net: ${AppConstants.currencySymbol}${_directNetBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _directNetBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),

            // Add payment button if user owes money
            if (_directTotalOwing > 0) ...[
              const SizedBox(height: 12),
              PaymentButton(
                friend: widget.friend,
                amount: _directTotalOwing,
                description: 'Payment to ${widget.friend.name} for direct debts',
                isOutlined: false,
                color: Theme.of(context).primaryColor,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Group Expenses Section
            Text(
              'Group Expenses',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceItem(
                  'They owe',
                  _groupTotalOwed,
                  Colors.green,
                ),
                _buildBalanceItem(
                  'You owe',
                  _groupTotalOwing,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Net: ${AppConstants.currencySymbol}${_groupNetBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _groupNetBalance >= 0 ? Colors.green : Colors.red,
              ),
            ),

            // Add payment button if user owes money in group expenses
            if (_groupTotalOwing > 0) ...[
              const SizedBox(height: 12),
              PaymentButton(
                friend: widget.friend,
                amount: _groupTotalOwing,
                description: 'Payment to ${widget.friend.name} for group expenses',
                isOutlined: false,
                color: Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: amount > 0 ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDirectDebtsTab() {
    if (_directDebts.isEmpty) {
      return _buildEmptyState(
        'No Direct Debts',
        'Direct transactions with ${widget.friend.name} will appear here',
        Icons.receipt_long,
      );
    }

    // Show direct debts with sub-tabs
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.smallSpacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectDebtFilterButton(
                'All',
                Icons.list,
                _directDebtFilter == DirectDebtFilter.all,
                () => setState(() => _directDebtFilter = DirectDebtFilter.all),
              ),
              _buildDirectDebtFilterButton(
                'They Owe',
                Icons.arrow_downward,
                _directDebtFilter == DirectDebtFilter.theyOwe,
                () => setState(() => _directDebtFilter = DirectDebtFilter.theyOwe),
              ),
              _buildDirectDebtFilterButton(
                'You Owe',
                Icons.arrow_upward,
                _directDebtFilter == DirectDebtFilter.youOwe,
                () => setState(() => _directDebtFilter = DirectDebtFilter.youOwe),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildFilteredDirectDebtsList(),
        ),
      ],
    );
  }

  Widget _buildDirectDebtFilterButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    // Determine colors based on label and selection state
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    Color iconColor;

    if (isSelected) {
      if (label == 'They Owe') {
        backgroundColor = Colors.green.withAlpha(50);
        textColor = Colors.green;
        borderColor = Colors.green;
        iconColor = Colors.green;
      } else if (label == 'You Owe') {
        backgroundColor = Colors.red.withAlpha(50);
        textColor = Colors.red;
        borderColor = Colors.red;
        iconColor = Colors.red;
      } else {
        backgroundColor = Theme.of(context).primaryColor.withAlpha(50);
        textColor = Theme.of(context).primaryColor;
        borderColor = Theme.of(context).primaryColor;
        iconColor = Theme.of(context).primaryColor;
      }
    } else {
      backgroundColor = Colors.transparent;
      textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
      borderColor = Theme.of(context).dividerColor;
      iconColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.mediumSpacing,
          vertical: AppTheme.smallSpacing,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredDirectDebtsList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    List<DebtModel> filteredDebts = [];

    switch (_directDebtFilter) {
      case DirectDebtFilter.all:
        filteredDebts = _directDebts;
        break;
      case DirectDebtFilter.theyOwe:
        filteredDebts = _directDebts.where((debt) {
          return debt.creditorId == authProvider.userModel!.id;
        }).toList();
        break;
      case DirectDebtFilter.youOwe:
        filteredDebts = _directDebts.where((debt) {
          return debt.debtorId == authProvider.userModel!.id;
        }).toList();
        break;
    }

    if (filteredDebts.isEmpty) {
      String title = 'No Direct Debts';
      String subtitle = 'Direct transactions with ${widget.friend.name} will appear here';
      IconData icon = Icons.receipt_long;

      switch (_directDebtFilter) {
        case DirectDebtFilter.all:
          title = 'No Direct Debts';
          subtitle = 'Direct transactions with ${widget.friend.name} will appear here';
          icon = Icons.receipt_long;
          break;
        case DirectDebtFilter.theyOwe:
          title = '${widget.friend.name} doesn\'t owe you';
          subtitle = 'Direct transactions where they owe you will appear here';
          icon = Icons.arrow_downward;
          break;
        case DirectDebtFilter.youOwe:
          title = 'You don\'t owe ${widget.friend.name}';
          subtitle = 'Direct transactions where you owe them will appear here';
          icon = Icons.arrow_upward;
          break;
      }

      return _buildEmptyState(title, subtitle, icon);
    }

    return _buildDebtsList(filteredDebts);
  }

  Widget _buildGroupExpensesTab() {
    if (_groupExpenseDebts.isEmpty) {
      return _buildEmptyState(
        'No Group Expenses',
        'Group expenses with ${widget.friend.name} will appear here',
        Icons.group,
      );
    }

    return _buildDebtsList(_groupExpenseDebts);
  }

  Widget _buildDebtsList(List<DebtModel> debts) {
    // Sort debts by date (newest first)
    final sortedDebts = List<DebtModel>.from(debts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      itemCount: sortedDebts.length,
      itemBuilder: (context, index) {
        return DebtItem(
          debt: sortedDebts[index],
          friend: widget.friend,
          onStatusChanged: _loadDebts,
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.largeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for clearing transaction history
  void _showClearHistoryDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to perform this action')),
      );
      return;
    }

    final userId = authProvider.userModel!.id;
    final friendId = widget.friend.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Transaction History'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 16,
            ),
            children: [
              const TextSpan(
                text: 'Are you sure you want to clear all transaction history with ',
              ),
              TextSpan(
                text: widget.friend.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: '? This will permanently delete all debts, payments, and group expenses between you two. This action cannot be undone.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              // Use the async/await in a separate function to avoid BuildContext issues
              _performClearHistory(userId, friendId, debtProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }

  // Helper method to show a snackbar safely
  void _showSnackBar(String message, Color backgroundColor) {
    // Only show the snackbar if the widget is still mounted
    if (mounted) {
      // Use a post-frame callback to ensure we're not in the middle of a build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
            ),
          );
        }
      });
    }
  }

  // Perform the clear history operation
  Future<void> _performClearHistory(
    String userId,
    String friendId,
    DebtProvider debtProvider
  ) async {
    final success = await debtProvider.clearTransactionHistory(userId, friendId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Reset all the balance variables
      _totalOwed = 0;
      _totalOwing = 0;
      _netBalance = 0;
      _directTotalOwed = 0;
      _directTotalOwing = 0;
      _directNetBalance = 0;
      _groupTotalOwed = 0;
      _groupTotalOwing = 0;
      _groupNetBalance = 0;

      // Show success message
      _showSnackBar(
        'Transaction history cleared successfully',
        Colors.green,
      );

      // Reload debts to refresh the UI
      _loadDebts();
    } else {
      // Show error message
      _showSnackBar(
        debtProvider.error ?? 'Failed to clear transaction history',
        Colors.red,
      );
    }
  }
}

// Custom SliverPersistentHeaderDelegate for the tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
