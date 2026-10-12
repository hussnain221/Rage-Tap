import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../components/obstacle.dart';
import 'difficulty.dart';
import 'pattern.dart';
import 'pattern_library.dart';

class SpawnItem {
  final ObstacleType type;
  final int count;
  final double x;

  const SpawnItem({
    required this.type,
    this.count = 1,
    required this.x,
  });

  @override
  String toString() => 'SpawnItem(type: $type, count: $count, x: $x)';
}

class Spawner {
  Spawner({
    int? seed,
    List<Pattern>? library,
    this.enableLogging = true,
  })  : seed = seed ?? resolveSeed(),
        _random = math.Random(seed ?? resolveSeed()),
        library = library ?? PatternLibrary.patterns {
    if (kDebugMode && enableLogging) {
      debugPrint('Spawner initialized with seed: ${this.seed}');
    }
  }

  final bool enableLogging;

  static int resolveSeed([int? overrideSeed]) {
    if (overrideSeed != null) return overrideSeed;
    final definedSeed = int.tryParse(const String.fromEnvironment('SEED'));
    if (definedSeed != null) return definedSeed;
    return DateTime.now().millisecondsSinceEpoch;
  }

  final int seed;
  final math.Random _random;
  final List<Pattern> library;

  String? lastPatternId;
  int _consecutiveCount = 0;
  double _lastHazardTrailingX = 0.0;
  ObstacleType? _lastHazardType;
  Pattern? _pendingPattern;
  double _pendingLeadSec = 0.0;

  static double computeItemWidth(ObstacleType type, int count) {
    switch (type) {
      case ObstacleType.spike:
        return C.spikeW * count;
      case ObstacleType.barrier:
        return C.barrierW;
      case ObstacleType.charging:
        return C.chargeW;
    }
  }

  static double restMin(double t) => Difficulty.restGapRange(t).min;
  static double restMax(double t) => Difficulty.restGapRange(t).max;

  List<SpawnItem> startRun({required bool isRetry, required double speed}) {
    reset();
    final leadSec = isRetry ? C.safeOpeningRetry : C.safeOpeningFirstRun;
    final firstX = math.max(C.worldW + 40, C.playerLeft + leadSec * speed);

    final pattern = pickPattern(runTime: 0.0, speed: speed);
    final items = _generatePatternItems(pattern, firstX, speed);
    _prepareNextPattern(runTime: 0.0, speed: speed);
    return items;
  }

  void _prepareNextPattern({required double runTime, required double speed}) {
    _pendingPattern = pickPattern(runTime: runTime, speed: speed);
    final range = Difficulty.restGapRange(runTime);
    final restGapSec = range.min + _random.nextDouble() * (range.max - range.min);
    _pendingLeadSec = math.max(restGapSec, _pendingPattern!.minLeadSeconds);
  }

  List<SpawnItem> update(double dt, double currentSpeed, double runTime) {
    final lastSpeed = _lastHazardType == ObstacleType.charging
        ? currentSpeed + C.chargingExtraSpeed
        : currentSpeed;
    _lastHazardTrailingX -= lastSpeed * dt;
    final spawned = <SpawnItem>[];

    if (_pendingPattern == null) {
      _prepareNextPattern(runTime: runTime, speed: currentSpeed);
    }

    while (true) {
      final p = _pendingPattern!;
      final minGapPx = _pendingLeadSec * currentSpeed;

      if (p.id == 'C1') {
        final chargingSpeed = currentSpeed + C.chargingExtraSpeed;
        final telegraphX = C.worldW + C.chargingTelegraphSec * chargingSpeed;
        if (_lastHazardTrailingX + minGapPx <= telegraphX) {
          final items = _generatePatternItems(p, telegraphX, currentSpeed);
          spawned.addAll(items);
          _prepareNextPattern(runTime: runTime, speed: currentSpeed);
        } else {
          break;
        }
      } else {
        final targetX = _lastHazardTrailingX + minGapPx;
        if (targetX <= C.worldW + 200) {
          final startX = math.max(C.worldW + 40, targetX);
          final items = _generatePatternItems(p, startX, currentSpeed);
          spawned.addAll(items);
          _prepareNextPattern(runTime: runTime, speed: currentSpeed);
        } else {
          break;
        }
      }
    }

    return spawned;
  }

  Pattern pickPattern({required double runTime, required double speed}) {
    // Filter available patterns by tier start and min speed
    var available = library.where((p) => runTime >= p.tierStart && speed >= p.minSpeed).toList();
    if (available.isEmpty) {
      available = [library.first];
    }

    // C1 may never directly follow another C1
    if (lastPatternId == 'C1') {
      final withoutC1 = available.where((p) => p.id != 'C1').toList();
      if (withoutC1.isNotEmpty) {
        available = withoutC1;
      }
    }

    // Avoid same pattern more than twice in a row if alternatives exist
    if (_consecutiveCount >= 2 && lastPatternId != null) {
      final filtered = available.where((p) => p.id != lastPatternId).toList();
      if (filtered.isNotEmpty) {
        available = filtered;
      }
    }

    // Weighted random selection
    final totalWeight = available.fold<int>(0, (sum, p) => sum + p.weight);
    var roll = _random.nextInt(totalWeight);
    Pattern chosen = available.first;
    for (final p in available) {
      if (roll < p.weight) {
        chosen = p;
        break;
      }
      roll -= p.weight;
    }

    if (chosen.id == lastPatternId) {
      _consecutiveCount++;
    } else {
      lastPatternId = chosen.id;
      _consecutiveCount = 1;
    }

    if (kDebugMode && enableLogging) {
      debugPrint('Spawner: selected pattern ${chosen.id} (runTime: ${runTime.toStringAsFixed(1)}s, seed: $seed)');
    }

    return chosen;
  }

  List<SpawnItem> _generatePatternItems(Pattern pattern, double startX, double speed) {
    final items = <SpawnItem>[];
    double maxTrailing = startX;

    for (final item in pattern.items) {
      final itemX = startX + item.dxSeconds * speed;
      final width = computeItemWidth(item.type, item.count);
      final itemTrailing = itemX + width;
      if (itemTrailing > maxTrailing) {
        maxTrailing = itemTrailing;
      }
      items.add(SpawnItem(
        type: item.type,
        count: item.count,
        x: itemX,
      ));
    }

    _lastHazardTrailingX = maxTrailing;
    _lastHazardType = pattern.items.last.type;
    return items;
  }

  void reset() {
    lastPatternId = null;
    _consecutiveCount = 0;
    _lastHazardTrailingX = 0.0;
    _lastHazardType = null;
    _pendingPattern = null;
    _pendingLeadSec = 0.0;
  }
}
