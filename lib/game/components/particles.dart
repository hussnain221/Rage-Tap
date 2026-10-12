import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../game_state.dart';
import '../rage_tap_game.dart';

/// A pooled particle for death bursts and landing dust.
class GameParticle {
  bool active = false;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 4;
  Color color = Palette.cyan;
  double gravity = 900;
  double life = 0;
  double maxLife = 0.5;

  void reset() {
    active = false;
    x = 0;
    y = 0;
    vx = 0;
    vy = 0;
    size = 4;
    color = Palette.cyan;
    gravity = 900;
    life = 0;
    maxLife = 0.5;
  }

  void update(double dt) {
    if (!active) return;
    life += dt;
    if (life >= maxLife) {
      active = false;
      return;
    }
    vy += gravity * dt;
    x += vx * dt;
    y += vy * dt;
  }
}

/// Particle system and visual impact effects (flash, shake, dust, death burst).
class ParticleEffects extends Component with HasGameReference<RageTapGame> {
  ParticleEffects({math.Random? random}) : _random = random ?? math.Random() {
    priority = 20;
  }

  final math.Random _random;

  static const int poolSize = 32;
  final List<GameParticle> _pool = List.generate(
    poolSize,
    (_) => GameParticle(),
    growable: false,
  );

  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _flashPaint = Paint()..style = PaintingStyle.fill;
  static final Rect _flashRect = Rect.fromLTWH(-50, -50, C.worldW + 100, C.worldH + 100);

  // Flash state
  bool _flashActive = false;
  double _flashTimer = 0.15;
  static const double flashDuration = 0.15;

  // Shake state
  bool _shakeActive = false;
  double _shakeTimer = C.shakeSec;

  // Hit freeze & pending death particles
  bool _deathParticlesPending = false;
  double _hitFreezeTimer = 0.0;
  final Vector2 _deathPosition = Vector2.zero();

  int get activeParticleCount => _pool.where((p) => p.active).length;
  bool get isShaking => _shakeActive;
  bool get isFlashing => _flashActive;
  bool get isHitFreezeActive => _deathParticlesPending && _hitFreezeTimer > 0;
  double get currentFlashAlpha {
    if (!_flashActive) return 0.0;
    final progress = (_flashTimer / flashDuration).clamp(0.0, 1.0);
    return (0.35 * (1.0 - progress)).clamp(0.0, 0.35);
  }

  GameParticle? _obtainParticle() {
    for (int i = 0; i < poolSize; i++) {
      if (!_pool[i].active) {
        return _pool[i];
      }
    }
    // If pool exhausted, recycle the oldest particle
    GameParticle oldest = _pool[0];
    for (int i = 1; i < poolSize; i++) {
      if (_pool[i].life > oldest.life) {
        oldest = _pool[i];
      }
    }
    return oldest;
  }

  /// Triggers full death impact sequence:
  /// - Immediate white flash overlay (0.35 -> 0 over 0.15s)
  /// - Immediate decaying screen shake (amplitude 6, 0.25s)
  /// - Hit freeze for C.hitFreezeSec (0.10s)
  /// - Followed by 14 cyan square particles burst fading over 0.5s
  void triggerDeathEffect(Vector2 position) {
    _flashActive = true;
    _flashTimer = 0.0;

    _shakeActive = true;
    _shakeTimer = 0.0;

    _deathPosition.setFrom(position);
    _deathParticlesPending = true;
    _hitFreezeTimer = C.hitFreezeSec;
  }

  /// Immediately spawns 14 cyan square particles without freeze delay.
  void spawnDeathParticles(Vector2 position) {
    for (int i = 0; i < 14; i++) {
      final p = _obtainParticle();
      if (p == null) continue;

      final size = 4.0 + _random.nextDouble() * 3.0; // 4..7 units
      final speed = 80.0 + _random.nextDouble() * 180.0; // 80..260 units/s

      // Upward bias: angle centered around -pi/2 with +/- 70 deg spread
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * (math.pi * 0.78);

      p.active = true;
      p.x = position.x;
      p.y = position.y;
      p.vx = speed * math.cos(angle);
      p.vy = speed * math.sin(angle); // negative = upward
      p.size = size;
      p.color = Palette.cyan;
      p.gravity = 900.0;
      p.life = 0.0;
      p.maxLife = 0.5;
    }
  }

  /// Spawns 3 tiny muted landing dust particles at the feet.
  void spawnLandingDust(Vector2 position) {
    for (int i = 0; i < 3; i++) {
      final p = _obtainParticle();
      if (p == null) continue;

      final size = 2.0 + _random.nextDouble() * 1.5; // ~2..3.5 units
      final vx = (_random.nextDouble() - 0.5) * 80.0; // -40..+40
      final vy = -30.0 - _random.nextDouble() * 40.0; // -30..-70 upward puff

      p.active = true;
      p.x = position.x + (_random.nextDouble() - 0.5) * 12.0;
      p.y = position.y;
      p.vx = vx;
      p.vy = vy;
      p.size = size;
      p.color = Palette.muted;
      p.gravity = 500.0;
      p.life = 0.0;
      p.maxLife = 0.25;
    }
  }

  /// Clears all active particles, flash, shake, and resets camera offset.
  void clear() {
    _flashActive = false;
    _flashTimer = flashDuration;
    _shakeActive = false;
    _shakeTimer = C.shakeSec;
    _deathParticlesPending = false;
    _hitFreezeTimer = 0.0;
    for (int i = 0; i < poolSize; i++) {
      _pool[i].reset();
    }
    if (isMounted) {
      game.camera.viewfinder.position.setZero();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isMounted) {
      final gameState = game.state.value;
      if (gameState == GameState.paused || gameState == GameState.resuming) {
        return;
      }
    }

    // 1. Update flash overlay
    if (_flashActive) {
      _flashTimer += dt;
      if (_flashTimer >= flashDuration) {
        _flashActive = false;
      }
    }

    // 2. Update camera screen shake
    if (_shakeActive) {
      _shakeTimer += dt;
      if (_shakeTimer >= C.shakeSec) {
        _shakeActive = false;
        if (isMounted) {
          game.camera.viewfinder.position.setZero();
        }
      } else {
        final progress = (_shakeTimer / C.shakeSec).clamp(0.0, 1.0);
        final currentAmp = C.shakeAmplitude * (1.0 - progress);
        final ox = math.sin(_shakeTimer * 80.0) * currentAmp;
        final oy = math.cos(_shakeTimer * 95.0) * currentAmp * 0.7;
        if (isMounted) {
          game.camera.viewfinder.position.setValues(ox, oy);
        }
      }
    }

    // 3. Update hit freeze & pending death particles
    if (_deathParticlesPending) {
      _hitFreezeTimer -= dt;
      if (_hitFreezeTimer <= 0) {
        _deathParticlesPending = false;
        spawnDeathParticles(_deathPosition);
      }
    }

    // 4. Update active particles
    for (int i = 0; i < poolSize; i++) {
      if (_pool[i].active) {
        _pool[i].update(dt);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw active particles
    for (int i = 0; i < poolSize; i++) {
      final p = _pool[i];
      if (!p.active) continue;

      final progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawRect(
        Rect.fromLTWH(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size),
        _particlePaint,
      );
    }

    // 2. Draw white flash overlay
    if (_flashActive) {
      final alpha = currentFlashAlpha;
      if (alpha > 0.0) {
        _flashPaint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawRect(_flashRect, _flashPaint);
      }
    }
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }
}

/// Convenience alias matching spec nomenclature.
typedef ParticleSystem = ParticleEffects;
