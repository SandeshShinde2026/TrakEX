import 'package:flutter/foundation.dart';
import '../models/karma_model.dart';
import '../services/karma_service.dart';

class KarmaProvider extends ChangeNotifier {
  final KarmaService _karmaService = KarmaService();

  KarmaModel? _userKarma;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  KarmaModel? get userKarma => _userKarma;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user's karma
  Future<void> loadUserKarma(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userKarma = await _karmaService.getUserKarma(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load karma leaderboard
  Future<void> loadKarmaLeaderboard(String userId, List<String> friendIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaderboard = await _karmaService.getKarmaLeaderboard(userId, friendIds);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get badge and nickname for a specific user
  Future<Map<String, dynamic>> getUserBadgeInfo(String userId) async {
    try {
      final karma = await _karmaService.getUserKarma(userId);
      return {
        'badgeLevel': karma.badgeLevel,
        'badgeEmoji': karma.badgeEmoji,
        'nickname': karma.nickname,
        'badgeName': karma.badgeName,
        'totalPoints': karma.totalPoints,
        'description': karma.description,
      };
    } catch (e) {
      debugPrint('Error getting user badge info: $e');
      return {
        'badgeLevel': KarmaBadgeLevel.leastTrusted,
        'badgeEmoji': '🤡',
        'nickname': 'The Clown Collector',
        'badgeName': 'Least Trusted',
        'totalPoints': 0,
        'description': 'Danger zone — promises a lot, repays rarely. Handle with caution!',
      };
    }
  }

  // Calculate karma points for a repayment
  int calculateKarmaPoints(DateTime borrowTimestamp, DateTime repaymentTimestamp) {
    return _karmaService.calculateKarmaPoints(borrowTimestamp, repaymentTimestamp);
  }
}
