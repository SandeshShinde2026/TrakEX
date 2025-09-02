import 'package:flutter/foundation.dart';
import '../models/currency_model.dart';
import '../constants/currency_constants.dart';
import '../services/currency_preferences_service.dart';
import '../services/currency_exchange_service.dart';

class CurrencyProvider with ChangeNotifier {
  final CurrencyPreferencesService _preferencesService = CurrencyPreferencesService();
  final CurrencyExchangeService _exchangeService = CurrencyExchangeService();

  CurrencyModel _defaultCurrency = CurrencyConstants.defaultCurrency;
  bool _autoConvertEnabled = true;
  bool _showOriginalAmount = true;
  bool _isLoading = false;
  Map<String, double>? _exchangeRates;
  DateTime? _lastRatesUpdate;

  // Getters
  CurrencyModel get defaultCurrency => _defaultCurrency;
  bool get autoConvertEnabled => _autoConvertEnabled;
  bool get showOriginalAmount => _showOriginalAmount;
  bool get isLoading => _isLoading;
  Map<String, double>? get exchangeRates => _exchangeRates;
  DateTime? get lastRatesUpdate => _lastRatesUpdate;

  /// Initialize currency provider
  Future<void> initialize({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user preferences
      await loadPreferences(userId: userId);
      
      // Load exchange rates
      await refreshExchangeRates();
    } catch (e) {
      debugPrint('Error initializing currency provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user preferences
  Future<void> loadPreferences({String? userId}) async {
    try {
      if (userId != null) {
        await _preferencesService.loadUserPreferences(userId);
      }

      final preferences = await _preferencesService.getAllPreferences();
      _defaultCurrency = preferences['defaultCurrency'];
      _autoConvertEnabled = preferences['autoConvertEnabled'];
      _showOriginalAmount = preferences['showOriginalAmount'];
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading currency preferences: $e');
    }
  }

  /// Set default currency
  Future<bool> setDefaultCurrency(CurrencyModel currency, {String? userId}) async {
    try {
      final success = await _preferencesService.setDefaultCurrency(currency, userId: userId);
      if (success) {
        _defaultCurrency = currency;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error setting default currency: $e');
      return false;
    }
  }

  /// Set auto-convert preference
  Future<bool> setAutoConvertEnabled(bool enabled, {String? userId}) async {
    try {
      final success = await _preferencesService.setAutoConvertEnabled(enabled, userId: userId);
      if (success) {
        _autoConvertEnabled = enabled;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error setting auto-convert preference: $e');
      return false;
    }
  }

  /// Set show original amount preference
  Future<bool> setShowOriginalAmount(bool show, {String? userId}) async {
    try {
      final success = await _preferencesService.setShowOriginalAmount(show, userId: userId);
      if (success) {
        _showOriginalAmount = show;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error setting show original amount preference: $e');
      return false;
    }
  }

  /// Refresh exchange rates
  Future<void> refreshExchangeRates() async {
    try {
      _exchangeRates = await _exchangeService.getExchangeRates('USD');
      _lastRatesUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing exchange rates: $e');
    }
  }

  /// Force refresh exchange rates (ignores cache)
  Future<void> forceRefreshExchangeRates() async {
    try {
      _isLoading = true;
      notifyListeners();

      _exchangeRates = await _exchangeService.forceRefreshRates('USD');
      _lastRatesUpdate = DateTime.now();

      debugPrint('Exchange rates force refreshed successfully');
    } catch (e) {
      debugPrint('Error force refreshing exchange rates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert currency amount
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      return await _exchangeService.convertCurrency(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
    } catch (e) {
      debugPrint('Error converting currency: $e');
      return amount;
    }
  }

  /// Get conversion text
  Future<String> getConversionText({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      return await _exchangeService.getConversionText(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
    } catch (e) {
      debugPrint('Error getting conversion text: $e');
      final fromCurrencyModel = CurrencyConstants.getCurrencyByCode(fromCurrency);
      return fromCurrencyModel?.formatAmount(amount) ?? '$amount $fromCurrency';
    }
  }

  /// Get exchange rate between two currencies
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      return await _exchangeService.getExchangeRate(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
    } catch (e) {
      debugPrint('Error getting exchange rate: $e');
      return null;
    }
  }

  /// Convert expense amount to default currency if needed
  Future<Map<String, dynamic>?> convertExpenseAmount({
    required double amount,
    required String currencyCode,
  }) async {
    if (!_autoConvertEnabled || currencyCode == _defaultCurrency.code) {
      return null;
    }

    try {
      final convertedAmount = await convertCurrency(
        amount: amount,
        fromCurrency: currencyCode,
        toCurrency: _defaultCurrency.code,
      );

      final exchangeRate = await getExchangeRate(
        fromCurrency: currencyCode,
        toCurrency: _defaultCurrency.code,
      );

      return {
        'convertedAmount': convertedAmount,
        'convertedCurrencyCode': _defaultCurrency.code,
        'exchangeRate': exchangeRate,
      };
    } catch (e) {
      debugPrint('Error converting expense amount: $e');
      return null;
    }
  }

  /// Format amount with currency
  String formatAmount(double amount, String currencyCode) {
    final currency = CurrencyConstants.getCurrencyByCode(currencyCode);
    return currency?.formatAmount(amount) ?? '$amount $currencyCode';
  }

  /// Get display text for expense amount
  String getExpenseDisplayText({
    required double originalAmount,
    required String originalCurrency,
    double? convertedAmount,
    String? convertedCurrency,
  }) {
    final originalText = formatAmount(originalAmount, originalCurrency);
    
    if (!_showOriginalAmount || 
        convertedAmount == null || 
        convertedCurrency == null ||
        originalCurrency == convertedCurrency) {
      return originalText;
    }

    final convertedText = formatAmount(convertedAmount, convertedCurrency);
    return '$originalText (≈$convertedText)';
  }

  /// Check if rates need refresh (older than 1 hour)
  bool get needsRatesRefresh {
    if (_lastRatesUpdate == null) return true;
    return DateTime.now().difference(_lastRatesUpdate!).inHours >= 1;
  }

  /// Auto-refresh rates if needed
  Future<void> autoRefreshRatesIfNeeded() async {
    if (needsRatesRefresh) {
      await refreshExchangeRates();
    }
  }

  /// Clear all data
  void clear() {
    _defaultCurrency = CurrencyConstants.defaultCurrency;
    _autoConvertEnabled = true;
    _showOriginalAmount = true;
    _exchangeRates = null;
    _lastRatesUpdate = null;
    notifyListeners();
  }

  /// Save all preferences to Firestore
  Future<void> savePreferences(String userId) async {
    try {
      await _preferencesService.saveUserPreferences(userId);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  /// Debug method to test current exchange rates
  Future<void> debugExchangeRates() async {
    try {
      debugPrint('=== Currency Exchange Rate Debug ===');

      // Test network connectivity first
      final networkOk = await _exchangeService.testNetworkConnectivity();
      debugPrint('Network connectivity test: ${networkOk ? "PASSED" : "FAILED"}');

      // Force refresh to get latest rates
      await forceRefreshExchangeRates();

      if (_exchangeRates != null) {
        final usdToInr = _exchangeRates!['INR'];
        debugPrint('Current USD to INR rate: $usdToInr');

        // Test conversion
        final testAmount = 1.0;
        final convertedAmount = await convertCurrency(
          amount: testAmount,
          fromCurrency: 'USD',
          toCurrency: 'INR',
        );
        debugPrint('$testAmount USD = $convertedAmount INR');

        // Show some other popular rates
        final eurRate = _exchangeRates!['EUR'];
        final gbpRate = _exchangeRates!['GBP'];
        debugPrint('USD to EUR: $eurRate');
        debugPrint('USD to GBP: $gbpRate');

        debugPrint('Last update: $_lastRatesUpdate');
        debugPrint('Using live exchange rates: ${networkOk ? "YES" : "NO (using fallback)"}');
      } else {
        debugPrint('No exchange rates available');
      }

      debugPrint('=== End Debug ===');
    } catch (e) {
      debugPrint('Error in debug exchange rates: $e');
    }
  }
}
