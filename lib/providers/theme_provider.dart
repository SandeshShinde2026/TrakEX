import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Theme mode (system, light, dark)
  ThemeMode _themeMode = ThemeMode.system;

  // Primary color
  Color _primaryColor = const Color(0xFF2196F3); // Default clean blue

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _error;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Available theme colors - simplified palette
  static const List<Color> availableColors = [
    Color(0xFF2196F3), // Clean blue (default)
    Color(0xFF424242), // Neutral gray
    Color(0xFF4CAF50), // Simple green
    Color(0xFFFF9800), // Subtle orange
  ];

  // Constructor - load saved preferences
  ThemeProvider() {
    _loadPreferences();
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeString = prefs.getString('themeMode') ?? 'system';
      _themeMode = _getThemeModeFromString(themeModeString);

      // Load primary color
      final colorValue = prefs.getInt('primaryColor') ?? 0xFF2196F3;
      _primaryColor = Color(colorValue);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load theme preferences: $e';
      notifyListeners();
    }
  }

  // Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save theme mode
      await prefs.setString('themeMode', _getStringFromThemeMode(_themeMode));

      // Save primary color
      await prefs.setInt('primaryColor', _primaryColor.value);
    } catch (e) {
      _error = 'Failed to save theme preferences: $e';
      notifyListeners();
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _savePreferences();
  }

  // Set primary color
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    await _savePreferences();
  }

  // Reset to default theme
  Future<void> resetToDefault() async {
    _themeMode = ThemeMode.system;
    _primaryColor = const Color(0xFF2196F3);
    notifyListeners();
    await _savePreferences();
  }

  // Helper method to convert ThemeMode to String
  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  // Helper method to convert String to ThemeMode
  ThemeMode _getThemeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // Get theme mode name
  String getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System Default';
    }
  }

  // Get color name - simplified
  String getColorName(Color color) {
    if (color == const Color(0xFF2196F3)) return 'Blue';
    if (color == const Color(0xFF424242)) return 'Gray';
    if (color == const Color(0xFF4CAF50)) return 'Green';
    if (color == const Color(0xFFFF9800)) return 'Orange';
    return 'Custom';
  }
}
