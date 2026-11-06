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

  // Interstitial frequency pacing (starts in the past so first eligible session can trigger)
  int _completedRunsSinceLastInterstitial = 0;
  DateTime _lastInterstitialTime = DateTime.now().subtract(const Duration(minutes: 5));

  // SDK init guard
  bool _isMobileAdsInitialized = false;

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

    debugPrint('[AdsService] init starting. Initializing MobileAds...');
    // Immediately initialize MobileAds so test ads preload right away
    _initializeMobileAds();

    try {
      // 1. UMP Consent flow concurrently
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint('[AdsService] UMP consent form error: ${formError.message}');
            } else {
              debugPrint('[AdsService] UMP consent form completed/not required');
            }
          });
        },
        (formError) {
          debugPrint('[AdsService] UMP consent info error: ${formError.message}');
        },
      );
    } catch (e) {
      debugPrint('[AdsService] UMP exception: $e');
    }
  }

  Future<void> _initializeMobileAds() async {
    if (_isMobileAdsInitialized) return;
    _isMobileAdsInitialized = true;
    try {
      await MobileAds.instance.initialize();
      debugPrint('[AdsService] MobileAds initialized successfully');
      loadRewardedAd();
      if (interstitialsEnabled) {
        loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('[AdsService] MobileAds.initialize exception: $e');
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
    debugPrint('[AdsService] Loading RewardedAd (id: ${C.rewardedAdUnitId})...');
    try {
      RewardedAd.load(
        adUnitId: C.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            debugPrint('[AdsService] RewardedAd LOADED successfully!');
            _rewardedAd = ad;
            _isRewardedLoading = false;
            isRewardedLoadedNotifier.value = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('[AdsService] RewardedAd FAILED to load: ${error.message} (code ${error.code})');
            _rewardedAd = null;
            _isRewardedLoading = false;
            isRewardedLoadedNotifier.value = false;
            // Retry loading after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (_rewardedAd == null && !_isRewardedLoading && C.adsEnabled) {
                loadRewardedAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdsService] loadRewardedAd exception: $e');
      _isRewardedLoading = false;
      isRewardedLoadedNotifier.value = false;
    }
  }

  /// Shows the preloaded rewarded ad.
  /// Calls [onUserEarnedReward] strictly once upon SDK reward confirmation.
  /// Offline or failure never throws and never blocks callers.
  Future<bool> showRewardedAd({required VoidCallback onUserEarnedReward}) async {
    debugPrint('[AdsService] showRewardedAd requested. isRewardedLoaded = $isRewardedLoaded');
    if (testShowHandler != null) {
      isRewardedLoadedNotifier.value = false;
      return testShowHandler!(onUserEarnedReward: onUserEarnedReward);
    }

    final ad = _rewardedAd;
    if (ad == null || !isRewardedLoaded) {
      debugPrint('[AdsService] showRewardedAd: No ad ready to display');
      return false;
    }

    // Immediately mark as not loaded to prevent double triggers
    isRewardedLoadedNotifier.value = false;
    _rewardedAd = null;

    bool rewardGranted = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('[AdsService] RewardedAd dismissed');
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('[AdsService] RewardedAd failed to show: ${error.message}');
        ad.dispose();
        loadRewardedAd();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('[AdsService] onUserEarnedReward callback received! Reward: ${reward.amount} ${reward.type}');
          if (!rewardGranted) {
            rewardGranted = true;
            onUserEarnedReward();
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AdsService] showRewardedAd exception: $e');
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
    debugPrint('[AdsService] Run completed recorded. Runs since last interstitial: $_completedRunsSinceLastInterstitial / ${C.interstitialMinRuns}');
    if (C.adsEnabled && !isRewardedLoaded && !_isRewardedLoading) {
      loadRewardedAd();
    }
    if (C.adsEnabled && interstitialsEnabled && !isInterstitialLoaded && !_isInterstitialLoading) {
      loadInterstitialAd();
    }
  }

  /// Whether strict limits for showing an interstitial ad are met:
  /// - Interstitials enabled switch is true
  /// - At least 4 completed runs since the last one (or 2 in active test mode)
  /// - At least 3 minutes (or 60s in test mode) since the last one
  /// - An interstitial ad is loaded and ready
  bool canShowInterstitial({DateTime? now}) {
    if (!C.adsEnabled || !interstitialsEnabled) {
      return false;
    }
    if (!isInterstitialLoaded) {
      return false;
    }
    if (_completedRunsSinceLastInterstitial < C.interstitialMinRuns) {
      return false;
    }

    final currentTime = now ?? (testCurrentTimeProvider?.call() ?? DateTime.now());
    final elapsedSec = currentTime.difference(_lastInterstitialTime).inSeconds;
    if (elapsedSec < C.interstitialMinIntervalSec) {
      return false;
    }

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
    debugPrint('[AdsService] Loading InterstitialAd (id: ${C.interstitialAdUnitId})...');
    try {
      InterstitialAd.load(
        adUnitId: C.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('[AdsService] InterstitialAd LOADED successfully!');
            _interstitialAd = ad;
            _isInterstitialLoading = false;
            isInterstitialLoadedNotifier.value = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('[AdsService] InterstitialAd FAILED to load: ${error.message} (code ${error.code})');
            _interstitialAd = null;
            _isInterstitialLoading = false;
            isInterstitialLoadedNotifier.value = false;
            // Retry loading after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (_interstitialAd == null && !_isInterstitialLoading && C.adsEnabled && interstitialsEnabled) {
                loadInterstitialAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdsService] loadInterstitialAd exception: $e');
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
    final eligible = canShowInterstitial(now: now);
    debugPrint('[AdsService] showInterstitialIfEligible: eligible = $eligible (runs: $_completedRunsSinceLastInterstitial, isLoaded: $isInterstitialLoaded)');
    if (!eligible) {
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
        debugPrint('[AdsService] InterstitialAd dismissed');
        ad.dispose();
        invokeActionOnce();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('[AdsService] InterstitialAd failed to show: ${error.message}');
        ad.dispose();
        invokeActionOnce();
        loadInterstitialAd();
      },
    );

    try {
      debugPrint('[AdsService] Displaying InterstitialAd now...');
      await ad.show();
      return true;
    } catch (e) {
      debugPrint('[AdsService] showInterstitial exception: $e');
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

    _isMobileAdsInitialized = false;
    _interstitialsEnabledOverride = null;
    testCurrentTimeProvider = null;
    testShowHandler = null;
    testInterstitialShowHandler = null;
  }
}
