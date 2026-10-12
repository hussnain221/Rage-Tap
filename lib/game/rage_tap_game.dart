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
import 'game_state.dart';
import 'systems/difficulty.dart';
import 'systems/scoring.dart';

class RageTapGame extends FlameGame {
  RageTapGame({SaveService? saveService})
      : _saveService = saveService ?? SaveService.instance,
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
  final ValueNotifier<GameState> state = ValueNotifier<GameState>(GameState.ready);
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  final ValueNotifier<bool> isNewBest = ValueNotifier<bool>(false);
  final ValueNotifier<int> resumeCountdown = ValueNotifier<int>(0);

  final Player player = Player();
  FpsComponent? _fpsComponent;

  double runTime = 0.0;
  double distance = 0.0;
  double currentSpeed = C.baseSpeed;

  ObstacleType? lastDeathCause;
  RunResult? lastResult;
  int _bestAtStart = 0;
  bool _runResultRecorded = false;
  bool _hasDied = false;
  double _dyingTimer = 0.0;
  double _resumeStepTimer = 0.0;

  double get currentFps => _fpsComponent?.fps ?? 0.0;

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
      score.value = Scoring.pointsFromDistance(distance);

      // Update player physics
      player.step(clampedDt);

      // Move obstacles with current scroll speed
      for (final obstacle in world.children.whereType<Obstacle>().toList()) {
        obstacle.move(currentSpeed, clampedDt);
      }


      // Check AABB collision between player and obstacles
      final playerHitbox = player.hitbox;
      for (final obstacle in world.children.whereType<Obstacle>()) {
        if (playerHitbox.overlaps(obstacle.hitbox)) {
          die(obstacle.type);
          break;
        }
      }

      super.update(clampedDt);
    } else if (state.value == GameState.dying) {
      _updateDying(clampedDt);
      super.update(clampedDt);
    }
  }

  void startRun() {
    if (state.value == GameState.ready) {
      _runResultRecorded = false;
      if (_saveService.bestScore > bestScore.value) {
        bestScore.value = _saveService.bestScore;
      }
      _bestAtStart = bestScore.value;
      _spawnInitialTestHazard(isRetry: false);
      state.value = GameState.playing;
      player.jump();
    }
  }

  void _spawnInitialTestHazard({required bool isRetry}) {
    // Clear any existing obstacles
    for (final obs in world.children.whereType<Obstacle>().toList()) {
      obs.removeFromParent();
    }
    // Safe opening: C.safeOpeningRetry on retry (2.0s), C.safeOpeningFirstRun on first run (3.0s)
    final leadSec = isRetry ? C.safeOpeningRetry : C.safeOpeningFirstRun;
    final spawnX = C.playerLeft + leadSec * C.baseSpeed;
    world.add(Obstacle.spike(x: spawnX, count: 1));
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
    final finalScore = score.value > distanceScore ? score.value : distanceScore;
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
      nearMisses: 0,
      durationSeconds: runTime,
    );
  }

  void retry() {
    runTime = 0.0;
    distance = 0.0;
    currentSpeed = C.baseSpeed;
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

    _spawnInitialTestHazard(isRetry: true);

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
  }
}
