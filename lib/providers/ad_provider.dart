import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class AdProvider extends ChangeNotifier {
  final AdService _adService = AdService();

  // Banner ads
  BannerAd? _dashboardBannerAd;
  BannerAd? _expensesBannerAd;
  bool _isDashboardBannerLoaded = false;
  bool _isExpensesBannerLoaded = false;

  // Interstitial ads
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;

  // Rewarded ads
  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;

  // Ad frequency control
  int _expenseAddCount = 0;
  int _interstitialFrequency = 5; // Show interstitial every 5 expense additions

  // Premium status (to disable ads)
  bool _isPremiumUser = false;

  // Getters
  BannerAd? get dashboardBannerAd => _dashboardBannerAd;
  BannerAd? get expensesBannerAd => _expensesBannerAd;
  bool get isDashboardBannerLoaded => _isDashboardBannerLoaded;
  bool get isExpensesBannerLoaded => _isExpensesBannerLoaded;
  bool get isInterstitialLoaded => _isInterstitialLoaded;
  bool get isRewardedLoaded => _isRewardedLoaded;
  bool get isPremiumUser => _isPremiumUser;

  // Initialize ads
  Future<void> initializeAds() async {
    if (_isPremiumUser) return;

    await _loadDashboardBanner();
    await _loadExpensesBanner();
    await _loadInterstitialAd();
    await _loadRewardedAd();
  }

  // Load dashboard banner ad
  Future<void> _loadDashboardBanner() async {
    _dashboardBannerAd = _adService.createBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        _isDashboardBannerLoaded = true;
        notifyListeners();
        debugPrint('Dashboard banner ad loaded');
      },
      onAdFailedToLoad: (ad, error) {
        _isDashboardBannerLoaded = false;
        ad.dispose();
        notifyListeners();
        debugPrint('Dashboard banner ad failed to load: $error');
      },
    );

    await _dashboardBannerAd?.load();
  }

  // Load expenses banner ad
  Future<void> _loadExpensesBanner() async {
    _expensesBannerAd = _adService.createBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        _isExpensesBannerLoaded = true;
        notifyListeners();
        debugPrint('Expenses banner ad loaded');
      },
      onAdFailedToLoad: (ad, error) {
        _isExpensesBannerLoaded = false;
        ad.dispose();
        notifyListeners();
        debugPrint('Expenses banner ad failed to load: $error');
      },
    );

    await _expensesBannerAd?.load();
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    _interstitialAd = await AdService.loadInterstitialAd();
    _isInterstitialLoaded = _interstitialAd != null;
    notifyListeners();
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    _rewardedAd = await AdService.loadRewardedAd();
    _isRewardedLoaded = _rewardedAd != null;
    notifyListeners();
  }

  // Show interstitial ad after expense addition
  void onExpenseAdded() {
    if (_isPremiumUser) return;

    _expenseAddCount++;
    if (_expenseAddCount >= _interstitialFrequency && _isInterstitialLoaded) {
      showInterstitialAd();
      _expenseAddCount = 0;
    }
  }

  // Show interstitial ad
  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_isPremiumUser || !_isInterstitialLoaded) {
      onAdClosed?.call();
      return;
    }

    AdService.showInterstitialAd(
      _interstitialAd,
      onAdClosed: () {
        _isInterstitialLoaded = false;
        _loadInterstitialAd(); // Preload next ad
        onAdClosed?.call();
      },
    );
  }

  // Show rewarded ad for premium features
  void showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (!_isRewardedLoaded) {
      onAdClosed?.call();
      return;
    }

    AdService.showRewardedAd(
      _rewardedAd,
      onUserEarnedReward: onUserEarnedReward,
      onAdClosed: () {
        _isRewardedLoaded = false;
        _loadRewardedAd(); // Preload next ad
        onAdClosed?.call();
      },
    );
  }

  // Set premium status
  void setPremiumStatus(bool isPremium) {
    _isPremiumUser = isPremium;
    if (isPremium) {
      _disposeBannerAds();
    } else {
      initializeAds();
    }
    notifyListeners();
  }

  // Dispose banner ads
  void _disposeBannerAds() {
    _dashboardBannerAd?.dispose();
    _expensesBannerAd?.dispose();
    _dashboardBannerAd = null;
    _expensesBannerAd = null;
    _isDashboardBannerLoaded = false;
    _isExpensesBannerLoaded = false;
  }

  @override
  void dispose() {
    _dashboardBannerAd?.dispose();
    _expensesBannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
