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
  static const List<double> tierStarts = [0, 8, 16, 24, 36];

  // FX
  static const double hitFreezeSec = 0.10;
  static const double deathAnimSec = 0.30;
  static const double shakeAmplitude = 6;
  static const double shakeSec = 0.25;
  static const int resumeCountStart = 3;
  static const double resumeCountStepSec = 0.4;

  // Persistence
  static const int maxScore = 9999999;
}
