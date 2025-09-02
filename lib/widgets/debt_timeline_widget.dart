import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/debt_model.dart';

class DebtTimelineWidget extends StatefulWidget {
  final List<DebtModel> debts;
  final String friendName;
  final bool showPayments;

  const DebtTimelineWidget({
    super.key,
    required this.debts,
    required this.friendName,
    this.showPayments = true,
  });

  @override
  State<DebtTimelineWidget> createState() => _DebtTimelineWidgetState();
}

class _DebtTimelineWidgetState extends State<DebtTimelineWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.debts.isEmpty) {
      return _buildEmptyState();
    }

    final sortedDebts = widget.debts.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Debt Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSummaryChip(sortedDebts),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Timeline
            _buildTimeline(sortedDebts),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.3,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.largeSpacing),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'No debt history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Debt transactions will appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(List<DebtModel> debts) {
    final totalAmount = debts.fold<double>(0, (sum, debt) => sum + debt.amount);
    final paidDebts = debts.where((debt) => debt.status == 'paid').length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${AppConstants.currencySymbol}${totalAmount.toStringAsFixed(0)} • $paidDebts/${debts.length} paid',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTimeline(List<DebtModel> debts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        final isLast = index == debts.length - 1;
        
        return _buildTimelineItem(debt, isLast, index);
      },
    );
  }

  Widget _buildTimelineItem(DebtModel debt, bool isLast, int index) {
    final statusColor = _getStatusColor(debt.status);
    final statusIcon = _getStatusIcon(debt.status);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: AppTheme.mediumSpacing),
        
        // Debt details
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.mediumSpacing),
            child: _buildDebtCard(debt, statusColor),
          ),
        ),
      ],
    ).animate(delay: Duration(milliseconds: 100 * index)).slideX(
      begin: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    ).fadeIn();
  }

  Widget _buildDebtCard(DebtModel debt, Color statusColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    debt.description,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(debt.status, statusColor),
              ],
            ),
            const SizedBox(height: 8),
            
            // Amount and date
            Row(
              children: [
                Text(
                  '${AppConstants.currencySymbol}${debt.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(debt.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            // Payment history
            if (widget.showPayments && debt.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPaymentHistory(debt),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    String label;
    switch (status) {
      case 'pending':
        label = 'Pending';
        break;
      case 'partially_paid':
        label = 'Partial';
        break;
      case 'paid':
        label = 'Paid';
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(DebtModel debt) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment History',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          ...debt.payments.map((payment) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 12,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${AppConstants.currencySymbol}${payment.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(payment.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'partially_paid':
        return AppTheme.primaryColor;
      case 'paid':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'partially_paid':
        return Icons.hourglass_bottom;
      case 'paid':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

// Enhanced trust score visualization
class TrustScoreVisualization extends StatefulWidget {
  final double trustScore;
  final String friendName;
  final int totalTransactions;
  final double totalAmount;

  const TrustScoreVisualization({
    super.key,
    required this.trustScore,
    required this.friendName,
    required this.totalTransactions,
    required this.totalAmount,
  });

  @override
  State<TrustScoreVisualization> createState() => _TrustScoreVisualizationState();
}

class _TrustScoreVisualizationState extends State<TrustScoreVisualization>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.trustScore / 100,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trustLevel = _getTrustLevel(widget.trustScore);
    final trustColor = _getTrustColor(widget.trustScore);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: trustColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trust Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Circular progress indicator
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(trustColor),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${widget.trustScore.toInt()}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: trustColor,
                          ),
                        ),
                        Text(
                          trustLevel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: trustColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: AppTheme.mediumSpacing),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Transactions',
                  widget.totalTransactions.toString(),
                  Icons.swap_horiz,
                ),
                _buildStatItem(
                  'Total Amount',
                  '${AppConstants.currencySymbol}${widget.totalAmount.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    ).scale(
      begin: const Offset(0.8, 0.8),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getTrustLevel(double score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  Color _getTrustColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.primaryColor;
    if (score >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
