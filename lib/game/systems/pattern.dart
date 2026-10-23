import '../components/obstacle.dart';
import 'hazard_geometry.dart';

class PatternItem {
  final HazardType type;
  final int count;
  final double dxSeconds;
  final double pitWidth;

  const PatternItem({
    required this.type,
    this.count = 1,
    required this.dxSeconds,
    this.pitWidth = 0.0,
  });
}

class Pattern {
  final String id;
  final double minSpeed;
  final double tierStart;
  final int weight;
  final double minLeadSeconds;
  final HazardType? introFor;
  final List<PatternItem> items;

  const Pattern({
    required this.id,
    required this.minSpeed,
    required this.tierStart,
    required this.weight,
    this.minLeadSeconds = 0.0,
    this.introFor,
    required this.items,
  });
}
