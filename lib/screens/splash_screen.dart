import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.largeSpacing),

              // App Name
              Text(
                AppConstants.appName,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900, // Extra bold
                  letterSpacing: 2.0, // Add letter spacing for elegance
                  shadows: [
                    Shadow(
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.extraLargeSpacing),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
    );
  }
}
