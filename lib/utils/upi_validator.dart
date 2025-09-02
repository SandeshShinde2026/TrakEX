import 'package:flutter/foundation.dart';

class UpiValidator {
  /// Validates a UPI ID based on standard UPI format
  /// UPI ID format: username@upiProvider
  /// Returns true if the UPI ID is valid, false otherwise
  static bool isValidUpiId(String? upiId) {
    if (upiId == null || upiId.isEmpty) {
      return false;
    }

    // Basic format check: should contain @ and no spaces
    if (!upiId.contains('@') || upiId.contains(' ')) {
      return false;
    }

    // Split the UPI ID into username and provider parts
    final parts = upiId.split('@');
    if (parts.length != 2) {
      return false;
    }

    final username = parts[0];
    final provider = parts[1];

    // Username validation: alphanumeric, period, underscore, hyphen
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username) || username.isEmpty) {
      return false;
    }

    // Provider validation: should be a known UPI provider
    if (!_isKnownUpiProvider(provider)) {
      return false;
    }

    return true;
  }

  /// Checks if the provider is a known UPI provider
  static bool _isKnownUpiProvider(String provider) {
    // List of common UPI providers in India
    final knownProviders = [
      'okaxis',      // Axis Bank
      'okicici',     // ICICI Bank
      'okhdfcbank',  // HDFC Bank
      'oksbi',       // State Bank of India
      'okbizaxis',   // Axis Bank Business
      'paytm',       // Paytm
      'upi',         // Generic UPI
      'apl',         // Amazon Pay
      'ybl',         // PhonePe
      'yesbank',     // Yes Bank
      'ibl',         // ICICI Bank
      'sbi',         // State Bank of India
      'hdfc',        // HDFC Bank
      'kotak',       // Kotak Mahindra Bank
      'axisbank',    // Axis Bank
      'axl',         // Axis Bank
      'pnb',         // Punjab National Bank
      'barodampay',  // Bank of Baroda
      'idfcbank',    // IDFC Bank
      'indus',       // IndusInd Bank
      'jupiteraxis', // Jupiter
      'freecharge',  // Freecharge
      'gpay',        // Google Pay
      'airtel',      // Airtel Payments Bank
      'icici',       // ICICI Bank
      'aubank',      // AU Small Finance Bank
      'dbs',         // DBS Bank
      'federal',     // Federal Bank
      'citi',        // Citibank
      'hsbc',        // HSBC Bank
      'rbl',         // RBL Bank
      'scb',         // Standard Chartered Bank
      'canara',      // Canara Bank
      'uco',         // UCO Bank
      'unionbank',   // Union Bank of India
      'bob',         // Bank of Baroda
      'boi',         // Bank of India
      'pockets',     // ICICI Pockets
      'pingpay',     // PingPay
      'fampay',      // FamPay
      'cred',        // CRED
      'slice',       // Slice
      'jio',         // Jio Payments Bank
      'myicici',     // ICICI Bank
      'yapl',        // Amazon Pay
      'abfspay',     // Aditya Birla Finance
      'bajajfinserv',// Bajaj Finserv
      'bandhan',     // Bandhan Bank
      'csbpay',      // CSB Bank
      'dcb',         // DCB Bank
      'equitas',     // Equitas Small Finance Bank
      'fino',        // Fino Payments Bank
      'idbi',        // IDBI Bank
      'indianbank',  // Indian Bank
      'iob',         // Indian Overseas Bank
      'jkb',         // Jammu & Kashmir Bank
      'kbl',         // Karnataka Bank
      'kvb',         // Karur Vysya Bank
      'lvb',         // Lakshmi Vilas Bank
      'mahb',        // Bank of Maharashtra
      'obc',         // Oriental Bank of Commerce
      'psb',         // Punjab & Sind Bank
      'sib',         // South Indian Bank
      'tjsb',        // TJSB Bank
      'ubi',         // Union Bank of India
      'ujjivan',     // Ujjivan Small Finance Bank
      'vijayabank',  // Vijaya Bank
      'yesbank',     // Yes Bank
    ];

    return knownProviders.contains(provider.toLowerCase());
  }

  /// Formats a UPI ID for display (e.g., adds @ if missing)
  static String formatUpiId(String input) {
    // Remove any spaces
    String formatted = input.replaceAll(' ', '');
    
    // If there's no @ symbol and it's not empty, suggest a format
    if (!formatted.contains('@') && formatted.isNotEmpty) {
      return '$formatted@upi';
    }
    
    return formatted;
  }

  /// Provides a helpful error message based on UPI ID validation
  static String? getUpiIdErrorMessage(String? upiId) {
    if (upiId == null || upiId.isEmpty) {
      return 'UPI ID cannot be empty';
    }

    if (!upiId.contains('@')) {
      return 'UPI ID must contain @ symbol (e.g., username@upi)';
    }

    final parts = upiId.split('@');
    if (parts.length != 2) {
      return 'UPI ID must be in format: username@provider';
    }

    final username = parts[0];
    final provider = parts[1];

    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username) || username.isEmpty) {
      return 'Username part can only contain letters, numbers, periods, underscores, and hyphens';
    }

    if (!_isKnownUpiProvider(provider)) {
      return 'Unknown UPI provider. Please check your UPI ID';
    }

    return null; // No error
  }

  /// Logs UPI validation issues for debugging
  static void logUpiValidationIssue(String upiId, String message) {
    debugPrint('UPI Validation Issue: $upiId - $message');
  }
}
