import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2196F3), // Clean blue
      secondary: Color(0xFF2196F3),
      surface: Color(0xFFFAFAFA), // Very light gray background
      error: Color(0xFFF44336), // Clean red
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF212121), // Dark gray text
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF212121)),
      headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF212121)),
      headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF212121)),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF212121)),
      bodyMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF212121)),
      bodySmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF757575)),
      labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF212121)),
      labelMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF757575)),
      labelSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF757575)),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2196F3),
      unselectedItemColor: Color(0xFF757575),
      backgroundColor: Colors.white,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2196F3), // Clean blue
      secondary: Color(0xFF2196F3),
      surface: Color(0xFF121212), // Dark background
      error: Color(0xFFF44336), // Clean red
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
      headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
      headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
      bodyMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
      bodySmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
      labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
      labelMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
      labelSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFF424242), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2196F3),
      unselectedItemColor: Color(0xFF757575),
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Simplified color palette - only 4 colors
  static const Color primaryColor = Color(0xFF2196F3); // Clean blue
  static const Color successColor = Color(0xFF4CAF50); // Simple green
  static const Color warningColor = Color(0xFFFF9800); // Subtle orange
  static const Color errorColor = Color(0xFFF44336); // Clean red

  // Neutral colors
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF757575);
  static const Color darkGray = Color(0xFF424242);

  // Context-aware text styles - use these methods instead of static styles
  static TextStyle getHeadingStyle(BuildContext context) => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).textTheme.headlineSmall?.color,
  );

  static TextStyle getBodyStyle(BuildContext context) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).textTheme.bodyLarge?.color,
  );

  static TextStyle getCaptionStyle(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).textTheme.bodySmall?.color ?? mediumGray,
  );

  // Legacy static styles (kept for backward compatibility, but prefer context-aware methods above)
  static TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle captionStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: mediumGray,
  );

  // Consistent spacing - 16px base unit
  static const double smallSpacing = 8.0;   // 0.5x base
  static const double mediumSpacing = 16.0; // 1x base
  static const double largeSpacing = 32.0;  // 2x base
  static const double extraLargeSpacing = 48.0; // 3x base

  // Border radius
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
}
