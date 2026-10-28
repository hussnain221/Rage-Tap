import 'dart:math' as math;

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../core/constants.dart';
import '../core/palette.dart';
import '../data/save_service.dart';
import 'components/background.dart';
import 'components/ground.dart';
import 'components/obstacle.dart';
import 'components/particles.dart';
import 'components/player.dart';
import 'components/popup_text.dart';
import 'components/telegraph.dart';
import 'game_state.dart';
import 'model/daily_challenge.dart';
import 'systems/difficulty.dart';
import 'systems/near_miss.dart';
import 'systems/scoring.dart';
import 'systems/spawner.dart';

class RageTapGame extends FlameGame {
  RageTapGame({
    SaveService? saveService,
    Spawner? spawner,
    int? seed,
    this.dailyChallenge,
  })  : _saveService = saveService ?? SaveService.instance,
        spawner = spawner ?? Spawner(seed: seed),
        super(
          camera: CameraComponent.withFixedResolution(
            width: C.worldW,
            height: C.worldH,
            viewfinder: Viewfinder()..anchor = Anchor.topLeft,
          ),
        ) {
    bestScore.value = _saveService.bestScore;
    _bestAtStart = bestScore.value;
  }

  final DailyChallenge? dailyChallenge;
  final SaveService _saveService;
  SaveService get saveService => _saveService;
  final Spawner spawner;
  final ValueNotifier<GameState> state = ValueNotifier<GameState>(GameState.ready);
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  final ValueNotifier<bool> isNewBest = ValueNotifier<bool>(false);
  final ValueNotifier<int> resumeCountdown = ValueNotifier<int>(0);
  final ValueNotifier<int> scoreBonusTrigger = ValueNotifier<int>(0);
  final ValueNotifier<bool> showHitboxes = ValueNotifier<bool>(false);
  final ValueNotifier<double> rageMeter = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> isRageActive = ValueNotifier<bool>(false);

  final Player player = Player();
  final ParticleEffects particles = ParticleEffects();
  final List<Obstacle> _activeObstacles = [];
  PopupText? _activePopupText;
  FpsComponent? _fpsComponent;

  double runTime = 0.0;
  double distance = 0.0;
  double currentSpeed = C.baseSpeed;
  int bonusScore = 0;
  int nearMissCount = 0;
  double nearMissCooldown = 0.0;
  final ValueNotifier<String?> hint = ValueNotifier<String?>(null);
  double? _hintTimer;

  DeathCause? lastDeathCause;
  RunResult? lastResult;
  int _bestAtStart = 0;
  bool _runResultRecorded = false;
  bool _hasDied = false;
  double _dyingTimer = 0.0;
  double _resumeStepTimer = 0.0;
  double _rageModeTimer = 0.0;
  double _timeSinceLastNearMiss = 0.0;

  double get currentFps => _fpsComponent?.fps ?? 0.0;
  int get seed => spawner.seed;
  String? get lastPatternId => spawner.lastPatternId;

