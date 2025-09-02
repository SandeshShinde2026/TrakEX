import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyProvider extends ChangeNotifier {
  // Privacy settings
  bool _showExpensesToFriends = false;
  bool _showBudgetsToFriends = false;
  bool _allowFriendSearch = true;
  bool _showProfileDetails = true;
  
  // Loading state
  bool _isLoading = false;
  
  // Error message
  String? _error;
  
  // Getters
  bool get showExpensesToFriends => _showExpensesToFriends;
  bool get showBudgetsToFriends => _showBudgetsToFriends;
  bool get allowFriendSearch => _allowFriendSearch;
  bool get showProfileDetails => _showProfileDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Constructor - load saved preferences
  PrivacyProvider() {
    _loadPreferences();
  }
  
  // Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load privacy settings with defaults
      _showExpensesToFriends = prefs.getBool('privacy_showExpensesToFriends') ?? false;
      _showBudgetsToFriends = prefs.getBool('privacy_showBudgetsToFriends') ?? false;
      _allowFriendSearch = prefs.getBool('privacy_allowFriendSearch') ?? true;
      _showProfileDetails = prefs.getBool('privacy_showProfileDetails') ?? true;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load privacy preferences: $e';
      notifyListeners();
    }
  }
  
  // Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save privacy settings
      await prefs.setBool('privacy_showExpensesToFriends', _showExpensesToFriends);
      await prefs.setBool('privacy_showBudgetsToFriends', _showBudgetsToFriends);
      await prefs.setBool('privacy_allowFriendSearch', _allowFriendSearch);
      await prefs.setBool('privacy_showProfileDetails', _showProfileDetails);
    } catch (e) {
      _error = 'Failed to save privacy preferences: $e';
      notifyListeners();
    }
  }
  
  // Toggle show expenses to friends
  Future<void> toggleShowExpensesToFriends(bool value) async {
    _showExpensesToFriends = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle show budgets to friends
  Future<void> toggleShowBudgetsToFriends(bool value) async {
    _showBudgetsToFriends = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle allow friend search
  Future<void> toggleAllowFriendSearch(bool value) async {
    _allowFriendSearch = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle show profile details
  Future<void> toggleShowProfileDetails(bool value) async {
    _showProfileDetails = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Reset to default settings
  Future<void> resetToDefault() async {
    _showExpensesToFriends = false;
    _showBudgetsToFriends = false;
    _allowFriendSearch = true;
    _showProfileDetails = true;
    notifyListeners();
    await _savePreferences();
  }
}
