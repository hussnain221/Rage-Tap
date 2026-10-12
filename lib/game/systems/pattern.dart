import '../components/obstacle.dart';

class PatternItem {
  final ObstacleType type;
  final int count;
  final double dxSeconds;

  const PatternItem({
    required this.type,
    this.count = 1,
    required this.dxSeconds,
  });
}

class Pattern {
  final String id;
  final double minSpeed;
  final double tierStart;
  final int weight;
  final double minLeadSeconds;
  final List<PatternItem> items;

  const Pattern({
    required this.id,
    required this.minSpeed,
    required this.tierStart,
    required this.weight,
    this.minLeadSeconds = 0.0,
    required this.items,
  });
}
