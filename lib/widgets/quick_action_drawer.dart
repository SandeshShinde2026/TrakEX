import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';

class QuickActionDrawer extends StatefulWidget {
  final VoidCallback? onAddExpense;
  final VoidCallback? onSetBudget;
  final VoidCallback? onAddFriend;
  final VoidCallback? onViewAnalytics;
  final VoidCallback? onCalculator;
  final VoidCallback? onScanReceipt;

  const QuickActionDrawer({
    super.key,
    this.onAddExpense,
    this.onSetBudget,
    this.onAddFriend,
    this.onViewAnalytics,
    this.onCalculator,
    this.onScanReceipt,
  });

  @override
  State<QuickActionDrawer> createState() => _QuickActionDrawerState();
}

class _QuickActionDrawerState extends State<QuickActionDrawer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _closeDrawer() {
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
            child: GestureDetector(
              onTap: _closeDrawer,
              child: Column(
                children: [
                  Expanded(child: Container()), // Spacer
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildDrawerContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerContent() {
    final quickActions = [
      QuickActionItem(
        icon: Icons.add_circle,
        label: 'Add Expense',
        color: AppTheme.primaryColor,
        onTap: () {
          _closeDrawer();
          widget.onAddExpense?.call();
        },
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet,
        label: 'Set Budget',
        color: AppTheme.successColor,
        onTap: () {
          _closeDrawer();
          widget.onSetBudget?.call();
        },
      ),
      QuickActionItem(
        icon: Icons.person_add,
        label: 'Add Friend',
        color: AppTheme.warningColor,
        onTap: () {
          _closeDrawer();
          widget.onAddFriend?.call();
        },
      ),
      QuickActionItem(
        icon: Icons.analytics,
        label: 'Analytics',
        color: Colors.purple,
        onTap: () {
          _closeDrawer();
          widget.onViewAnalytics?.call();
        },
      ),
      QuickActionItem(
        icon: Icons.calculate,
        label: 'Calculator',
        color: Colors.teal,
        onTap: () {
          _closeDrawer();
          widget.onCalculator?.call();
        },
      ),
      QuickActionItem(
        icon: Icons.camera_alt,
        label: 'Scan Receipt',
        color: Colors.indigo,
        onTap: () {
          _closeDrawer();
          widget.onScanReceipt?.call();
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _closeDrawer,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Actions grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.mediumSpacing),
            child: AnimationLimiter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: quickActions.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 3,
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildActionItem(quickActions[index], index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: AppTheme.largeSpacing),
        ],
      ),
    );
  }

  Widget _buildActionItem(QuickActionItem action, int index) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: action.color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().scale(
      delay: Duration(milliseconds: 50 * index),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
    );
  }
}

class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// Helper function to show the quick action drawer
void showQuickActionDrawer(
  BuildContext context, {
  VoidCallback? onAddExpense,
  VoidCallback? onSetBudget,
  VoidCallback? onAddFriend,
  VoidCallback? onViewAnalytics,
  VoidCallback? onCalculator,
  VoidCallback? onScanReceipt,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => QuickActionDrawer(
      onAddExpense: onAddExpense,
      onSetBudget: onSetBudget,
      onAddFriend: onAddFriend,
      onViewAnalytics: onViewAnalytics,
      onCalculator: onCalculator,
      onScanReceipt: onScanReceipt,
    ),
  );
}
