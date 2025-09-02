import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  // Notification settings
  bool _expenseReminders = true;
  bool _budgetAlerts = true;
  bool _friendRequests = true;
  bool _debtReminders = true;
  bool _paymentConfirmations = true;
  
  // Loading state
  bool _isLoading = false;
  
  // Error message
  String? _error;
  
  // Getters
  bool get expenseReminders => _expenseReminders;
  bool get budgetAlerts => _budgetAlerts;
  bool get friendRequests => _friendRequests;
  bool get debtReminders => _debtReminders;
  bool get paymentConfirmations => _paymentConfirmations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Constructor - load saved preferences
  NotificationProvider() {
    _loadPreferences();
  }
  
  // Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load notification settings with defaults
      _expenseReminders = prefs.getBool('notification_expenseReminders') ?? true;
      _budgetAlerts = prefs.getBool('notification_budgetAlerts') ?? true;
      _friendRequests = prefs.getBool('notification_friendRequests') ?? true;
      _debtReminders = prefs.getBool('notification_debtReminders') ?? true;
      _paymentConfirmations = prefs.getBool('notification_paymentConfirmations') ?? true;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load notification preferences: $e';
      notifyListeners();
    }
  }
  
  // Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save notification settings
      await prefs.setBool('notification_expenseReminders', _expenseReminders);
      await prefs.setBool('notification_budgetAlerts', _budgetAlerts);
      await prefs.setBool('notification_friendRequests', _friendRequests);
      await prefs.setBool('notification_debtReminders', _debtReminders);
      await prefs.setBool('notification_paymentConfirmations', _paymentConfirmations);
    } catch (e) {
      _error = 'Failed to save notification preferences: $e';
      notifyListeners();
    }
  }
  
  // Toggle expense reminders
  Future<void> toggleExpenseReminders(bool value) async {
    _expenseReminders = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle budget alerts
  Future<void> toggleBudgetAlerts(bool value) async {
    _budgetAlerts = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle friend requests
  Future<void> toggleFriendRequests(bool value) async {
    _friendRequests = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle debt reminders
  Future<void> toggleDebtReminders(bool value) async {
    _debtReminders = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Toggle payment confirmations
  Future<void> togglePaymentConfirmations(bool value) async {
    _paymentConfirmations = value;
    notifyListeners();
    await _savePreferences();
  }
  
  // Reset to default settings
  Future<void> resetToDefault() async {
    _expenseReminders = true;
    _budgetAlerts = true;
    _friendRequests = true;
    _debtReminders = true;
    _paymentConfirmations = true;
    notifyListeners();
    await _savePreferences();
  }
}
