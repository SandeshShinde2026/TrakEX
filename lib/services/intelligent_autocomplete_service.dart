import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class IntelligentAutoCompleteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<String>> _cachedSuggestions = {};
  static final List<String> _commonIndianExpenses = [];

  // Initialize with Indian context data from your CSV
  Future<void> initialize() async {
    if (_commonIndianExpenses.isEmpty) {
      try {
        final csvData = await rootBundle.loadString('assets/expense_categorization_data.csv');
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
        
        for (var row in rows.skip(1)) { // Skip header
          if (row.length >= 2) {
            _commonIndianExpenses.add(row[0].toString().replaceAll('"', ''));
          }
        }
      } catch (e) {
        print('Error loading CSV data: $e');
      }
    }
  }

  // Get intelligent suggestions based on user input
  Future<List<ExpenseSuggestion>> getSuggestions(String input, String userId) async {
    if (input.length < 2) return [];

    final suggestions = <ExpenseSuggestion>[];
    final inputLower = input.toLowerCase().trim();
    
    // 1. Personal History Suggestions (highest priority)
    final personalSuggestions = await _getPersonalHistorySuggestions(inputLower, userId);
    suggestions.addAll(personalSuggestions);

    // 2. Indian Context Suggestions
    final indianSuggestions = _getIndianContextSuggestions(inputLower);
    suggestions.addAll(indianSuggestions);

    // 3. Pattern-based suggestions (for partial matches)
    final patternSuggestions = _getPatternBasedSuggestions(inputLower);
    suggestions.addAll(patternSuggestions);

    // Remove duplicates and sort by relevance
    final uniqueSuggestions = _removeDuplicatesAndSort(suggestions);
    
    return uniqueSuggestions.take(8).toList();
  }

  Future<List<ExpenseSuggestion>> _getPersonalHistorySuggestions(String input, String userId) async {
    try {
      final query = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();

      final suggestions = <ExpenseSuggestion>[];
      final descriptionFrequency = <String, int>{};

      // Count frequency of descriptions
      for (var doc in query.docs) {
        final data = doc.data();
        final description = (data['description'] as String).toLowerCase();
        descriptionFrequency[description] = (descriptionFrequency[description] ?? 0) + 1;
      }

      // Find matching descriptions
      for (var entry in descriptionFrequency.entries) {
        final similarity = _calculateSimilarity(input, entry.key);
        if (similarity > 0.6 || entry.key.contains(input)) {
          suggestions.add(ExpenseSuggestion(
            text: _toTitleCase(entry.key),
            type: SuggestionType.personal,
            frequency: entry.value,
            similarity: similarity,
          ));
        }
      }

      return suggestions;
    } catch (e) {
      print('Error getting personal suggestions: $e');
      return [];
    }
  }

  List<ExpenseSuggestion> _getIndianContextSuggestions(String input) {
    final suggestions = <ExpenseSuggestion>[];
    
    for (var expense in _commonIndianExpenses) {
      final expenseLower = expense.toLowerCase();
      final similarity = _calculateSimilarity(input, expenseLower);
      
      if (similarity > 0.7 || expenseLower.startsWith(input) || expenseLower.contains(input)) {
        suggestions.add(ExpenseSuggestion(
          text: expense,
          type: SuggestionType.indian,
          frequency: 0,
          similarity: similarity,
        ));
      }
    }

    return suggestions;
  }

  List<ExpenseSuggestion> _getPatternBasedSuggestions(String input) {
    final patterns = <String, List<String>>{
      'auto': ['Auto rickshaw', 'Auto fare', 'Auto to office'],
      'chai': ['Chai and snacks', 'Cutting chai', 'Masala chai'],
      'petrol': ['Petrol for scooter', 'Petrol pump', 'Petrol expense'],
      'metro': ['Metro card recharge', 'Metro ticket', 'Metro travel'],
      'medicine': ['Medicine from pharmacy', 'Medical store', 'Medicine purchase'],
      'parlour': ['Beauty parlour', 'Hair cut at parlour', 'Parlour visit'],
      'grocery': ['Grocery shopping', 'Monthly grocery', 'Weekly grocery'],
      'bill': ['Electricity bill', 'Mobile bill', 'Internet bill'],
    };

    final suggestions = <ExpenseSuggestion>[];
    
    for (var entry in patterns.entries) {
      if (input.contains(entry.key) || entry.key.contains(input)) {
        for (var suggestion in entry.value) {
          suggestions.add(ExpenseSuggestion(
            text: suggestion,
            type: SuggestionType.pattern,
            frequency: 0,
            similarity: _calculateSimilarity(input, suggestion.toLowerCase()),
          ));
        }
      }
    }

    return suggestions;
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    // Levenshtein distance-based similarity
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(s1.length + 1, (i) => List.filled(s2.length + 1, 0));
    
    for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  List<ExpenseSuggestion> _removeDuplicatesAndSort(List<ExpenseSuggestion> suggestions) {
    final seen = <String>{};
    final unique = <ExpenseSuggestion>[];

    for (var suggestion in suggestions) {
      if (!seen.contains(suggestion.text.toLowerCase())) {
        seen.add(suggestion.text.toLowerCase());
        unique.add(suggestion);
      }
    }

    // Sort by: 1. Type priority, 2. Frequency, 3. Similarity
    unique.sort((a, b) {
      // Personal suggestions get highest priority
      if (a.type != b.type) {
        if (a.type == SuggestionType.personal) return -1;
        if (b.type == SuggestionType.personal) return 1;
      }
      
      // Then by frequency (for personal suggestions)
      if (a.frequency != b.frequency) {
        return b.frequency.compareTo(a.frequency);
      }
      
      // Finally by similarity
      return b.similarity.compareTo(a.similarity);
    });

    return unique;
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

class ExpenseSuggestion {
  final String text;
  final SuggestionType type;
  final int frequency;
  final double similarity;

  ExpenseSuggestion({
    required this.text,
    required this.type,
    required this.frequency,
    required this.similarity,
  });
}

enum SuggestionType { personal, indian, pattern }