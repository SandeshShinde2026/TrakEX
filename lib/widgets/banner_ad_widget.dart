import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';

class BannerAdWidget extends StatelessWidget {
  final String adLocation;
  final EdgeInsetsGeometry? margin;
  final bool showCloseButton;

  const BannerAdWidget({
    super.key,
    required this.adLocation,
    this.margin,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        // Don't show ads for premium users
        if (adProvider.isPremiumUser) {
          return const SizedBox.shrink();
        }

        BannerAd? bannerAd;
        bool isLoaded = false;

        // Get the appropriate banner ad based on location
        switch (adLocation) {
          case 'dashboard':
            bannerAd = adProvider.dashboardBannerAd;
            isLoaded = adProvider.isDashboardBannerLoaded;
            break;
          case 'expenses':
            bannerAd = adProvider.expensesBannerAd;
            isLoaded = adProvider.isExpensesBannerLoaded;
            break;
          default:
            return const SizedBox.shrink();
        }

        // Don't show if ad is not loaded
        if (!isLoaded || bannerAd == null) {
          return const SizedBox.shrink();
        }

        // Wrap in try-catch to prevent crashes
        try {
          return Container(
          margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Stack(
              children: [
                // Ad container
                Container(
                  width: bannerAd.size.width.toDouble(),
                  height: bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: bannerAd),
                ),

                // Close button (optional)
                if (showCloseButton)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        // Handle ad close (could hide for session)
                        _handleAdClose(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                // Ad label (required by AdMob policies)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Ad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        } catch (e) {
          debugPrint('Error displaying banner ad: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  void _handleAdClose(BuildContext context) {
    // You could implement session-based ad hiding here
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ad closed for this session'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Adaptive banner ad widget that adjusts to screen size
class AdaptiveBannerAdWidget extends StatelessWidget {
  final String adLocation;
  final EdgeInsetsGeometry? margin;

  const AdaptiveBannerAdWidget({
    super.key,
    required this.adLocation,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        if (adProvider.isPremiumUser) {
          return const SizedBox.shrink();
        }

        // Get screen width to determine ad size
        final screenWidth = MediaQuery.of(context).size.width;

        // Use different ad sizes based on screen width
        if (screenWidth < 600) {
          // Mobile: Standard banner
          return BannerAdWidget(
            adLocation: adLocation,
            margin: margin,
          );
        } else {
          // Tablet/Desktop: Larger banner
          return BannerAdWidget(
            adLocation: adLocation,
            margin: margin,
          );
        }
      },
    );
  }
}

// Sticky Banner Ad Widget that stays at the bottom of the screen
class StickyBannerAdWidget extends StatelessWidget {
  final String adLocation;
  final Widget child;

  const StickyBannerAdWidget({
    super.key,
    required this.adLocation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, _) {
        // Don't show ads for premium users
        if (adProvider.isPremiumUser) {
          return child;
        }

        BannerAd? bannerAd;
        bool isLoaded = false;

        // Get the appropriate banner ad based on location
        switch (adLocation) {
          case 'dashboard':
            bannerAd = adProvider.dashboardBannerAd;
            isLoaded = adProvider.isDashboardBannerLoaded;
            break;
          case 'expenses':
            bannerAd = adProvider.expensesBannerAd;
            isLoaded = adProvider.isExpensesBannerLoaded;
            break;
          default:
            return child;
        }

        // If ad is not loaded, show content without ad
        if (!isLoaded || bannerAd == null) {
          return child;
        }

        // Calculate ad height
        final adHeight = bannerAd.size.height.toDouble() + 16.0; // Add padding

        return Stack(
          children: [
            // Main content with bottom padding to avoid overlap with ad
            Positioned.fill(
              bottom: adHeight,
              child: child,
            ),

            // Sticky banner ad at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: adHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                        width: bannerAd.size.width.toDouble(),
                        height: bannerAd.size.height.toDouble(),
                        child: AdWidget(ad: bannerAd),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Native ad placeholder widget (for future implementation)
class NativeAdWidget extends StatelessWidget {
  final String adLocation;
  final EdgeInsetsGeometry? margin;

  const NativeAdWidget({
    super.key,
    required this.adLocation,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        if (adProvider.isPremiumUser) {
          return const SizedBox.shrink();
        }

        // Placeholder for native ads
        // Native ads require more complex implementation
        return Container(
          margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.ads_click,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sponsored Content',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Native ad content will appear here',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Text(
                'Ad',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
