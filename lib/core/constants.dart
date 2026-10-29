// All values in world units (360x640 logical world) and seconds.
class C {
  // World
  static const double worldW = 360;
  static const double worldH = 640;
  static const double groundTopY = 500;

  // Player
  static const double playerLeft = 64;
  static const double playerSize = 40;
  static const double playerHitX = 6, playerHitY = 6, playerHitW = 28, playerHitH = 34;

  // Physics
  static const double gravity = 2000;
  static const double jumpVelocity = 640;
  static const double jumpBufferSec = 0.10;
  static const double maxDt = 1 / 30;

  // Speed
  static const double baseSpeed = 190;
  static const double maxSpeed = 300;
  static const double speedRampPerSec = 3.0;
  static const double chargingExtraSpeed = 60;

  // Opening
  static const double safeOpeningFirstRun = 3.0;
  static const double safeOpeningRetry = 2.0;

  // Scoring
  static const double distancePerPoint = 40;
  static const double nearMissClearance = 14;
  static const int nearMissBonus = 5;
  static const double nearMissCooldownSec = 0.4;

  // Hazards (visual w,h) and hitbox (x,y,w,h)
  static const double spikeW = 30, spikeH = 28;
  static const double spikeHitX = 3, spikeHitY = 6, spikeHitW = 24, spikeHitH = 22;
  static const double barrierW = 30, barrierH = 56;
  static const double barrierHitX = 3, barrierHitY = 3, barrierHitW = 24, barrierHitH = 53;
  static const double chargeW = 34, chargeH = 34;
  static const double chargeHitX = 4, chargeHitY = 4, chargeHitW = 26, chargeHitH = 30;

  // Spawning
  static const double separateJumpReactionSec = 0.25; // + air time = 0.89 s
  static const double minTimingWindowSec = 0.12;
  static const double chargingTelegraphSec = 0.7;
  static const double chargingMinLeadSec = 1.8;
  static const double restMinStart = 1.30, restMaxStart = 1.90;
  static const double restMinEnd = 0.95, restMaxEnd = 1.25;
  static const double restRampSeconds = 45;
  static const double tier0Start = 0;
  static const double tier1Start = 5;
  static const double tier2Start = 10;
  static const double tier3Start = 16;
  static const double tier4Start = 22;
  static const double tier5Start = 28;
  static const double tier6Start = 36;
  static const double tier7Start = 45;
  static const List<double> tierStarts = [
    tier0Start,
    tier1Start,
    tier2Start,
    tier3Start,
    tier4Start,
    tier5Start,
    tier6Start,
    tier7Start,
  ];

  // ---- New hazards (addendum) ----
  // Tall wall
  static const double tallW = 30, tallH = 68;
  static const double tallHitX = 3, tallHitY = 3, tallHitW = 24, tallHitH = 65;

  // Overhead beam (top-anchored; world y coordinates)
  static const double beamDroneTopY = 96;
  static const double beamDroneW = 44, beamDroneH = 30;
  static const double beamHitTopY = 126; // beamDroneTopY + beamDroneH
  static const double beamBottomY = 450; // groundTopY - 50 (emitter tip)
  static const double beamHitW = 12; // centered under the drone
  static const double beamSafeHeight = 16; // player must be lower than this while overlapping

  // Pits
  static const double pitShortW = 80, pitMediumW = 110, pitLongW = 140;
  static const double pitCenterInset = 6;
  static const double airborneThreshold = 2;

  // Pattern rules
  static const double beamReactionSec = 0.20;
  static const double afterBeamMinDxSec = 0.75;
  static const double newTierWeightBoost = 1.5; // weight multiplier for patterns of the newest unlocked tier

  // FX
  static const double hitFreezeSec = 0.10;
  static const double deathAnimSec = 0.30;
  static const double shakeAmplitude = 6;
  static const double shakeSec = 0.25;
  static const int resumeCountStart = 3;
  static const double resumeCountStepSec = 0.4;

  // Persistence
  static const int maxScore = 9999999;

  // Rage meter (§20.1)
  static const bool rageEnabled = true;
  static const double rageNearMissIncrement = 25.0;
  static const double rageDrainDelaySec = 3.0;
  static const double rageDrainPerSec = 8.0;
  static const double rageDurationSec = 5.0;
  static const double rageSpeedMultiplier = 1.15;
  static const int rageScoreMultiplier = 2;
  static const double rageMeterW = 160.0;
  static const double rageMeterH = 8.0;
  static const double rageOverlayAlpha = 0.15;

  // Ads (§20.6) - Official Google Test IDs only during development
  static const bool adsEnabled = true;
  static const String admobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const bool interstitialsEnabled = false;
  static const int interstitialMinRuns = 4;
  static const int interstitialMinIntervalSec = 180;

  // Metadata & Links
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/stormlogix-privacy-policy/ragetap';
  static const String publisherName = 'StormLogix';
  static const String contactEmail = 'stormlogix1@gmail.com';
  static const String appVersion = 'v1.0.0';
}
