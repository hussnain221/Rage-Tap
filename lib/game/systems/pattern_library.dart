import '../../core/constants.dart';
import '../components/obstacle.dart';
import 'pattern.dart';

class PatternLibrary {
  // Tier 1 (t >= 0s)
  static const Pattern s1 = Pattern(
    id: 'S1',
    minSpeed: 190,
    tierStart: C.tier0Start,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 0),
    ],
  );

  // Tier 2 (t >= 5s)
  static const Pattern s2 = Pattern(
    id: 'S2',
    minSpeed: 190,
    tierStart: C.tier1Start,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 0),
    ],
  );

  static const Pattern b1 = Pattern(
    id: 'B1',
    minSpeed: 190,
    tierStart: C.tier1Start,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
    ],
  );

  // Tier 3 (t >= 10s)
  static const Pattern s1b1 = Pattern(
    id: 'S1B1',
    minSpeed: 190,
    tierStart: C.tier2Start,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 1.25),
    ],
  );

  static const Pattern b1s1 = Pattern(
    id: 'B1S1',
    minSpeed: 190,
    tierStart: C.tier2Start,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 1.25),
    ],
  );

  static const Pattern s2s1 = Pattern(
    id: 'S2S1',
    minSpeed: 190,
    tierStart: C.tier2Start,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 0),
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 1.30),
    ],
  );

  // Tier 4 (t >= 16s)
  static const Pattern b1b1 = Pattern(
    id: 'B1B1',
    minSpeed: 190,
    tierStart: C.tier3Start,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 1.30),
    ],
  );

  static const Pattern s3 = Pattern(
    id: 'S3',
    minSpeed: 255,
    tierStart: C.tier3Start,
    weight: 2,
    items: [
      PatternItem(type: ObstacleType.spike, count: 3, dxSeconds: 0),
    ],
  );

  static const Pattern c1 = Pattern(
    id: 'C1',
    minSpeed: 190,
    tierStart: C.tier3Start,
    weight: 2,
    minLeadSeconds: 1.8,
    items: [
      PatternItem(type: ObstacleType.charging, count: 1, dxSeconds: 0),
    ],
  );

  // Tier 5 (t >= 22s)
  static const Pattern s1b1s1 = Pattern(
    id: 'S1B1S1',
    minSpeed: 190,
    tierStart: C.tier4Start,
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
    tierStart: C.tier4Start,
    weight: 1,
    items: [
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 1.30),
      PatternItem(type: ObstacleType.barrier, count: 1, dxSeconds: 2.60),
    ],
  );

  // Tier 6 (t >= 28s) - Tall Wall (minSpeed 210)
  static const Pattern w1 = Pattern(
    id: 'W1',
    minSpeed: 210,
    tierStart: C.tier5Start,
    weight: 3,
    introFor: HazardType.tallWall,
    items: [
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 0),
    ],
  );

  static const Pattern w1s1 = Pattern(
    id: 'W1S1',
    minSpeed: 210,
    tierStart: C.tier5Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.15),
    ],
  );

  static const Pattern b1w1 = Pattern(
    id: 'B1W1',
    minSpeed: 210,
    tierStart: C.tier5Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 1.15),
    ],
  );

  static const Pattern s2w1 = Pattern(
    id: 'S2W1',
    minSpeed: 210,
    tierStart: C.tier5Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.spike, count: 2, dxSeconds: 0),
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 1.20),
    ],
  );

  static const Pattern w1w1 = Pattern(
    id: 'W1W1',
    minSpeed: 210,
    tierStart: C.tier5Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 1.20),
    ],
  );

  // Rhythm Packs (tier 6, minSpeed 285)
  static const Pattern r3 = Pattern(
    id: 'R3',
    minSpeed: 285,
    tierStart: C.tier5Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.10),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 2.20),
    ],
  );

  static const Pattern r3s = Pattern(
    id: 'R3S',
    minSpeed: 285,
    tierStart: C.tier5Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.10),
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 2.75),
    ],
  );

  static const Pattern r4 = Pattern(
    id: 'R4',
    minSpeed: 285,
    tierStart: C.tier5Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.10),
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 2.20),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 3.30),
    ],
  );

  // Tier 8 (t >= 45s) - Rhythm Pack (minSpeed 285)
  static const Pattern r5 = Pattern(
    id: 'R5',
    minSpeed: 285,
    tierStart: C.tier7Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.10),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 2.20),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 3.30),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 4.40),
    ],
  );

  // Tier 7 (t >= 36s) - Overhead Beam (minSpeed 190)
  static const Pattern d1 = Pattern(
    id: 'D1',
    minSpeed: 190,
    tierStart: C.tier6Start,
    weight: 3,
    introFor: HazardType.beam,
    items: [
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 0),
    ],
  );

  static const Pattern d2 = Pattern(
    id: 'D2',
    minSpeed: 190,
    tierStart: C.tier6Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 1.20),
    ],
  );

  static const Pattern d3 = Pattern(
    id: 'D3',
    minSpeed: 190,
    tierStart: C.tier6Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.00),
    ],
  );

  static const Pattern d4 = Pattern(
    id: 'D4',
    minSpeed: 190,
    tierStart: C.tier6Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 1.25),
    ],
  );

  static const Pattern d5 = Pattern(
    id: 'D5',
    minSpeed: 190,
    tierStart: C.tier6Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 1.10),
    ],
  );

  static const Pattern d6 = Pattern(
    id: 'D6',
    minSpeed: 190,
    tierStart: C.tier6Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 1.20),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 2.30),
    ],
  );

  static const Pattern d7 = Pattern(
    id: 'D7',
    minSpeed: 210,
    tierStart: C.tier6Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.beam, count: 1, dxSeconds: 1.30),
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 2.40),
    ],
  );

  // Tier 8 (t >= 45s) - Pit (gap in the ground)
  static const Pattern pit1 = Pattern(
    id: 'PIT1',
    minSpeed: 190,
    tierStart: C.tier7Start,
    weight: 3,
    introFor: HazardType.pit,
    items: [
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitShortW),
    ],
  );

  static const Pattern pit2 = Pattern(
    id: 'PIT2',
    minSpeed: 200,
    tierStart: C.tier7Start,
    weight: 3,
    items: [
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitMediumW),
    ],
  );

  static const Pattern pit3 = Pattern(
    id: 'PIT3',
    minSpeed: 255,
    tierStart: C.tier7Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitLongW),
    ],
  );

  static const Pattern ps1 = Pattern(
    id: 'PS1',
    minSpeed: 190,
    tierStart: C.tier7Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 1.30, pitWidth: C.pitShortW),
    ],
  );

  static const Pattern sp1 = Pattern(
    id: 'SP1',
    minSpeed: 190,
    tierStart: C.tier7Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitShortW),
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 1.40),
    ],
  );

  static const Pattern pm1 = Pattern(
    id: 'PM1',
    minSpeed: 200,
    tierStart: C.tier7Start,
    weight: 2,
    items: [
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 1.35, pitWidth: C.pitMediumW),
    ],
  );

  static const Pattern mb1 = Pattern(
    id: 'MB1',
    minSpeed: 200,
    tierStart: C.tier7Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitMediumW),
      PatternItem(type: HazardType.barrier, count: 1, dxSeconds: 1.55),
    ],
  );

  static const Pattern pp = Pattern(
    id: 'PP',
    minSpeed: 190,
    tierStart: C.tier7Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitShortW),
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 1.35, pitWidth: C.pitShortW),
    ],
  );

  static const Pattern g1 = Pattern(
    id: 'G1',
    minSpeed: 210,
    tierStart: C.tier7Start,
    weight: 1,
    items: [
      PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
      PatternItem(type: HazardType.pit, count: 1, dxSeconds: 1.30, pitWidth: C.pitShortW),
      PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 2.80),
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
    w1,
    w1s1,
    b1w1,
    s2w1,
    w1w1,
    r3,
    r3s,
    r4,
    r5,
    d1,
    d2,
    d3,
    d4,
    d5,
    d6,
    d7,
    pit1,
    pit2,
    pit3,
    ps1,
    sp1,
    pm1,
    mb1,
    pp,
    g1,
  ];
}
