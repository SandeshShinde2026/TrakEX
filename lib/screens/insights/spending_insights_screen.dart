import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/spending_habits_insights_service.dart';

class SpendingInsightsScreen extends StatefulWidget {
  const SpendingInsightsScreen({super.key});

  @override
  State<SpendingInsightsScreen> createState() => _SpendingInsightsScreenState();
}

class _SpendingInsightsScreenState extends State<SpendingInsightsScreen> {
  final SpendingHabitsInsightsService _insightsService = SpendingHabitsInsightsService();
  SpendingInsights? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      final insights = await _insightsService.generateInsights(authProvider.userModel!.id);
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Insights'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights == null
              ? const Center(child: Text('No insights available'))
              : RefreshIndicator(
                  onRefresh: _loadInsights,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFinancialHealthScore(),
                        const SizedBox(height: 24),
                        _buildTimeBasedInsights(),
                        const SizedBox(height: 24),
                        _buildCategoryInsights(),
                        const SizedBox(height: 24),
                        _buildBehavioralInsights(),
                        const SizedBox(height: 24),
                        _buildPredictions(),
                        const SizedBox(height: 24),
                        _buildRecommendations(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFinancialHealthScore() {
    final score = _insights!.financialHealthScore;
    final scoreColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: scoreColor),
                const SizedBox(width: 8),
                const Text(
                  'Financial Health Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: 180,
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: score,
                      color: scoreColor,
                      radius: 20,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - score,
                      color: Colors.grey.shade300,
                      radius: 20,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '${score.toInt()}/100',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getHealthScoreDescription(score),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBasedInsights() {
    final timeInsights = _insights!.timeBasedInsights;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Time-Based Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Peak Spending Day', timeInsights.peakSpendingDay),
            _buildInfoRow('Peak Spending Time', '${timeInsights.peakSpendingHour}:00'),
            _buildInfoRow('Weekend vs Weekday', 
                '${(timeInsights.weekendSpendingRatio * 100).toInt()}% weekend'),
            const SizedBox(height: 12),
            ...timeInsights.insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInsights() {
    final categoryInsights = _insights!.categoryInsights;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Category Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (categoryInsights.topCategories.isNotEmpty) ...[
              const Text('Top Categories:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ...categoryInsights.topCategories.take(3).map((category) => 
                _buildCategoryItem(category)),
              const SizedBox(height: 12),
            ],
            ...categoryInsights.insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildBehavioralInsights() {
    final behavioralInsights = _insights!.behavioralInsights;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Behavioral Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Impulse Buying Score', 
                '${(behavioralInsights.impulseBuyingScore * 100).toInt()}%'),
            _buildInfoRow('Routine Expenses', 
                '${(behavioralInsights.routineExpensePercentage * 100).toInt()}%'),
            const SizedBox(height: 12),
            ...behavioralInsights.insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictions() {
    final predictions = _insights!.predictions;
    
    if (predictions.isEmpty) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Spending Predictions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...predictions.take(3).map((prediction) => _buildPredictionItem(prediction)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _insights!.recommendations;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Smart Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => _buildRecommendationItem(recommendation)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String insight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(insight)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryData category) {
    final trendIcon = category.trend == SpendingTrend.increasing 
        ? Icons.trending_up 
        : category.trend == SpendingTrend.decreasing 
            ? Icons.trending_down 
            : Icons.trending_flat;
    
    final trendColor = category.trend == SpendingTrend.increasing 
        ? Colors.red 
        : category.trend == SpendingTrend.decreasing 
            ? Colors.green 
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(category.category),
          ),
          Text(
            '₹${category.totalAmount.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Icon(trendIcon, size: 16, color: trendColor),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(SpendingPrediction prediction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.category,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Predicted: ₹${prediction.predictedAmount.toInt()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(prediction.confidence * 100).toInt()}% confidence',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(recommendation)),
          ],
        ),
      ),
    );
  }

  String _getHealthScoreDescription(double score) {
    if (score >= 80) return 'Excellent financial habits!';
    if (score >= 60) return 'Good spending patterns with room for improvement';
    if (score >= 40) return 'Consider reviewing your spending habits';
    return 'Time to focus on financial discipline';
  }
}