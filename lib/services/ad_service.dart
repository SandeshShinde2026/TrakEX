import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs (replace with real ones for production)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Production Ad Unit IDs (replace with your actual AdMob IDs)
  static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Get appropriate ad unit IDs based on platform and build mode
  String get bannerAdUnitId {
    // Use test ads until production ad unit IDs are configured
    if (kDebugMode || _prodBannerAdUnitId.contains('XXXXXXXXXXXXXXXX')) {
      return _testBannerAdUnitId;
    }
    return Platform.isAndroid ? _prodBannerAdUnitId : _prodBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    // Use test ads until production ad unit IDs are configured
    if (kDebugMode || _prodInterstitialAdUnitId.contains('XXXXXXXXXXXXXXXX')) {
      return _testInterstitialAdUnitId;
    }
    return Platform.isAndroid ? _prodInterstitialAdUnitId : _prodInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    // Use test ads until production ad unit IDs are configured
    if (kDebugMode || _prodRewardedAdUnitId.contains('XXXXXXXXXXXXXXXX')) {
      return _testRewardedAdUnitId;
    }
    return Platform.isAndroid ? _prodRewardedAdUnitId : _prodRewardedAdUnitId;
  }

  // Initialize AdMob
  static Future<void> initialize() async {
    // Configure test device settings for better ad testing
    final RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: <String>[
        'kGADSimulatorID', // iOS Simulator
        // Add your physical device's advertising ID here for testing
        // You can find it in the AdMob logs when running the app
      ],
    );
    MobileAds.instance.updateRequestConfiguration(configuration);

    await MobileAds.instance.initialize();
    debugPrint('AdMob initialized successfully');

    // Print current ad unit IDs for debugging
    final adService = AdService();
    debugPrint('Using Banner Ad Unit ID: ${adService.bannerAdUnitId}');
    debugPrint('Using Interstitial Ad Unit ID: ${adService.interstitialAdUnitId}');
    debugPrint('Using Rewarded Ad Unit ID: ${adService.rewardedAdUnitId}');
    debugPrint('Debug mode: $kDebugMode');
  }

  // Create banner ad
  BannerAd createBannerAd({
    required AdSize adSize,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    required void Function(Ad) onAdLoaded,
  }) {
    final adUnitId = bannerAdUnitId;
    debugPrint('Creating banner ad with unit ID: $adUnitId');

    return BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully with unit ID: $adUnitId');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load with unit ID: $adUnitId');
          debugPrint('Error: ${error.message} (Code: ${error.code})');
          onAdFailedToLoad(ad, error);
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
        onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
      ),
    );
  }

  // Load interstitial ad
  static Future<InterstitialAd?> loadInterstitialAd() async {
    InterstitialAd? interstitialAd;

    await InterstitialAd.load(
      adUnitId: AdService()._getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );

    return interstitialAd;
  }

  // Load rewarded ad
  static Future<RewardedAd?> loadRewardedAd() async {
    RewardedAd? rewardedAd;

    await RewardedAd.load(
      adUnitId: AdService()._getRewardedAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );

    return rewardedAd;
  }

  String _getInterstitialAdUnitId() {
    // Use test ads until production ad unit IDs are configured
    if (kDebugMode || _prodInterstitialAdUnitId.contains('XXXXXXXXXXXXXXXX')) {
      return _testInterstitialAdUnitId;
    }
    return Platform.isAndroid ? _prodInterstitialAdUnitId : _prodInterstitialAdUnitId;
  }

  String _getRewardedAdUnitId() {
    // Use test ads until production ad unit IDs are configured
    if (kDebugMode || _prodRewardedAdUnitId.contains('XXXXXXXXXXXXXXXX')) {
      return _testRewardedAdUnitId;
    }
    return Platform.isAndroid ? _prodRewardedAdUnitId : _prodRewardedAdUnitId;
  }

  // Show interstitial ad with callback
  static void showInterstitialAd(InterstitialAd? ad, {VoidCallback? onAdClosed}) {
    if (ad != null) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onAdClosed?.call();
          debugPrint('Interstitial ad dismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          onAdClosed?.call();
          debugPrint('Interstitial ad failed to show: $error');
        },
      );
      ad.show();
    } else {
      onAdClosed?.call();
    }
  }

  // Show rewarded ad with reward callback
  static void showRewardedAd(
    RewardedAd? ad, {
    required OnUserEarnedRewardCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (ad != null) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onAdClosed?.call();
          debugPrint('Rewarded ad dismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          onAdClosed?.call();
          debugPrint('Rewarded ad failed to show: $error');
        },
      );
      ad.show(onUserEarnedReward: onUserEarnedReward);
    } else {
      onAdClosed?.call();
    }
  }
}
