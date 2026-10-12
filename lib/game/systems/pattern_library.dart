import '../components/obstacle.dart';
import 'pattern.dart';

class PatternLibrary {
  // Tier 1 (t >= 0s)
  static const Pattern s1 = Pattern(
    id: 'S1',
    minSpeed: 190,
    tierStart: 0,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 0),
    ],
  );

  // Tier 2 (t >= 8s)
  static const Pattern s2 = Pattern(
    id: 'S2',
    minSpeed: 190,
    tierStart: 8,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 0),
    ],
  );

  static const Pattern b1 = Pattern(
    id: 'B1',
    minSpeed: 190,
    tierStart: 8,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
    ],
  );

  // Tier 3 (t >= 16s)
  static const Pattern s1b1 = Pattern(
    id: 'S1B1',
    minSpeed: 190,
    tierStart: 16,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 1.25),
    ],
  );

  static const Pattern b1s1 = Pattern(
    id: 'B1S1',
    minSpeed: 190,
    tierStart: 16,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 1.25),
    ],
  );

  static const Pattern s2s1 = Pattern(
    id: 'S2S1',
    minSpeed: 190,
    tierStart: 16,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 0),
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 1.30),
    ],
  );

  // Tier 4 (t >= 24s)
  static const Pattern b1b1 = Pattern(
    id: 'B1B1',
    minSpeed: 190,
    tierStart: 24,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 1.30),
    ],
  );

  static const Pattern s3 = Pattern(
    id: 'S3',
    minSpeed: 255,
    tierStart: 24,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.spike, count: 3, dxSeconds: 0),
    ],
  );

  static const Pattern c1 = Pattern(
    id: 'C1',
    minSpeed: 190,
    tierStart: 24,
    weight: 2,
    minLeadSeconds: 1.8,
    items: [
      PatternItem(type: ObstacleType.charging, count: 1, dxSeconds: 0),
    ],
  );

  // Tier 5 (t >= 36s)
  static const Pattern s1b1s1 = Pattern(
    id: 'S1B1S1',
    minSpeed: 190,
    tierStart: 36,
    weight: 1,
    items: [
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 1.25),
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 2.50),
    ],
  );

  static const Pattern b1s2b1 = Pattern(
    id: 'B1S2B1',
    minSpeed: 190,
    tierStart: 36,
    weight: 1,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 1.30),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 2.60),
    ],
  );

  static const List<Pattern> patterns = [
    s1,
    s2,
    b1,
    s1b1,
    b1s1,
    s2s1,
    b1b1,
    s3,
    c1,
    s1b1s1,
    b1s2b1,
  ];
}
