import '../models/currency_model.dart';

class CurrencyConstants {
  // Popular currencies with approximate exchange rates (these should be updated from an API in production)
  static const List<CurrencyModel> supportedCurrencies = [
    // Major currencies
    CurrencyModel(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      exchangeRate: 1.0, // Base currency
    ),
    CurrencyModel(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      exchangeRate: 0.85,
    ),
    CurrencyModel(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
      exchangeRate: 0.73,
    ),
    CurrencyModel(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      flag: '🇮🇳',
      exchangeRate: 86.13, // Updated to current rate
    ),
    CurrencyModel(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      flag: '🇯🇵',
      exchangeRate: 150.0,
    ),
    CurrencyModel(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      flag: '🇨🇳',
      exchangeRate: 7.2,
    ),
    CurrencyModel(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      flag: '🇨🇦',
      exchangeRate: 1.35,
    ),
    CurrencyModel(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
      exchangeRate: 1.50,
    ),
    CurrencyModel(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      flag: '🇨🇭',
      exchangeRate: 0.88,
    ),
    CurrencyModel(
      code: 'SEK',
      name: 'Swedish Krona',
      symbol: 'kr',
      flag: '🇸🇪',
      exchangeRate: 10.5,
    ),
    
    // Asian currencies
    CurrencyModel(
      code: 'KRW',
      name: 'South Korean Won',
      symbol: '₩',
      flag: '🇰🇷',
      exchangeRate: 1320.0,
    ),
    CurrencyModel(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      flag: '🇸🇬',
      exchangeRate: 1.35,
    ),
    CurrencyModel(
      code: 'HKD',
      name: 'Hong Kong Dollar',
      symbol: 'HK\$',
      flag: '🇭🇰',
      exchangeRate: 7.8,
    ),
    CurrencyModel(
      code: 'THB',
      name: 'Thai Baht',
      symbol: '฿',
      flag: '🇹🇭',
      exchangeRate: 35.0,
    ),
    CurrencyModel(
      code: 'MYR',
      name: 'Malaysian Ringgit',
      symbol: 'RM',
      flag: '🇲🇾',
      exchangeRate: 4.7,
    ),
    CurrencyModel(
      code: 'IDR',
      name: 'Indonesian Rupiah',
      symbol: 'Rp',
      flag: '🇮🇩',
      exchangeRate: 15500.0,
    ),
    CurrencyModel(
      code: 'PHP',
      name: 'Philippine Peso',
      symbol: '₱',
      flag: '🇵🇭',
      exchangeRate: 56.0,
    ),
    CurrencyModel(
      code: 'VND',
      name: 'Vietnamese Dong',
      symbol: '₫',
      flag: '🇻🇳',
      exchangeRate: 24000.0,
    ),
    
    // Middle East & Africa
    CurrencyModel(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'د.إ',
      flag: '🇦🇪',
      exchangeRate: 3.67,
    ),
    CurrencyModel(
      code: 'SAR',
      name: 'Saudi Riyal',
      symbol: '﷼',
      flag: '🇸🇦',
      exchangeRate: 3.75,
    ),
    CurrencyModel(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      flag: '🇿🇦',
      exchangeRate: 18.5,
    ),
    
    // Latin America
    CurrencyModel(
      code: 'BRL',
      name: 'Brazilian Real',
      symbol: 'R\$',
      flag: '🇧🇷',
      exchangeRate: 5.0,
    ),
    CurrencyModel(
      code: 'MXN',
      name: 'Mexican Peso',
      symbol: '\$',
      flag: '🇲🇽',
      exchangeRate: 17.0,
    ),
    CurrencyModel(
      code: 'ARS',
      name: 'Argentine Peso',
      symbol: '\$',
      flag: '🇦🇷',
      exchangeRate: 350.0,
    ),
    
    // Cryptocurrencies (optional)
    CurrencyModel(
      code: 'BTC',
      name: 'Bitcoin',
      symbol: '₿',
      flag: '₿',
      exchangeRate: 0.000023, // 1 USD = 0.000023 BTC (approximate)
    ),
    CurrencyModel(
      code: 'ETH',
      name: 'Ethereum',
      symbol: 'Ξ',
      flag: 'Ξ',
      exchangeRate: 0.00045, // 1 USD = 0.00045 ETH (approximate)
    ),
  ];

  // Default currency (Indian Rupee to match current app)
  static const CurrencyModel defaultCurrency = CurrencyModel(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    flag: '🇮🇳',
    exchangeRate: 86.13, // Updated to current rate
  );

  // Get currency by code
  static CurrencyModel? getCurrencyByCode(String code) {
    try {
      return supportedCurrencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  // Get popular currencies (top 10)
  static List<CurrencyModel> getPopularCurrencies() {
    return supportedCurrencies.take(10).toList();
  }

  // Search currencies by name or code
  static List<CurrencyModel> searchCurrencies(String query) {
    if (query.isEmpty) return supportedCurrencies;
    
    final lowerQuery = query.toLowerCase();
    return supportedCurrencies.where((currency) {
      return currency.name.toLowerCase().contains(lowerQuery) ||
             currency.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Group currencies by region
  static Map<String, List<CurrencyModel>> getCurrenciesByRegion() {
    return {
      'Major Currencies': supportedCurrencies.take(4).toList(),
      'Asia Pacific': supportedCurrencies.skip(4).take(8).toList(),
      'Middle East & Africa': supportedCurrencies.skip(12).take(3).toList(),
      'Americas': supportedCurrencies.skip(15).take(3).toList(),
      'Crypto': supportedCurrencies.skip(18).take(2).toList(),
    };
  }
}
