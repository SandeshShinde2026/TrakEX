import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ExpenseCategorization {
  final String predictedCategory;
  final double confidence;
  final String description;
  final List<CategoryPrediction> allPredictions;
  final DateTime timestamp;

  ExpenseCategorization({
    required this.predictedCategory,
    required this.confidence,
    required this.description,
    required this.allPredictions,
    required this.timestamp,
  });

  factory ExpenseCategorization.fromJson(Map<String, dynamic> json) {
    return ExpenseCategorization(
      predictedCategory: json['predicted_category'],
      confidence: json['confidence'].toDouble(),
      description: json['description'],
      allPredictions: (json['all_predictions'] as List)
          .map((e) => CategoryPrediction.fromList(e))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CategoryPrediction {
  final String category;
  final double probability;

  CategoryPrediction({
    required this.category,
    required this.probability,
  });

  factory CategoryPrediction.fromList(List<dynamic> list) {
    return CategoryPrediction(
      category: list[0],
      probability: list[1].toDouble(),
    );
  }
}

class BatchPredictionResult {
  final int index;
  final String description;
  final String? predictedCategory;
  final double? confidence;
  final String? error;

  BatchPredictionResult({
    required this.index,
    required this.description,
    this.predictedCategory,
    this.confidence,
    this.error,
  });

  factory BatchPredictionResult.fromJson(Map<String, dynamic> json) {
    return BatchPredictionResult(
      index: json['index'],
      description: json['description'],
      predictedCategory: json['predicted_category'],
      confidence: json['confidence']?.toDouble(),
      error: json['error'],
    );
  }

  bool get hasError => error != null;
  bool get isSuccessful => predictedCategory != null && error == null;
}

class ExpenseCategorizationService {
  static const String _baseUrl = 'http://localhost:5002';
  static const Duration _timeoutDuration = Duration(seconds: 10);
  
  final http.Client _client = http.Client();

  /// Check if the backend service is healthy and model is loaded
  Future<bool> isServiceHealthy() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Predict category for a single expense description
  Future<ExpenseCategorization?> predictCategory(String description) async {
    if (description.trim().isEmpty) {
      throw ArgumentError('Description cannot be empty');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'description': description.trim(),
        }),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ExpenseCategorization.fromJson(data);
        } else {
          throw Exception('Prediction failed: ${data['error']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error']}');
      }
    } on SocketException {
      throw Exception('No internet connection or server not reachable');
    } on http.ClientException {
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  /// Predict categories for multiple expense descriptions
  Future<List<BatchPredictionResult>> predictBatch(List<String> descriptions) async {
    if (descriptions.isEmpty) {
      throw ArgumentError('Descriptions list cannot be empty');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/predict/batch'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'descriptions': descriptions,
        }),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['results'] as List)
              .map((e) => BatchPredictionResult.fromJson(e))
              .toList();
        } else {
          throw Exception('Batch prediction failed: ${data['error']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error']}');
      }
    } on SocketException {
      throw Exception('No internet connection or server not reachable');
    } on http.ClientException {
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('Batch prediction failed: $e');
    }
  }

  /// Get all available categories from the model
  Future<List<String>> getAvailableCategories() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/categories'),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['categories']);
        } else {
          throw Exception('Failed to get categories: ${data['error']}');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Server error: ${errorData['error']}');
      }
    } on SocketException {
      throw Exception('No internet connection or server not reachable');
    } on http.ClientException {
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Predict category with fallback to manual categorization
  Future<String> predictCategoryWithFallback(
    String description, {
    List<String>? availableCategories,
    String defaultCategory = 'Other',
  }) async {
    try {
      final prediction = await predictCategory(description);
      if (prediction != null && prediction.confidence > 0.3) {
        return prediction.predictedCategory;
      }
    } catch (e) {
      print('Auto-categorization failed: $e');
    }

    // Fallback to manual categorization or default
    return _manualCategorization(description, availableCategories) ?? defaultCategory;
  }

  /// Simple rule-based fallback categorization
  String? _manualCategorization(String description, List<String>? categories) {
    final desc = description.toLowerCase();
    
    // Food & Dining keywords
    if (desc.contains('food') || desc.contains('restaurant') || 
        desc.contains('coffee') || desc.contains('lunch') || 
        desc.contains('dinner') || desc.contains('zomato') || 
        desc.contains('swiggy') || desc.contains('pizza') ||
        desc.contains('burger') || desc.contains('chai')) {
      return 'Food & Dining';
    }
    
    // Transportation keywords
    if (desc.contains('uber') || desc.contains('ola') || 
        desc.contains('taxi') || desc.contains('bus') || 
        desc.contains('metro') || desc.contains('train') ||
        desc.contains('petrol') || desc.contains('fuel')) {
      return 'Transportation';
    }
    
    // Shopping keywords
    if (desc.contains('amazon') || desc.contains('flipkart') || 
        desc.contains('myntra') || desc.contains('shop') || 
        desc.contains('clothes') || desc.contains('shoes')) {
      return 'Shopping';
    }
    
    // Entertainment keywords
    if (desc.contains('movie') || desc.contains('netflix') || 
        desc.contains('game') || desc.contains('concert') ||
        desc.contains('entertainment')) {
      return 'Entertainment';
    }
    
    return null;
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}

/// Singleton instance for global access
class ExpenseCategorizationManager {
  static final ExpenseCategorizationManager _instance = 
      ExpenseCategorizationManager._internal();
  
  factory ExpenseCategorizationManager() => _instance;
  
  ExpenseCategorizationManager._internal();

  final ExpenseCategorizationService _service = ExpenseCategorizationService();

  ExpenseCategorizationService get service => _service;

  /// Initialize and check service health
  Future<bool> initialize() async {
    return await _service.isServiceHealthy();
  }

  void dispose() {
    _service.dispose();
  }
}