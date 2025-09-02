import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class SpendingTrendsChart extends StatelessWidget {
  final Map<DateTime, double> dailySpending;
  final double maxY;

  const SpendingTrendsChart({
    super.key,
    required this.dailySpending,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (dailySpending.isEmpty) {
      return const Center(
        child: Text('No spending data available'),
      );
    }

    // Sort dates for the chart
    final sortedDates = dailySpending.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Ensure we have a valid maximum Y value
    final safeMaxY = maxY <= 0 ? 100.0 : maxY;

    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: Size.infinite,
        painter: SpendingChartPainter(
          dailySpending: dailySpending,
          sortedDates: sortedDates,
          maxY: safeMaxY,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
          primaryColor: Theme.of(context).primaryColor,
        ),
        child: Stack(
          children: [
            // Y-axis labels
            Positioned(
              left: 0,
              top: 0,
              bottom: 20, // Space for X-axis labels
              width: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppConstants.currencySymbol}${safeMaxY.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${(safeMaxY / 2).toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}0',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // X-axis labels
            Positioned(
              left: 40,
              right: 0,
              bottom: 0,
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (sortedDates.isNotEmpty) ...[
                    Text(
                      DateFormat.MMMd().format(sortedDates.first),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    if (sortedDates.length > 2)
                      Text(
                        DateFormat.MMMd().format(sortedDates[sortedDates.length ~/ 2]),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    Text(
                      DateFormat.MMMd().format(sortedDates.last),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpendingChartPainter extends CustomPainter {
  final Map<DateTime, double> dailySpending;
  final List<DateTime> sortedDates;
  final double maxY;
  final bool isDarkMode;
  final Color primaryColor;

  SpendingChartPainter({
    required this.dailySpending,
    required this.sortedDates,
    required this.maxY,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTRB(
      40, // Left padding for Y-axis labels
      10, // Top padding
      size.width, // Right edge
      size.height - 20, // Bottom padding for X-axis labels
    );

    // Draw grid lines
    final gridPaint = Paint()
      ..color = isDarkMode ? Colors.grey.withAlpha(70) : Colors.grey.withAlpha(50)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = chartRect.top + (chartRect.height * (5 - i) / 5);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    // If no data, return
    if (sortedDates.isEmpty) return;

    // Draw the line chart
    final linePaint = Paint()
      ..color = isDarkMode ? Colors.white : primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isDarkMode ? Colors.white.withAlpha(100) : primaryColor.withAlpha(100),
          isDarkMode ? Colors.white.withAlpha(10) : primaryColor.withAlpha(10),
        ],
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Start at the bottom left for the fill path
    fillPath.moveTo(chartRect.left, chartRect.bottom);

    bool isFirstPoint = true;

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final amount = dailySpending[date] ?? 0;

      // Calculate x position based on date index
      final x = chartRect.left + (i / (sortedDates.length - 1)) * chartRect.width;

      // Calculate y position based on amount
      final y = chartRect.bottom - (amount / maxY) * chartRect.height;

      if (isFirstPoint) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw point markers
      final pointPaint = Paint()
        ..color = isDarkMode ? Colors.white : primaryColor
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isDarkMode ? Colors.grey.shade800 : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(x, y), 4, borderPaint);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    // Complete the fill path
    fillPath.lineTo(chartRect.right, chartRect.bottom);
    fillPath.close();

    // Draw the fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