  @override
  Color backgroundColor() => Palette.bgDeep;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (kDebugMode) {
      _fpsComponent = FpsComponent();
      add(_fpsComponent!);
    }
    await world.add(Background());
    await world.add(Ground());
    if (!player.isMounted) {
      await world.add(player);
    }
    await world.add(particles);
    await world.add(TelegraphComponent());
  }

  void _clearObstacles() {
    _activeObstacles.clear();
    _activePopupText = null;
    hint.value = null;
    _hintTimer = null;
    // Collect removals first to avoid modifying the collection mid-iteration
    final toRemove = <Component>[];
    for (final child in world.children) {
      if (child is Obstacle || child is PopupText) {
        toRemove.add(child);
      }
    }
    for (final child in toRemove) {
      if (child is Obstacle) child.x = -1000;
      child.removeFromParent();
    }
  }

  Obstacle _createObstacle(SpawnItem item) {
    return Obstacle(
      type: item.type,
      initialX: item.x,
      count: item.count,
      pitWidth: item.pitWidth,
    );
  }

  @override
  void update(double dt) {
    final clampedDt = dt.clamp(0.0, C.maxDt).toDouble();

    // Update hint timer
    if (_hintTimer != null) {
      _hintTimer = _hintTimer! - clampedDt;
      if (_hintTimer! <= 0) {
        _hintTimer = null;
        hint.value = null;
      }
    }

    if (state.value == GameState.resuming) {
      _updateResumeCountdown(clampedDt);
    } else if (state.value == GameState.playing) {
      // Rage Meter and Rage Mode updates (§20.1)
      if (C.rageEnabled) {
        if (isRageActive.value) {
          _rageModeTimer -= clampedDt;
          rageMeter.value = math.max(0.0, (_rageModeTimer / C.rageDurationSec) * 100.0);
          if (_rageModeTimer <= 0.0) {
            _endRageMode();
          }
        } else {
          _timeSinceLastNearMiss += clampedDt;
          if (_timeSinceLastNearMiss >= C.rageDrainDelaySec && rageMeter.value > 0.0) {
            final drained = rageMeter.value - (C.rageDrainPerSec * clampedDt);
            rageMeter.value = math.max(0.0, drained);
          }
        }
      }

      runTime += clampedDt;
      final baseSpeed = Difficulty.speed(runTime);
      currentSpeed = (C.rageEnabled && isRageActive.value)
          ? baseSpeed * C.rageSpeedMultiplier
          : baseSpeed;
      final scoreMult = (C.rageEnabled && isRageActive.value) ? C.rageScoreMultiplier : 1;
      distance += currentSpeed * clampedDt * scoreMult;
      final currentScore = Scoring.pointsFromDistance(distance) + bonusScore;
      score.value = currentScore;
      if (currentScore > bestScore.value) {
        bestScore.value = currentScore;
      }

      // Update player physics
      player.step(clampedDt);

      // Collect active obstacles into reusable buffer (no world.children scan per frame)
      // _activeObstacles is maintained: populated on spawn, removed below when off-screen.
      // We still rebuild it once per frame for isRemoving checks.
      _activeObstacles.clear();
      for (final child in world.children) {
        if (child is Obstacle && !child.isRemoving) {
          _activeObstacles.add(child);
        }
      }

      // Fall rule (evaluated every frame while state == playing, AFTER physics step including landing and buffered jump)
      if (player.grounded) {
        final playerCenterX = player.x + C.playerHitX + (C.playerHitW / 2);
        for (int i = 0; i < _activeObstacles.length; i++) {
          final obs = _activeObstacles[i];
          if (obs.type == HazardType.pit && !obs.isRemoving) {
            final holeLeft = obs.x;
            final holeRight = obs.x + obs.width;
            if (playerCenterX > (holeLeft + C.pitCenterInset) &&
                playerCenterX < (holeRight - C.pitCenterInset)) {
              die(DeathCause.pit);
              break;
            }
          }
        }
      }

      if (state.value != GameState.playing) {
        super.update(clampedDt);
        return;
      }

      // Teaching hint (one-time for beam and pit)
      if (!_saveService.beamHintShown || !_saveService.pitHintShown) {
        for (int i = 0; i < _activeObstacles.length; i++) {
          final obs = _activeObstacles[i];
          if (!_saveService.beamHintShown && obs.type == HazardType.beam && obs.x < C.worldW) {
            _triggerBeamHint();
            break;
          } else if (!_saveService.pitHintShown && obs.type == HazardType.pit && obs.x < C.worldW) {
            _triggerPitHint();
            break;
          }
        }
      }

      // Move obstacles with current scroll speed and remove off-screen
      for (int i = 0; i < _activeObstacles.length; i++) {
        final obstacle = _activeObstacles[i];
        obstacle.move(currentSpeed, clampedDt);
        if (obstacle.x + obstacle.width < -20) {
          obstacle.removeFromParent();
        }
      }

      // Spawn upcoming obstacles
      final newItems = spawner.update(clampedDt, currentSpeed, runTime);
      for (int i = 0; i < newItems.length; i++) {
        final obs = _createObstacle(newItems[i]);
        world.add(obs);
        _activeObstacles.add(obs);
      }

      // Check AABB collision between player and obstacles (pits have no AABB collision)
      final playerHitbox = player.hitbox;
      bool collided = false;
      for (int i = 0; i < _activeObstacles.length; i++) {
        final obstacle = _activeObstacles[i];
        if (obstacle.isRemoving || obstacle.type == HazardType.pit) continue;
        if (playerHitbox.overlaps(obstacle.hitbox)) {
          die(DeathCause.values.byName(obstacle.type.name));
          collided = true;
          break;
        }
      }

      // If no collision happened, track clearance and evaluate near-misses (skip beam and pit)
      if (!collided) {
        if (nearMissCooldown > 0) {
          nearMissCooldown -= clampedDt;
        }

        for (int i = 0; i < _activeObstacles.length; i++) {
          final obstacle = _activeObstacles[i];
          if (obstacle.isRemoving ||
              obstacle.type == HazardType.beam ||
              obstacle.type == HazardType.pit) {
            continue;
          }
          obstacle.updateClearance(playerHitbox);

          if (!obstacle.passed && obstacle.hitbox.right < playerHitbox.left) {
            obstacle.passed = true;
            if (NearMiss.isNearMiss(
              minClearance: obstacle.minClearance,
              cooldownRemaining: nearMissCooldown,
            )) {
              _triggerNearMiss();
            }
          }
        }
      }
    } else if (state.value == GameState.dying) {
      _updateDying(clampedDt);
    }

    if (_activePopupText != null && _activePopupText!.isExpired) {
      _activePopupText!.removeFromParent();
      _activePopupText = null;
    }

    super.update(clampedDt);
  }

  void _triggerNearMiss() {
    AudioService.instance.playNearMiss();
    HapticsService.nearMiss();
    bonusScore += C.nearMissBonus;
    nearMissCount++;
    nearMissCooldown = C.nearMissCooldownSec;
    final currentScore = Scoring.pointsFromDistance(distance) + bonusScore;
    score.value = currentScore;
    if (currentScore > bestScore.value) {
      bestScore.value = currentScore;
    }
    scoreBonusTrigger.value++;
    player.triggerScared();
    _activePopupText?.removeFromParent();
    final popup = PopupText(
      initialPosition: Vector2(player.x + C.playerSize / 2, player.y - 12),
    );
    _activePopupText = popup;
    world.add(popup);

    if (C.rageEnabled) {
      _timeSinceLastNearMiss = 0.0;
      if (!isRageActive.value) {
        final nextVal = (rageMeter.value + C.rageNearMissIncrement).clamp(0.0, 100.0);
        rageMeter.value = nextVal;
        if (nextVal >= 100.0) {
          _activateRageMode();
        }
      }
    }
  }

  void _activateRageMode() {
    isRageActive.value = true;
    player.isRageMode = true;
    _rageModeTimer = C.rageDurationSec;
    rageMeter.value = 100.0;
  }

  void _endRageMode() {
    isRageActive.value = false;
    player.isRageMode = false;
    rageMeter.value = 0.0;
    _rageModeTimer = 0.0;
    _timeSinceLastNearMiss = 0.0;
  }

  @visibleForTesting
  void triggerNearMissForTesting() {
    _triggerNearMiss();
  }

  @visibleForTesting
  void activateRageModeForTesting() {
    _activateRageMode();
  }

  void _triggerBeamHint() {
    _saveService.setBeamHintShown(true);
    hint.value = 'STAY LOW!';
    _hintTimer = 1.6;
  }

  void _triggerPitHint() {
    _saveService.setPitHintShown(true);
    hint.value = 'JUMP THE GAP!';
    _hintTimer = 1.6;
  }

  static double get _startTime {
    if (!kDebugMode) return 0.0;
    const fromEnv = String.fromEnvironment('START_TIME');
    return double.tryParse(fromEnv) ?? 0.0;
  }

  void startRun() {
    if (state.value == GameState.ready) {
      _runResultRecorded = false;
      bonusScore = 0;
      nearMissCount = 0;
      nearMissCooldown = 0.0;
      _endRageMode();
      player.resetAnimation();
      if (_saveService.bestScore > bestScore.value) {
        bestScore.value = _saveService.bestScore;
      }
      _bestAtStart = bestScore.value;
      _clearObstacles();
      runTime = _startTime;
      currentSpeed = Difficulty.speed(runTime);
      final initialItems = spawner.startRun(isRetry: false, speed: currentSpeed, runTime: runTime);
      for (final item in initialItems) {
        world.add(_createObstacle(item));
      }
      if (!_saveService.firstRunDone) {
        _saveService.setFirstRunDone(true);
      }
      state.value = GameState.playing;
      player.jump();
    }
  }

  void pause() {
    if (state.value == GameState.playing || state.value == GameState.resuming) {
      resumeCountdown.value = 0;
      _resumeStepTimer = 0.0;
      state.value = GameState.paused;
    }
  }

  void beginResume() {
    if (state.value == GameState.paused) {
      state.value = GameState.resuming;
      resumeCountdown.value = C.resumeCountStart;
      _resumeStepTimer = C.resumeCountStepSec;
    }
  }

  void _updateResumeCountdown(double dt) {
    _resumeStepTimer -= dt;
    if (_resumeStepTimer <= 0) {
      resumeCountdown.value -= 1;
      if (resumeCountdown.value <= 0) {
        resumeCountdown.value = 0;
        state.value = GameState.playing;
      } else {
        _resumeStepTimer += C.resumeCountStepSec;
      }
    }
  }

  void spawnLandingDust(Vector2 position) {
    particles.spawnLandingDust(position);
  }

  void die([DeathCause? cause]) {
    if (_hasDied || state.value != GameState.playing) return;
    _hasDied = true;
    lastDeathCause = cause;
    _dyingTimer = 0.0;
    state.value = GameState.dying;
    player.isDead = true;
    if (isRageActive.value) {
      _endRageMode();
    }

    if (cause == DeathCause.pit) {
      player.isFalling = true;
      AudioService.instance.playFall();
      HapticsService.fall();
      // Skip white flash, particles, screen shake, and hit freeze
    } else {
      AudioService.instance.playHit();
      HapticsService.hit();
      particles.triggerDeathEffect(
        Vector2(player.x + C.playerSize / 2, player.y + C.playerSize / 2),
      );
    }

    if (kDebugMode) {
      debugPrint('Player died. Cause: $cause');
    }
  }

  void _updateDying(double dt) {
    _dyingTimer += dt;
    if (lastDeathCause == DeathCause.pit) {
      player.step(dt);
    }
    final dyingDuration =
        lastDeathCause == DeathCause.pit ? 0.55 : (C.hitFreezeSec + C.deathAnimSec);
    if (_dyingTimer >= dyingDuration) {
      _finalizeRun();
      state.value = GameState.results;
      if (kDebugMode) {
        debugPrint('Run ended. State -> results.');
      }
    }
  }

  void _finalizeRun() {
    if (_runResultRecorded) return;
    _runResultRecorded = true;

    final distanceScore = Scoring.pointsFromDistance(distance);
    final finalScore = distanceScore + bonusScore;
    score.value = finalScore;

    final newBest = Scoring.isNewBest(finalScore, _bestAtStart);
    isNewBest.value = newBest;

    if (newBest) {
      _saveService.setBestIfHigher(finalScore);
      bestScore.value = finalScore;
    } else if (_saveService.bestScore > bestScore.value) {
      bestScore.value = _saveService.bestScore;
    }

    _saveService.incrementTotalRuns();

    final coins = Scoring.coinsEarned(score: finalScore, nearMisses: nearMissCount);
    _saveService.addCoins(coins);

    bool goalMet = false;
    bool rewardClaimed = false;
    if (dailyChallenge != null) {
      goalMet = dailyChallenge!.isGoalMet(
        score: finalScore,
        nearMisses: nearMissCount,
        durationSeconds: runTime,
      );
      if (goalMet && !_saveService.isDailyCompleted(dailyChallenge!.dateKey)) {
        rewardClaimed = true;
        _saveService.claimDailyReward(dailyChallenge!);
      }
    }

    lastResult = RunResult(
      score: finalScore,
      best: bestScore.value,
      isNewBest: newBest,
      deathCause: lastDeathCause,
      nearMisses: nearMissCount,
      durationSeconds: runTime,
      coinsEarned: coins,
      isDailyChallenge: dailyChallenge != null,
      dailyGoalMet: goalMet,
      dailyRewardClaimed: rewardClaimed,
    );
  }

  void retry() {
    if (state.value == GameState.playing) return;
    runTime = _startTime;
    distance = 0.0;
    currentSpeed = Difficulty.speed(runTime);
    bonusScore = 0;
    nearMissCount = 0;
    nearMissCooldown = 0.0;
    score.value = 0;
    isNewBest.value = false;
    resumeCountdown.value = 0;
    _hasDied = false;
    _dyingTimer = 0.0;
    _resumeStepTimer = 0.0;
    _endRageMode();
    _runResultRecorded = false;
    lastResult = null;

    if (_saveService.bestScore > bestScore.value) {
      bestScore.value = _saveService.bestScore;
    }
    _bestAtStart = bestScore.value;

    // Reset player position and physics
    player.y = Player.groundY;
    player.vy = 0.0;
    player.grounded = true;
    player.isFalling = false;
    player.jumpBufferTimer = 0.0;
    player.resetAnimation();
    particles.clear();
    _clearObstacles();
    final initialItems = spawner.startRun(isRetry: true, speed: currentSpeed, runTime: runTime);
    for (final item in initialItems) {
      world.add(_createObstacle(item));
    }

    state.value = GameState.playing;
  }

  void onTapDown() {
    if (state.value == GameState.ready) {
      startRun();
    } else if (state.value == GameState.playing) {
      player.jump();
    }
  }

  void disposeGame() {
    if (score.value > _saveService.bestScore) {
      _saveService.setBestIfHigher(score.value);
    }
    particles.clear();
    state.dispose();
    score.dispose();
    bestScore.dispose();
    isNewBest.dispose();
    resumeCountdown.dispose();
    scoreBonusTrigger.dispose();
    showHitboxes.dispose();
    hint.dispose();
    rageMeter.dispose();
    isRageActive.dispose();
  }
}
