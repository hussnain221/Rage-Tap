import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';

/// Ads service managing UMP consent, Rewarded Ads, and Interstitial Ads per spec §20.6.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  // Rewarded ad state
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;
  final ValueNotifier<bool> isRewardedLoadedNotifier = ValueNotifier<bool>(false);

  // Interstitial ad state
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  final ValueNotifier<bool> isInterstitialLoadedNotifier = ValueNotifier<bool>(false);

  // Interstitial frequency pacing
  int _completedRunsSinceLastInterstitial = 0;
  DateTime _lastInterstitialTime = DateTime.now();

  // Test hooks & overrides
  bool? _interstitialsEnabledOverride;
  DateTime Function()? testCurrentTimeProvider;
  Future<bool> Function({required VoidCallback onUserEarnedReward})? testShowHandler;
  Future<bool> Function({required VoidCallback onDismissed})? testInterstitialShowHandler;

  bool get isRewardedLoaded => isRewardedLoadedNotifier.value;
  bool get isInterstitialLoaded => isInterstitialLoadedNotifier.value;
  int get completedRunsSinceLastInterstitial => _completedRunsSinceLastInterstitial;
  DateTime get lastInterstitialTime => _lastInterstitialTime;
  bool get interstitialsEnabled => _interstitialsEnabledOverride ?? C.interstitialsEnabled;

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
      if (interstitialsEnabled) {
        loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('AdsService: MobileAds.initialize exception: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Rewarded Ads (§20.6)
  // ---------------------------------------------------------------------------

  /// Loads a rewarded ad with Google's test ad unit ID.
  void loadRewardedAd() {
    if (!C.adsEnabled) return;
    if (_isRewardedLoading || _rewardedAd != null) return;

    // Mobile platforms only
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _isRewardedLoading = true;
    try {
      RewardedAd.load(
        adUnitId: C.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedLoading = false;
            isRewardedLoadedNotifier.value = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdsService: Rewarded ad failed to load: $error');
            _rewardedAd = null;
            _isRewardedLoading = false;
            isRewardedLoadedNotifier.value = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdsService.loadRewardedAd exception: $e');
      _isRewardedLoading = false;
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

  // ---------------------------------------------------------------------------
  // Interstitial Ads (§20.6)
  // ---------------------------------------------------------------------------

  /// Records a completed run for interstitial pacing (§20.6).
  void recordRunCompleted() {
    _completedRunsSinceLastInterstitial++;
    if (C.adsEnabled && interstitialsEnabled && !isInterstitialLoaded) {
      loadInterstitialAd();
    }
  }

  /// Whether strict limits for showing an interstitial ad are met:
  /// - Interstitials enabled switch is true
  /// - At least 4 completed runs since the last one
  /// - At least 3 minutes (180s) since the last one
  /// - An interstitial ad is loaded and ready
  bool canShowInterstitial({DateTime? now}) {
    if (!C.adsEnabled || !interstitialsEnabled) return false;
    if (!isInterstitialLoaded) return false;
    if (_completedRunsSinceLastInterstitial < C.interstitialMinRuns) return false;

    final currentTime = now ?? (testCurrentTimeProvider?.call() ?? DateTime.now());
    final elapsedSec = currentTime.difference(_lastInterstitialTime).inSeconds;
    if (elapsedSec < C.interstitialMinIntervalSec) return false;

    return true;
  }

  /// Loads an interstitial ad with Google's test ad unit ID.
  void loadInterstitialAd() {
    if (!C.adsEnabled || !interstitialsEnabled) return;
    if (_isInterstitialLoading || _interstitialAd != null) return;

    // Mobile platforms only
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _isInterstitialLoading = true;
    try {
      InterstitialAd.load(
        adUnitId: C.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialLoading = false;
            isInterstitialLoadedNotifier.value = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdsService: Interstitial ad failed to load: $error');
            _interstitialAd = null;
            _isInterstitialLoading = false;
            isInterstitialLoadedNotifier.value = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdsService.loadInterstitialAd exception: $e');
      _isInterstitialLoading = false;
      isInterstitialLoadedNotifier.value = false;
    }
  }

  /// Shows the interstitial if eligible per spec §20.6 limits.
  /// Calls [onAction] when the ad is closed, or immediately if ineligible/failed.
  /// Failure or offline NEVER delays or blocks callers.
  Future<bool> showInterstitialIfEligible({
    required VoidCallback onAction,
    DateTime? now,
  }) async {
    if (!canShowInterstitial(now: now)) {
      onAction();
      return false;
    }

    // Test hook for unit/widget tests
    if (testInterstitialShowHandler != null) {
      _completedRunsSinceLastInterstitial = 0;
      _lastInterstitialTime = now ?? (testCurrentTimeProvider?.call() ?? DateTime.now());
      isInterstitialLoadedNotifier.value = false;
      return testInterstitialShowHandler!(onDismissed: onAction);
    }

    final ad = _interstitialAd;
    if (ad == null || !isInterstitialLoaded) {
      onAction();
      return false;
    }

    isInterstitialLoadedNotifier.value = false;
    _interstitialAd = null;
    _completedRunsSinceLastInterstitial = 0;
    _lastInterstitialTime = now ?? (testCurrentTimeProvider?.call() ?? DateTime.now());

    bool actionInvoked = false;
    void invokeActionOnce() {
      if (!actionInvoked) {
        actionInvoked = true;
        onAction();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        invokeActionOnce();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('AdsService: Interstitial ad failed to show: $error');
        ad.dispose();
        invokeActionOnce();
        loadInterstitialAd();
      },
    );

    try {
      await ad.show();
      return true;
    } catch (e) {
      debugPrint('AdsService.showInterstitial exception: $e');
      ad.dispose();
      invokeActionOnce();
      loadInterstitialAd();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Testing & Lifecycle helpers
  // ---------------------------------------------------------------------------

  void setInterstitialsEnabledForTesting(bool? enabled) {
    _interstitialsEnabledOverride = enabled;
  }

  void resetTrackingForTesting({
    int completedRuns = 0,
    DateTime? lastTime,
    bool? isLoaded,
  }) {
    _completedRunsSinceLastInterstitial = completedRuns;
    _lastInterstitialTime = lastTime ?? DateTime.now();
    if (isLoaded != null) {
      isInterstitialLoadedNotifier.value = isLoaded;
    }
  }

  /// Cleans up ad instances.
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedLoading = false;
    isRewardedLoadedNotifier.value = false;

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoading = false;
    isInterstitialLoadedNotifier.value = false;

    _interstitialsEnabledOverride = null;
    testCurrentTimeProvider = null;
    testShowHandler = null;
    testInterstitialShowHandler = null;
  }
}
