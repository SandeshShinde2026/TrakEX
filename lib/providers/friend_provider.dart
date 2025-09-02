import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../models/debt_model.dart';
import '../services/friend_service.dart';
import '../services/debt_service.dart';

class FriendProvider extends ChangeNotifier {
  final FriendService _friendService = FriendService();
  final DebtService _debtService = DebtService();

  List<UserModel> _friends = [];
  List<UserModel> _searchResults = [];
  List<FriendRequestModel> _receivedRequests = [];
  List<FriendRequestModel> _sentRequests = [];
  Map<String, double> _balances = {}; // Friend ID to balance (direct transactions only)
  Map<String, double> _directBalances = {}; // Friend ID to balance for direct transactions
  Map<String, double> _groupExpenseBalances = {}; // Friend ID to balance for group expenses
  List<Map<String, dynamic>> _karmaLeaderboard = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get friends => _friends;
  List<UserModel> get searchResults => _searchResults;
  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  Map<String, double> get balances => _balances;
  Map<String, double> get directBalances => _directBalances;
  Map<String, double> get groupExpenseBalances => _groupExpenseBalances;
  List<Map<String, dynamic>> get karmaLeaderboard => _karmaLeaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user's friends
  Future<void> loadFriends(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _friends = await _friendService.getFriends(userId);

      // Load balances for each friend
      for (var friend in _friends) {
        // We'll get specific debt types directly

        // Get direct transaction debts
        final directDebts = await _debtService.getDirectDebtsBetweenUsers(userId, friend.id);

        // Get group expense debts
        final groupExpenseDebts = await _debtService.getGroupExpenseDebtsBetweenUsers(userId, friend.id);

        // Calculate balances
        double directBalance = 0;
        double groupExpenseBalance = 0;

        // Calculate direct transaction balance
        for (var debt in directDebts) {
          // Skip paid debts
          if (debt.status == PaymentStatus.paid) continue;

          if (debt.creditorId == userId) {
            // Friend owes user
            directBalance += debt.remainingAmount;
          } else {
            // User owes friend
            directBalance -= debt.remainingAmount;
          }
        }

        // Calculate group expense balance
        for (var debt in groupExpenseDebts) {
          // Skip paid debts
          if (debt.status == PaymentStatus.paid) continue;

          if (debt.creditorId == userId) {
            // Friend owes user
            groupExpenseBalance += debt.remainingAmount;
          } else {
            // User owes friend
            groupExpenseBalance -= debt.remainingAmount;
          }
        }

        // Store balances
        _directBalances[friend.id] = directBalance;
        _groupExpenseBalances[friend.id] = groupExpenseBalance;

        // For backward compatibility, use direct balance for the main balance
        _balances[friend.id] = directBalance;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search for users
  Future<void> searchUsers(String query, String currentUserId) async {
    debugPrint('FriendProvider.searchUsers called with query: "$query"');

    if (query.isEmpty) {
      debugPrint('Empty query, clearing search results');
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null; // Clear any previous errors
    notifyListeners();

    try {
      debugPrint('Calling friend service to search for users...');
      _searchResults = await _friendService.searchUsers(query, currentUserId);
      debugPrint('Search completed, found ${_searchResults.length} results');

      // Log the results for debugging
      for (var user in _searchResults) {
        debugPrint('Result: ${user.name} (${user.email}), ID: ${user.id}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in searchUsers: $e');
      _isLoading = false;
      _error = e.toString();
      _searchResults = []; // Clear results on error
      notifyListeners();
    }
  }

  // Load friend requests
  Future<void> loadFriendRequests(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _receivedRequests = await _friendService.getPendingReceivedRequests(userId);
      _sentRequests = await _friendService.getPendingSentRequests(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send friend request
  Future<bool> sendFriendRequest(
    String senderId,
    String receiverId,
    String senderName,
    String senderEmail,
    String? senderPhotoUrl,
    String receiverName,
    String receiverEmail,
    String? receiverPhotoUrl,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final request = await _friendService.sendFriendRequest(
        senderId,
        receiverId,
        senderName,
        senderEmail,
        senderPhotoUrl,
        receiverName,
        receiverEmail,
        receiverPhotoUrl,
      );

      if (request != null) {
        _sentRequests.add(request);
      }

      _isLoading = false;
      notifyListeners();
      return request != null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _friendService.acceptFriendRequest(requestId);

      if (success) {
        // Update the request status in the local list
        final index = _receivedRequests.indexWhere((req) => req.id == requestId);
        if (index >= 0) {
          _receivedRequests.removeAt(index);
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _friendService.rejectFriendRequest(requestId);

      if (success) {
        // Remove the request from the local list
        final index = _receivedRequests.indexWhere((req) => req.id == requestId);
        if (index >= 0) {
          _receivedRequests.removeAt(index);
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel sent friend request
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _friendService.cancelFriendRequest(requestId);

      if (success) {
        // Remove the request from the local list
        final index = _sentRequests.indexWhere((req) => req.id == requestId);
        if (index >= 0) {
          _sentRequests.removeAt(index);
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if a user is already a friend
  bool isFriend(String friendId) {
    return _friends.any((friend) => friend.id == friendId);
  }

  // Check if there's a pending request with a user
  Future<FriendRequestModel?> checkExistingRequest(String userId1, String userId2) async {
    try {
      return await _friendService.checkExistingRequest(userId1, userId2);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Add a friend
  Future<bool> addFriend(String userId, String friendId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _friendService.addFriend(userId, friendId);
      await loadFriends(userId); // Reload friends list

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove a friend
  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('FriendProvider: Removing friend $friendId and clearing all debt data');

      await _friendService.removeFriend(userId, friendId);

      // Reload friends list
      await loadFriends(userId);

      // Clear local balances for this friend
      _balances.remove(friendId);
      _directBalances.remove(friendId);
      _groupExpenseBalances.remove(friendId);

      debugPrint('FriendProvider: Friend removed successfully, balances cleared');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FriendProvider: Error removing friend: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update trust score
  Future<bool> updateTrustScore(String userId, String friendId, double newScore) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _friendService.updateTrustScore(userId, friendId, newScore);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update privacy setting
  Future<bool> updatePrivacySetting(String userId, String friendId, bool isVisible) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _friendService.updatePrivacySetting(userId, friendId, isVisible);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get friend summary
  Future<Map<String, dynamic>?> getFriendSummary(String userId, String friendId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final summary = await _friendService.getFriendSummary(userId, friendId);

      _isLoading = false;
      notifyListeners();
      return summary;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Load karma leaderboard
  Future<void> loadKarmaLeaderboard(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _karmaLeaderboard = await _friendService.getKarmaLeaderboard(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get friends who owe the user money (direct transactions only)
  List<Map<String, dynamic>> getFriendsWhoOwe(String userId) {
    final List<Map<String, dynamic>> result = [];

    for (var friend in _friends) {
      final balance = _directBalances[friend.id] ?? 0;
      if (balance > 0) {
        result.add({
          'friend': friend,
          'amount': balance,
          'debtType': DebtType.direct,
        });
      }
    }

    // Sort by amount (descending)
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return result;
  }

  // Get friends the user owes money to (direct transactions only)
  List<Map<String, dynamic>> getFriendsUserOwes(String userId) {
    final List<Map<String, dynamic>> result = [];

    for (var friend in _friends) {
      final balance = _directBalances[friend.id] ?? 0;
      if (balance < 0) {
        result.add({
          'friend': friend,
          'amount': balance.abs(),
          'debtType': DebtType.direct,
        });
      }
    }

    // Sort by amount (descending)
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return result;
  }

  // Get friends with group expense splits
  List<Map<String, dynamic>> getFriendsWithGroupExpenses(String userId) {
    final List<Map<String, dynamic>> result = [];

    for (var friend in _friends) {
      final balance = _groupExpenseBalances[friend.id] ?? 0;
      if (balance != 0) {
        result.add({
          'friend': friend,
          'amount': balance.abs(),
          'isOwed': balance > 0, // True if friend owes user
          'debtType': DebtType.groupExpense,
        });
      }
    }

    // Sort by amount (descending)
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return result;
  }

  // Calculate optimal settlement plan
  List<Map<String, dynamic>> calculateOptimalSettlement() {
    final List<Map<String, dynamic>> settlements = [];

    // Create a copy of balances for processing
    final Map<String, double> processBalances = Map.from(_balances);

    // Create lists of debtors and creditors
    final List<MapEntry<String, double>> debtors = [];
    final List<MapEntry<String, double>> creditors = [];

    for (var entry in processBalances.entries) {
      if (entry.value < 0) {
        debtors.add(MapEntry(entry.key, entry.value.abs()));
      } else if (entry.value > 0) {
        creditors.add(MapEntry(entry.key, entry.value));
      }
    }

    // Sort by amount (descending)
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    // Match debtors with creditors
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      final debtor = debtors.first;
      final creditor = creditors.first;

      final amount = debtor.value < creditor.value ? debtor.value : creditor.value;

      // Add settlement
      settlements.add({
        'from': _getFriendById(debtor.key),
        'to': _getFriendById(creditor.key),
        'amount': amount,
      });

      // Update balances
      if (debtor.value < creditor.value) {
        creditors[0] = MapEntry(creditor.key, creditor.value - amount);
        debtors.removeAt(0);
      } else if (debtor.value > creditor.value) {
        debtors[0] = MapEntry(debtor.key, debtor.value - amount);
        creditors.removeAt(0);
      } else {
        debtors.removeAt(0);
        creditors.removeAt(0);
      }
    }

    return settlements;
  }

  // Helper to get friend by ID
  UserModel? _getFriendById(String friendId) {
    try {
      return _friends.firstWhere((friend) => friend.id == friendId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
