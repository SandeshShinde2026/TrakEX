import 'package:flutter/material.dart';
import '../services/expense_categorization_service.dart';

class ExpenseCategorializationDemo extends StatefulWidget {
  const ExpenseCategorializationDemo({Key? key}) : super(key: key);

  @override
  State<ExpenseCategorializationDemo> createState() => _ExpenseCategoralizationDemoState();
}

class _ExpenseCategoralizationDemoState extends State<ExpenseCategorializationDemo> {
  final TextEditingController _descriptionController = TextEditingController();
  final ExpenseCategorizationService _categorizationService = ExpenseCategorizationService();
  
  bool _isLoading = false;
  bool _isServiceHealthy = false;
  ExpenseCategorization? _lastPrediction;
  String? _errorMessage;
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _checkServiceHealth();
    _loadAvailableCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categorizationService.dispose();
    super.dispose();
  }

  Future<void> _checkServiceHealth() async {
    try {
      final isHealthy = await _categorizationService.isServiceHealthy();
      setState(() {
        _isServiceHealthy = isHealthy;
        if (!isHealthy) {
          _errorMessage = 'Backend service is not available. Make sure the Flask server is running on port 5001.';
        }
      });
    } catch (e) {
      setState(() {
        _isServiceHealthy = false;
        _errorMessage = 'Failed to check service health: $e';
      });
    }
  }

  Future<void> _loadAvailableCategories() async {
    try {
      final categories = await _categorizationService.getAvailableCategories();
      setState(() {
        _availableCategories = categories;
      });
    } catch (e) {
      print('Failed to load categories: $e');
    }
  }

  Future<void> _predictCategory() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an expense description';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastPrediction = null;
    });

    try {
      final prediction = await _categorizationService.predictCategory(description);
      setState(() {
        _lastPrediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _predictWithFallback() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an expense description';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final category = await _categorizationService.predictCategoryWithFallback(
        description,
        availableCategories: _availableCategories,
      );
      
      // Show result in a simple dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Category Prediction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: $description'),
                const SizedBox(height: 8),
                Text('Predicted Category: $category', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Expense Categorization'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Status Card
            Card(
              color: _isServiceHealthy ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isServiceHealthy ? Icons.check_circle : Icons.error,
                      color: _isServiceHealthy ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServiceHealthy 
                          ? 'AI Service: Online ✅' 
                          : 'AI Service: Offline ❌',
                      style: TextStyle(
                        color: _isServiceHealthy ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _checkServiceHealth,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Status',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Input Section
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Expense Description',
                hintText: 'e.g., coffee at starbucks, uber ride, netflix subscription',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isServiceHealthy && !_isLoading ? _predictCategory : null,
                    icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.psychology),
                    label: const Text('AI Predict'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_isLoading ? _predictWithFallback : null,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('Smart Predict'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Prediction Results
            if (_lastPrediction != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Prediction Result',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Main Prediction
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${_lastPrediction!.predictedCategory}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confidence: ${(_lastPrediction!.confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Top Predictions
                      const Text(
                        'Top Predictions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_lastPrediction!.allPredictions.take(3).map((prediction) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(prediction.category),
                              Text(
                                '${(prediction.probability * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],

            // Available Categories
            if (_availableCategories.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Available Categories:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableCategories.map((category) =>
                  Chip(
                    label: Text(
                      category,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}