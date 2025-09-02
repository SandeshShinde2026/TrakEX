import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  // Format amount to currency string
  static String format(double amount, {String? symbol, int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: symbol ?? AppConstants.currencySymbol,
      decimalDigits: decimalDigits,
    );
    
    return formatter.format(amount);
  }

  // Format amount to compact currency string (e.g., $1.2K)
  static String formatCompact(double amount, {String? symbol}) {
    final formatter = NumberFormat.compactCurrency(
      symbol: symbol ?? AppConstants.currencySymbol,
    );
    
    return formatter.format(amount);
  }

  // Parse currency string to double
  static double? parse(String amountStr, {String? symbol}) {
    try {
      final cleanString = amountStr
          .replaceAll(symbol ?? AppConstants.currencySymbol, '')
          .replaceAll(',', '')
          .trim();
      
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }

  // Format with color indicator (positive/negative)
  static Map<String, dynamic> formatWithColor(double amount, {String? symbol, int decimalDigits = 2}) {
    final formattedAmount = format(amount.abs(), symbol: symbol, decimalDigits: decimalDigits);
    
    if (amount < 0) {
      return {
        'text': '-$formattedAmount',
        'isNegative': true,
      };
    } else {
      return {
        'text': formattedAmount,
        'isNegative': false,
      };
    }
  }

  // Format for display in list items (shorter format)
  static String formatShort(double amount, {String? symbol}) {
    if (amount.abs() >= 1000000) {
      return '${symbol ?? AppConstants.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${symbol ?? AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${symbol ?? AppConstants.currencySymbol}${amount.toStringAsFixed(0)}';
    }
  }
}
