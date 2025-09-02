import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';
import '../constants/currency_constants.dart';

class CurrencyExchangeService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _fallbackUrl = 'https://api.fxratesapi.com/latest';
  static const String _backupUrl = 'https://open.er-api.com/v6/latest'; // Additional backup
  static const String _cacheKey = 'exchange_rates_cache';
  static const String _cacheTimestampKey = 'exchange_rates_timestamp';
  static const Duration _cacheValidDuration = Duration(minutes: 30); // Cache for 30 minutes for more frequent updates

  // Singleton pattern
  static final CurrencyExchangeService _instance = CurrencyExchangeService._internal();
  factory CurrencyExchangeService() => _instance;
  CurrencyExchangeService._internal();

  Map<String, double>? _cachedRates;
  DateTime? _lastFetchTime;

  /// Get exchange rates for a base currency
  Future<Map<String, double>?> getExchangeRates(String baseCurrency) async {
    try {
      // Check if we have valid cached data
      if (_cachedRates != null && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration) {
        return _cachedRates;
      }

      // Try to load from local cache first
      final cachedRates = await _loadCachedRates();
      if (cachedRates != null) {
        _cachedRates = cachedRates;
        return cachedRates;
      }

      // Fetch fresh data from API
      final rates = await _fetchExchangeRates(baseCurrency);
      if (rates != null) {
        _cachedRates = rates;
        _lastFetchTime = DateTime.now();
        await _saveCachedRates(rates);
        return rates;
      }

      // If all fails, return fallback rates
      return _getFallbackRates();
    } catch (e) {
      print('Error getting exchange rates: $e');
      return _getFallbackRates();
    }
  }

  /// Fetch exchange rates from API
  Future<Map<String, double>?> _fetchExchangeRates(String baseCurrency) async {
    // List of APIs to try in order
    final apiUrls = [
      '$_baseUrl/$baseCurrency',
      '$_fallbackUrl?base=$baseCurrency',
      '$_backupUrl/$baseCurrency',
    ];

    for (int i = 0; i < apiUrls.length; i++) {
      try {
        print('Trying API ${i + 1}: ${apiUrls[i]}');

        final response = await http.get(
          Uri.parse(apiUrls[i]),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'MujjarFunds/1.0',
          },
        ).timeout(const Duration(seconds: 15)); // Increased timeout

        print('API ${i + 1} response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          Map<String, double>? rates;

          // Different APIs have different response structures
          if (data['rates'] != null) {
            rates = Map<String, double>.from(data['rates']);
            print('Found rates in "rates" field');
          } else if (data['conversion_rates'] != null) {
            rates = Map<String, double>.from(data['conversion_rates']);
            print('Found rates in "conversion_rates" field');
          }

          if (rates != null && rates.isNotEmpty) {
            final inrRate = rates['INR'];
            print('Successfully fetched rates from API ${i + 1}. USD to INR: $inrRate');
            return rates;
          } else {
            print('API ${i + 1} returned empty rates');
          }
        } else {
          print('API ${i + 1} returned status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('API ${i + 1} failed with error: $e');
        // Continue to next API
      }
    }

    print('All exchange rate APIs failed, using fallback rates');
    return null;
  }

  /// Load cached exchange rates from local storage
  Future<Map<String, double>?> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) < _cacheValidDuration) {
          final rates = Map<String, double>.from(json.decode(cachedData));
          _lastFetchTime = cacheTime;
          return rates;
        }
      }
    } catch (e) {
      print('Error loading cached rates: $e');
    }
    return null;
  }

  /// Save exchange rates to local cache
  Future<void> _saveCachedRates(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(rates));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving cached rates: $e');
    }
  }

  /// Get fallback exchange rates (static rates as backup)
  Map<String, double> _getFallbackRates() {
    // Return approximate rates based on our currency constants
    final fallbackRates = <String, double>{};
    
    for (final currency in CurrencyConstants.supportedCurrencies) {
      fallbackRates[currency.code] = currency.exchangeRate;
    }
    
    return fallbackRates;
  }

  /// Convert amount from one currency to another
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    try {
      // Get exchange rates with USD as base
      final rates = await getExchangeRates('USD');
      if (rates == null) return amount;

      // Convert to USD first, then to target currency
      double amountInUSD = amount;
      if (fromCurrency != 'USD') {
        final fromRate = rates[fromCurrency];
        if (fromRate == null) return amount;
        amountInUSD = amount / fromRate;
      }

      // Convert from USD to target currency
      if (toCurrency == 'USD') {
        return amountInUSD;
      }

      final toRate = rates[toCurrency];
      if (toRate == null) return amount;

      return amountInUSD * toRate;
    } catch (e) {
      print('Error converting currency: $e');
      return amount;
    }
  }

  /// Get formatted conversion text
  Future<String> getConversionText({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      final currency = CurrencyConstants.getCurrencyByCode(fromCurrency);
      return currency?.formatAmount(amount) ?? '$amount $fromCurrency';
    }

    final convertedAmount = await convertCurrency(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );

    final fromCurrencyModel = CurrencyConstants.getCurrencyByCode(fromCurrency);
    final toCurrencyModel = CurrencyConstants.getCurrencyByCode(toCurrency);

    final originalText = fromCurrencyModel?.formatAmount(amount) ?? '$amount $fromCurrency';
    final convertedText = toCurrencyModel?.formatAmount(convertedAmount) ?? '$convertedAmount $toCurrency';

    return '$originalText ≈ $convertedText';
  }

  /// Get current exchange rate between two currencies
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return 1.0;

    try {
      final rates = await getExchangeRates('USD');
      if (rates == null) return null;

      final fromRate = rates[fromCurrency] ?? 1.0;
      final toRate = rates[toCurrency] ?? 1.0;

      if (fromCurrency == 'USD') return toRate;
      if (toCurrency == 'USD') return 1.0 / fromRate;

      return toRate / fromRate;
    } catch (e) {
      print('Error getting exchange rate: $e');
      return null;
    }
  }

  /// Clear cached data (useful for testing or manual refresh)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      _cachedRates = null;
      _lastFetchTime = null;
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Force refresh exchange rates (ignores cache)
  Future<Map<String, double>?> forceRefreshRates(String baseCurrency) async {
    try {
      // Clear cache first
      await clearCache();

      // Fetch fresh data
      final rates = await _fetchExchangeRates(baseCurrency);
      if (rates != null) {
        _cachedRates = rates;
        _lastFetchTime = DateTime.now();
        await _saveCachedRates(rates);
        return rates;
      }

      return _getFallbackRates();
    } catch (e) {
      print('Error force refreshing rates: $e');
      return _getFallbackRates();
    }
  }

  /// Check if cached data is available and valid
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateTime.now().difference(cacheTime) < _cacheValidDuration;
      }
    } catch (e) {
      print('Error checking cache validity: $e');
    }
    return false;
  }

  /// Test network connectivity and API access
  Future<bool> testNetworkConnectivity() async {
    try {
      print('Testing network connectivity...');

      // Test a simple HTTP request first
      final response = await http.get(
        Uri.parse('https://httpbin.org/json'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Basic HTTP connectivity: OK');

        // Now test our exchange rate API
        final exchangeResponse = await http.get(
          Uri.parse('$_baseUrl/USD'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (exchangeResponse.statusCode == 200) {
          print('Exchange rate API connectivity: OK');
          final data = json.decode(exchangeResponse.body);
          final inrRate = data['rates']?['INR'];
          print('Current USD to INR rate: $inrRate');
          return true;
        } else {
          print('Exchange rate API failed: ${exchangeResponse.statusCode}');
        }
      } else {
        print('Basic HTTP connectivity failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Network connectivity test failed: $e');
    }
    return false;
  }
}
