import 'package:flame/extensions.dart';

import '../../core/constants.dart';

enum HazardType {
  spike,
  barrier,
  tallWall,
  charging,
  beam,
  pit,
}

enum HazardAnchor {
  ground,
  top,
  hole,
}

enum HazardKind {
  solid,
  overhead,
  hole,
}

enum DeathCause {
  spike,
  barrier,
  tallWall,
  charging,
  beam,
  pit,
}

class HazardGeometry {
  final Vector2 visualSize;
  final Rect relativeHitbox;
  final HazardAnchor anchor;
  final double extraSpeed;
  final HazardKind kind;

  const HazardGeometry({
    required this.visualSize,
    required this.relativeHitbox,
    required this.anchor,
    required this.extraSpeed,
    required this.kind,
  });
}

/// Pure function returning geometry specification for any hazard type.
HazardGeometry geometryFor(
  HazardType type, {
  int count = 1,
  double pitWidth = 0,
}) {
  switch (type) {
    case HazardType.spike:
      final visualW = C.spikeW * count;
      final hitboxW = 24.0 * count + 6.0 * (count - 1);
      return HazardGeometry(
        visualSize: Vector2(visualW, C.spikeH),
        relativeHitbox: Rect.fromLTWH(
          C.spikeHitX,
          C.spikeHitY,
          hitboxW,
          C.spikeHitH,
        ),
        anchor: HazardAnchor.ground,
        extraSpeed: 0.0,
        kind: HazardKind.solid,
      );

    case HazardType.barrier:
      return HazardGeometry(
        visualSize: Vector2(C.barrierW, C.barrierH),
        relativeHitbox: const Rect.fromLTWH(
          C.barrierHitX,
          C.barrierHitY,
          C.barrierHitW,
          C.barrierHitH,
        ),
        anchor: HazardAnchor.ground,
        extraSpeed: 0.0,
        kind: HazardKind.solid,
      );

    case HazardType.tallWall:
      return HazardGeometry(
        visualSize: Vector2(C.tallW, C.tallH),
        relativeHitbox: const Rect.fromLTWH(
          C.tallHitX,
          C.tallHitY,
          C.tallHitW,
          C.tallHitH,
        ),
        anchor: HazardAnchor.ground,
        extraSpeed: 0.0,
        kind: HazardKind.solid,
      );

    case HazardType.charging:
      return HazardGeometry(
        visualSize: Vector2(C.chargeW, C.chargeH),
        relativeHitbox: const Rect.fromLTWH(
          C.chargeHitX,
          C.chargeHitY,
          C.chargeHitW,
          C.chargeHitH,
        ),
        anchor: HazardAnchor.ground,
        extraSpeed: C.chargingExtraSpeed,
        kind: HazardKind.solid,
      );

    case HazardType.beam:
      final totalH = C.beamBottomY - C.beamDroneTopY; // 354
      final hitH = C.beamBottomY - C.beamHitTopY; // 324
      return HazardGeometry(
        visualSize: Vector2(C.beamDroneW, totalH),
        relativeHitbox: Rect.fromLTWH(16, C.beamDroneH, C.beamHitW, hitH),
        anchor: HazardAnchor.top,
        extraSpeed: 0.0,
        kind: HazardKind.overhead,
      );

    case HazardType.pit:
      final w = pitWidth > 0 ? pitWidth : C.pitShortW;
      return HazardGeometry(
        visualSize: Vector2(w, C.worldH - C.groundTopY),
        relativeHitbox: Rect.zero,
        anchor: HazardAnchor.hole,
        extraSpeed: 0.0,
        kind: HazardKind.hole,
      );
  }
}
