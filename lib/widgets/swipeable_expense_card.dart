import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/expense_model.dart';

class SwipeableExpenseCard extends StatefulWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;
  final bool showMood;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  const SwipeableExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onShare,
    this.showMood = true,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<SwipeableExpenseCard> createState() => _SwipeableExpenseCardState();
}

class _SwipeableExpenseCardState extends State<SwipeableExpenseCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Find category icon
    final categoryInfo = AppConstants.expenseCategories.firstWhere(
      (c) => c['name'] == widget.expense.category,
      orElse: () => {'name': widget.expense.category, 'icon': Icons.category},
    );

    // Format date
    final formattedDate = DateFormat(AppConstants.dateFormat).format(widget.expense.date);

    // Get mood icon if available
    IconData? moodIcon;
    if (widget.showMood && widget.expense.mood != null) {
      final moodInfo = AppConstants.moodOptions.firstWhere(
        (m) => m['name'] == widget.expense.mood,
        orElse: () => {'name': widget.expense.mood, 'icon': null},
      );
      moodIcon = moodInfo['icon'] as IconData?;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
            child: Slidable(
              key: ValueKey(widget.expense.id),
              startActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      widget.onEdit?.call();
                    },
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      widget.onDuplicate?.call();
                    },
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                    icon: Icons.copy,
                    label: 'Copy',
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      widget.onShare?.call();
                    },
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    icon: Icons.share,
                    label: 'Share',
                  ),
                  SlidableAction(
                    onPressed: (context) {
                      _showDeleteConfirmation(context);
                    },
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Delete',
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ],
              ),
              child: _buildExpenseCard(categoryInfo, formattedDate, moodIcon),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> categoryInfo, String formattedDate, IconData? moodIcon) {
    return Card(
      elevation: widget.isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          _scaleController.forward().then((_) {
            _scaleController.reverse();
          });
          widget.onTap();
        },
        onLongPress: widget.onSelectionChanged,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              // Selection checkbox
              if (widget.onSelectionChanged != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),

              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryInfo['icon'] as IconData,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.mediumSpacing),

              // Expense details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.expense.description,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.expense.isGroupExpense)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Group',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.expense.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (moodIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            moodIcon,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.expense.amount < 0 ? '-' : ''}${AppConstants.currencySymbol}${widget.expense.amount.abs().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.expense.amount < 0 
                          ? AppTheme.successColor 
                          : Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  if (widget.expense.isGroupExpense && widget.expense.userShare != null)
                    Text(
                      'Your share: ${AppConstants.currencySymbol}${widget.expense.userShare!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text('Are you sure you want to delete "${widget.expense.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
