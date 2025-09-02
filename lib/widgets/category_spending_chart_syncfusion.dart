import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_helper.dart';

class CategorySpendingChart extends StatefulWidget {
  final Map<String, double> categorySpending;

  const CategorySpendingChart({
    super.key,
    required this.categorySpending,
  });

  @override
  State<CategorySpendingChart> createState() => _CategorySpendingChartState();
}

class _CategorySpendingChartState extends State<CategorySpendingChart> {
  int _selectedIndex = -1;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categorySpending.isEmpty) {
      return const Center(
        child: Text('No category data available'),
      );
    }

    // Sort categories by amount (descending)
    final sortedCategories = widget.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total spending
    final totalSpending = widget.categorySpending.values.fold(
      0.0, (sum, amount) => sum + amount);

    // Convert to chart data
    final List<CategoryData> chartData = [];
    for (var entry in sortedCategories) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = totalSpending > 0 ? (amount / totalSpending) * 100 : 0;

      // Find the category icon
      final categoryInfo = AppConstants.expenseCategories.firstWhere(
        (c) => c['name'] == category,
        orElse: () => {'name': category, 'icon': Icons.category},
      );

      chartData.add(CategoryData(
        category: category,
        amount: amount,
        percentage: percentage.toDouble(),
        icon: categoryInfo['icon'] as IconData,
        color: _getCategoryColor(category),
      ));
    }

    // Calculate responsive chart height
    final chartHeight = ResponsiveHelper.getResponsiveValue<double>(
      context: context,
      mobile: 180.0,
      tablet: 200.0,
      desktop: 220.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine available width for the chart
        final availableWidth = constraints.maxWidth;

        // Calculate chart size based on available width
        final chartSize = math.min(availableWidth * 0.9, chartHeight * 2);

        return Column(
          children: [
            SizedBox(
              height: chartHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(chartSize, chartHeight),
                    painter: PieChartPainter(
                      categories: chartData,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                  // Center text showing total
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConstants.currencySymbol + totalSpending.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 16,
                            tabletFactor: 1.2,
                            desktopFactor: 1.4,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 12,
                            tabletFactor: 1.1,
                            desktopFactor: 1.2,
                          ),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  // Add touch detection
                  GestureDetector(
                    onTapDown: (details) {
                      _handleTap(details.localPosition, chartData, chartSize, chartHeight);
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: chartSize,
                      height: chartHeight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            _buildLegend(chartData, totalSpending, constraints.maxHeight - chartHeight - AppTheme.smallSpacing),
          ],
        );
      }
    );
  }

  void _handleTap(Offset position, List<CategoryData> categories, double chartSize, double chartHeight) {
    // Calculate center of the chart
    final center = Offset(chartSize / 2, chartHeight / 2);

    // Calculate distance from center
    final distance = (position - center).distance;

    // Calculate radius of the chart
    final radius = chartSize * 0.4;
    final innerRadius = radius * 0.6;

    // Only process taps within the donut area
    if (distance >= innerRadius && distance <= radius) {
      // Calculate angle from center
      final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);

      // Convert to degrees and normalize to 0-360
      final degrees = (angle * 180 / math.pi + 360) % 360;

      // Find which segment was tapped
      double startAngle = 0;
      for (int i = 0; i < categories.length; i++) {
        final sweepAngle = categories[i].percentage / 100 * 360;
        if (degrees >= startAngle && degrees <= startAngle + sweepAngle) {
          setState(() {
            _selectedIndex = i;
          });
          break;
        }
        startAngle += sweepAngle;
      }
    }
  }

  Widget _buildLegend(List<CategoryData> categories, double totalSpending, double maxHeight) {
    // Calculate the maximum height for the legend
    final legendMaxHeight = math.max(100.0, maxHeight);

    return Container(
      constraints: BoxConstraints(
        maxHeight: legendMaxHeight,
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: categories.length > 3,
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: categories.length > 3
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final data = categories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        data.icon,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data.category,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              baseFontSize: 12,
                            ),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${data.amount.toStringAsFixed(0)} (${data.percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            baseFontSize: 12,
                          ),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: data.percentage / 100,
                    backgroundColor: Colors.grey.withAlpha(50),
                    valueColor: AlwaysStoppedAnimation<Color>(data.color),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Find predefined color or generate one based on the category name
    final categoryIndex = AppConstants.expenseCategories.indexWhere(
      (c) => c['name'] == category,
    );

    if (categoryIndex >= 0) {
      // Use a predefined list of colors
      final colors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.pink,
        Colors.amber,
        Colors.indigo,
        Colors.cyan,
        Colors.brown,
        Colors.lime,
      ];

      return colors[categoryIndex % colors.length];
    } else {
      // Generate a color based on the category name
      final hash = category.hashCode;
      return Color((hash & 0xFFFFFF) | 0xFF000000);
    }
  }
}

class PieChartPainter extends CustomPainter {
  final List<CategoryData> categories;
  final int selectedIndex;

  PieChartPainter({
    required this.categories,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final innerRadius = radius * 0.6; // For donut hole

    // Draw segments
    double startAngle = -math.pi / 2; // Start from top (270 degrees)

    // Draw background circle first (for empty chart or small segments)
    final bgPaint = Paint()
      ..color = Colors.grey.withAlpha(25) // 0.1 * 255 = ~25
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw segments
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final sweepAngle = category.percentage / 100 * 2 * math.pi;

      // Skip very small segments (less than 1%)
      if (category.percentage < 1) {
        startAngle += sweepAngle;
        continue;
      }

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill;

      // If this segment is selected, draw it slightly larger
      final segmentRadius = i == selectedIndex ? radius * 1.05 : radius;

      // Draw outer arc
      final rect = Rect.fromCircle(center: center, radius: segmentRadius);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    // Draw inner circle to create donut hole (after all segments)
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, holePaint);

    // Draw percentage labels for larger segments
    startAngle = -math.pi / 2; // Reset start angle
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final sweepAngle = category.percentage / 100 * 2 * math.pi;

      // Only draw labels for segments that are large enough (>= 5%)
      if (category.percentage >= 5) {
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = (radius + innerRadius) / 2;
        final labelPosition = Offset(
          center.dx + labelRadius * math.cos(labelAngle),
          center.dy + labelRadius * math.sin(labelAngle),
        );

        // Determine text color based on background color brightness
        final textColor = _isColorDark(category.color) ? Colors.white : Colors.black;

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${category.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            labelPosition.dx - textPainter.width / 2,
            labelPosition.dy - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    }
  }

  // Helper method to determine if a color is dark
  bool _isColorDark(Color color) {
    // Calculate relative luminance
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance < 0.5;
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
           oldDelegate.categories != categories;
  }
}

class CategoryData {
  final String category;
  final double amount;
  final double percentage;
  final IconData icon;
  final Color color;

  CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
  });
}
