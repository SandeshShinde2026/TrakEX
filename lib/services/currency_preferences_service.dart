import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/currency_model.dart';
import '../constants/currency_constants.dart';

class CurrencyPreferencesService {
  static const String _defaultCurrencyKey = 'default_currency_code';
  static const String _autoConvertKey = 'auto_convert_enabled';
  static const String _showOriginalAmountKey = 'show_original_amount';

  // Singleton pattern
  static final CurrencyPreferencesService _instance = CurrencyPreferencesService._internal();
  factory CurrencyPreferencesService() => _instance;
  CurrencyPreferencesService._internal();

  /// Get user's default currency
  Future<CurrencyModel> getDefaultCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_defaultCurrencyKey);
      
      if (currencyCode != null) {
        final currency = CurrencyConstants.getCurrencyByCode(currencyCode);
        if (currency != null) {
          return currency;
        }
      }
    } catch (e) {
      print('Error getting default currency: $e');
    }
    
    // Return default currency if not set or error occurred
    return CurrencyConstants.defaultCurrency;
  }

  /// Set user's default currency
  Future<bool> setDefaultCurrency(CurrencyModel currency, {String? userId}) async {
    try {
      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultCurrencyKey, currency.code);

      // Save to Firestore if user is logged in
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'defaultCurrency': currency.code,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error setting default currency: $e');
      return false;
    }
  }

  /// Get auto-convert preference
  Future<bool> getAutoConvertEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoConvertKey) ?? true; // Default to enabled
    } catch (e) {
      print('Error getting auto-convert preference: $e');
      return true;
    }
  }

  /// Set auto-convert preference
  Future<bool> setAutoConvertEnabled(bool enabled, {String? userId}) async {
    try {
      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoConvertKey, enabled);

      // Save to Firestore if user is logged in
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'autoConvertEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error setting auto-convert preference: $e');
      return false;
    }
  }

  /// Get show original amount preference
  Future<bool> getShowOriginalAmount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showOriginalAmountKey) ?? true; // Default to show
    } catch (e) {
      print('Error getting show original amount preference: $e');
      return true;
    }
  }

  /// Set show original amount preference
  Future<bool> setShowOriginalAmount(bool show, {String? userId}) async {
    try {
      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showOriginalAmountKey, show);

      // Save to Firestore if user is logged in
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'showOriginalAmount': show,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error setting show original amount preference: $e');
      return false;
    }
  }

  /// Load user preferences from Firestore
  Future<void> loadUserPreferences(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // Load default currency
        if (data.containsKey('defaultCurrency')) {
          final currencyCode = data['defaultCurrency'] as String?;
          if (currencyCode != null) {
            final currency = CurrencyConstants.getCurrencyByCode(currencyCode);
            if (currency != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_defaultCurrencyKey, currency.code);
            }
          }
        }

        // Load auto-convert preference
        if (data.containsKey('autoConvertEnabled')) {
          final autoConvert = data['autoConvertEnabled'] as bool?;
          if (autoConvert != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_autoConvertKey, autoConvert);
          }
        }

        // Load show original amount preference
        if (data.containsKey('showOriginalAmount')) {
          final showOriginal = data['showOriginalAmount'] as bool?;
          if (showOriginal != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_showOriginalAmountKey, showOriginal);
          }
        }
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  /// Save user preferences to Firestore
  Future<void> saveUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final defaultCurrency = prefs.getString(_defaultCurrencyKey);
      final autoConvert = prefs.getBool(_autoConvertKey);
      final showOriginal = prefs.getBool(_showOriginalAmountKey);

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (defaultCurrency != null) {
        updateData['defaultCurrency'] = defaultCurrency;
      }
      if (autoConvert != null) {
        updateData['autoConvertEnabled'] = autoConvert;
      }
      if (showOriginal != null) {
        updateData['showOriginalAmount'] = showOriginal;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updateData);
    } catch (e) {
      print('Error saving user preferences: $e');
    }
  }

  /// Clear all currency preferences
  Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_defaultCurrencyKey);
      await prefs.remove(_autoConvertKey);
      await prefs.remove(_showOriginalAmountKey);
    } catch (e) {
      print('Error clearing preferences: $e');
    }
  }

  /// Get all currency preferences as a map
  Future<Map<String, dynamic>> getAllPreferences() async {
    try {
      final defaultCurrency = await getDefaultCurrency();
      final autoConvert = await getAutoConvertEnabled();
      final showOriginal = await getShowOriginalAmount();

      return {
        'defaultCurrency': defaultCurrency,
        'autoConvertEnabled': autoConvert,
        'showOriginalAmount': showOriginal,
      };
    } catch (e) {
      print('Error getting all preferences: $e');
      return {
        'defaultCurrency': CurrencyConstants.defaultCurrency,
        'autoConvertEnabled': true,
        'showOriginalAmount': true,
      };
    }
  }

  /// Check if currency preferences are set up
  Future<bool> isSetupComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_defaultCurrencyKey);
    } catch (e) {
      print('Error checking setup status: $e');
      return false;
    }
  }

  /// Initialize default preferences for new users
  Future<void> initializeDefaults({String? userId}) async {
    try {
      final isSetup = await isSetupComplete();
      if (!isSetup) {
        await setDefaultCurrency(CurrencyConstants.defaultCurrency, userId: userId);
        await setAutoConvertEnabled(true, userId: userId);
        await setShowOriginalAmount(true, userId: userId);
      }
    } catch (e) {
      print('Error initializing defaults: $e');
    }
  }
}
