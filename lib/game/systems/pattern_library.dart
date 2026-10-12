import '../components/obstacle.dart';
import 'pattern.dart';

class PatternLibrary {
  static const Pattern s1 = Pattern(
    id: 'S1',
    minSpeed: 190,
    tierStart: 0,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.spike, count: 1, dxSeconds: 0),
    ],
  );

  static const Pattern s2 = Pattern(
    id: 'S2',
    minSpeed: 190,
    tierStart: 8,
    weight: 3,
    items: [
      PatternItem(type: ObstacleType.spike, count: 2, dxSeconds: 0),
    ],
  );

  static const List<Pattern> patterns = [
    s1,
    s2,
  ];
}
