import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';

/// Ads service managing UMP consent and Rewarded Ads per spec §20.6.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  final ValueNotifier<bool> isRewardedLoadedNotifier = ValueNotifier<bool>(false);

  /// Test hook for widget tests to simulate rewarded ad show callback without native SDK.
  Future<bool> Function({required VoidCallback onUserEarnedReward})? testShowHandler;

  bool get isRewardedLoaded => isRewardedLoadedNotifier.value;

  /// Initializes Mobile Ads SDK and requests UMP consent if supported on device.
  Future<void> init() async {
    if (!C.adsEnabled) return;

    // Mobile platforms only
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      // 1. UMP Consent flow
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            // Consent flow finished or not required; proceed to initialize SDK
            _initializeMobileAds();
          });
        },
        (formError) {
          debugPrint('AdsService: UMP consent error: ${formError.message}');
          // If consent fails, still attempt to initialize with non-personalized ads
          _initializeMobileAds();
        },
      );
    } catch (e) {
      debugPrint('AdsService.init exception: $e');
    }
  }

  Future<void> _initializeMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdsService: MobileAds.initialize exception: $e');
    }
  }

  /// Loads a rewarded ad with Google's test ad unit ID.
  void loadRewardedAd() {
    if (!C.adsEnabled) return;
    if (_isLoading || _rewardedAd != null) return;

    // Mobile platforms only
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _isLoading = true;
    try {
      RewardedAd.load(
        adUnitId: C.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isLoading = false;
            isRewardedLoadedNotifier.value = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdsService: Rewarded ad failed to load: $error');
            _rewardedAd = null;
            _isLoading = false;
            isRewardedLoadedNotifier.value = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdsService.loadRewardedAd exception: $e');
      _isLoading = false;
      isRewardedLoadedNotifier.value = false;
    }
  }

  /// Shows the preloaded rewarded ad.
  /// Calls [onUserEarnedReward] strictly once upon SDK reward confirmation.
  /// Offline or failure never throws and never blocks callers.
  Future<bool> showRewardedAd({required VoidCallback onUserEarnedReward}) async {
    if (testShowHandler != null) {
      isRewardedLoadedNotifier.value = false;
      return testShowHandler!(onUserEarnedReward: onUserEarnedReward);
    }

    final ad = _rewardedAd;
    if (ad == null || !isRewardedLoaded) {
      return false;
    }

    // Immediately mark as not loaded to prevent double triggers
    isRewardedLoadedNotifier.value = false;
    _rewardedAd = null;

    bool rewardGranted = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('AdsService: Rewarded ad failed to show: $error');
        ad.dispose();
        loadRewardedAd();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (!rewardGranted) {
            rewardGranted = true;
            onUserEarnedReward();
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint('AdsService.showRewardedAd exception: $e');
      ad.dispose();
      loadRewardedAd();
      return false;
    }
  }

  /// Cleans up ad instance.
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
    isRewardedLoadedNotifier.value = false;
  }
}
