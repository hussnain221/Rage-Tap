import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/palette.dart';
import '../data/save_service.dart';
import 'components/ground.dart';
import 'components/obstacle.dart';
import 'components/player.dart';
import 'components/popup_text.dart';
import 'components/telegraph.dart';
import 'game_state.dart';
import 'systems/difficulty.dart';
import 'systems/near_miss.dart';
import 'systems/scoring.dart';
import 'systems/spawner.dart';

class RageTapGame extends FlameGame {
  RageTapGame({
    SaveService? saveService,
    Spawner? spawner,
    int? seed,
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

  final SaveService _saveService;
  final Spawner spawner;
  final ValueNotifier<GameState> state = ValueNotifier<GameState>(GameState.ready);
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  final ValueNotifier<bool> isNewBest = ValueNotifier<bool>(false);
  final ValueNotifier<int> resumeCountdown = ValueNotifier<int>(0);
  final ValueNotifier<int> scoreBonusTrigger = ValueNotifier<int>(0);

  final Player player = Player();
  FpsComponent? _fpsComponent;

  double runTime = 0.0;
  double distance = 0.0;
  double currentSpeed = C.baseSpeed;
  int bonusScore = 0;
  int nearMissCount = 0;
  double nearMissCooldown = 0.0;

  ObstacleType? lastDeathCause;
  RunResult? lastResult;
  int _bestAtStart = 0;
  bool _runResultRecorded = false;
  bool _hasDied = false;
  double _dyingTimer = 0.0;
  double _resumeStepTimer = 0.0;

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
    await world.add(Ground());
    if (!player.isMounted) {
      await world.add(player);
    }
    await world.add(TelegraphComponent());
  }

  void _clearObstacles() {
    for (final obs in world.children.whereType<Obstacle>().toList()) {
      obs.removeFromParent();
    }
    for (final popup in world.children.whereType<PopupText>().toList()) {
      popup.removeFromParent();
    }
  }

  Obstacle _createObstacle(SpawnItem item) {
    switch (item.type) {
      case ObstacleType.spike:
        return Obstacle.spike(x: item.x, count: item.count);
      case ObstacleType.barrier:
        return Obstacle.barrier(x: item.x);
      case ObstacleType.charging:
        return Obstacle.charging(x: item.x);
    }
  }

  @override
  void update(double dt) {
    final clampedDt = dt.clamp(0.0, C.maxDt).toDouble();

    if (state.value == GameState.resuming) {
      _updateResumeCountdown(clampedDt);
    } else if (state.value == GameState.playing) {
      runTime += clampedDt;
      currentSpeed = Difficulty.speed(runTime);
      distance += currentSpeed * clampedDt;
      score.value = Scoring.pointsFromDistance(distance) + bonusScore;

      // Update player physics
      player.step(clampedDt);

      // Move obstacles with current scroll speed and remove off-screen
      for (final obstacle in world.children.whereType<Obstacle>().toList()) {
        obstacle.move(currentSpeed, clampedDt);
        if (obstacle.x + obstacle.width < -20) {
          obstacle.removeFromParent();
        }
      }

      // Spawn upcoming obstacles
      final newItems = spawner.update(clampedDt, currentSpeed, runTime);
      for (final item in newItems) {
        world.add(_createObstacle(item));
      }

      // Check AABB collision between player and obstacles
      final playerHitbox = player.hitbox;
      bool collided = false;
      for (final obstacle in world.children.whereType<Obstacle>()) {
        if (playerHitbox.overlaps(obstacle.hitbox)) {
          die(obstacle.type);
          collided = true;
          break;
        }
      }

      // If no collision happened, track clearance and evaluate near-misses
      if (!collided) {
        if (nearMissCooldown > 0) {
          nearMissCooldown -= clampedDt;
        }

        for (final obstacle in world.children.whereType<Obstacle>().toList()) {
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

      super.update(clampedDt);
    } else if (state.value == GameState.dying) {
      _updateDying(clampedDt);
      super.update(clampedDt);
    }
  }

  void _triggerNearMiss() {
    bonusScore += C.nearMissBonus;
    nearMissCount++;
    nearMissCooldown = C.nearMissCooldownSec;
    score.value = Scoring.pointsFromDistance(distance) + bonusScore;
    scoreBonusTrigger.value++;
    world.add(PopupText(
      initialPosition: Vector2(player.x + C.playerSize / 2, player.y - 12),
    ));
  }

  void startRun() {
    if (state.value == GameState.ready) {
      _runResultRecorded = false;
      bonusScore = 0;
      nearMissCount = 0;
      nearMissCooldown = 0.0;
      if (_saveService.bestScore > bestScore.value) {
        bestScore.value = _saveService.bestScore;
      }
      _bestAtStart = bestScore.value;
      _clearObstacles();
      final initialItems = spawner.startRun(isRetry: false, speed: currentSpeed);
      for (final item in initialItems) {
        world.add(_createObstacle(item));
      }
      state.value = GameState.playing;
      player.jump();
    }
  }

  void pause() {
    if (state.value == GameState.playing) {
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

  void die([ObstacleType? cause]) {
    if (_hasDied || state.value != GameState.playing) return;
    _hasDied = true;
    lastDeathCause = cause;
    _dyingTimer = 0.0;
    state.value = GameState.dying;
    if (kDebugMode) {
      debugPrint('Player died. Cause: $cause');
    }
  }

  void _updateDying(double dt) {
    _dyingTimer += dt;
    if (_dyingTimer >= C.hitFreezeSec + C.deathAnimSec) {
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

    lastResult = RunResult(
      score: finalScore,
      best: bestScore.value,
      isNewBest: newBest,
      deathCause: lastDeathCause,
      nearMisses: nearMissCount,
      durationSeconds: runTime,
    );
  }

  void retry() {
    runTime = 0.0;
    distance = 0.0;
    currentSpeed = C.baseSpeed;
    bonusScore = 0;
    nearMissCount = 0;
    nearMissCooldown = 0.0;
    score.value = 0;
    isNewBest.value = false;
    resumeCountdown.value = 0;
    _hasDied = false;
    _dyingTimer = 0.0;
    _resumeStepTimer = 0.0;
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
    player.jumpBufferTimer = 0.0;
    _clearObstacles();
    final initialItems = spawner.startRun(isRetry: true, speed: currentSpeed);
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
    state.dispose();
    score.dispose();
    bestScore.dispose();
    isNewBest.dispose();
    resumeCountdown.dispose();
    scoreBonusTrigger.dispose();
  }
}
