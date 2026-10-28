import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveService tests', () {
    test('Default values when keys are missing', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.bestScore, 0);
      expect(saveService.totalCoins, 0);
      expect(saveService.soundEnabled, isTrue);
      expect(saveService.hapticsEnabled, isTrue);
      expect(saveService.firstRunDone, isFalse);
      expect(saveService.totalRuns, 0);
      expect(saveService.schemaVersion, 2);
    });

    test('Clamping invalid, negative, or overflow values', () async {
      SharedPreferences.setMockInitialValues({
        'best_score': -50,
        'total_runs': -10,
      });
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.bestScore, 0);
      expect(saveService.totalRuns, 0);

      // Best score overflow
      SharedPreferences.setMockInitialValues({
        'best_score': 999999999,
      });
      await saveService.init();
      expect(saveService.bestScore, C.maxScore);
    });

    test('setBestIfHigher updates only when higher and clamps', () async {
      SharedPreferences.setMockInitialValues({'best_score': 100});
      final saveService = SaveService.instance;
      await saveService.init();

      // Lower score -> not updated
      final updatedLower = await saveService.setBestIfHigher(80);
      expect(updatedLower, isFalse);
      expect(saveService.bestScore, 100);

      // Equal score -> not updated
      final updatedEqual = await saveService.setBestIfHigher(100);
      expect(updatedEqual, isFalse);
      expect(saveService.bestScore, 100);

      // Higher score -> updated
      final updatedHigher = await saveService.setBestIfHigher(150);
      expect(updatedHigher, isTrue);
      expect(saveService.bestScore, 150);

      // Overflow clamped
      await saveService.setBestIfHigher(20000000);
      expect(saveService.bestScore, C.maxScore);
    });

    test('Toggles and setters persist values', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService.instance;
      await saveService.init();

      await saveService.setSoundEnabled(false);
      expect(saveService.soundEnabled, isFalse);

      await saveService.setHapticsEnabled(false);
      expect(saveService.hapticsEnabled, isFalse);

      await saveService.setFirstRunDone(true);
      expect(saveService.firstRunDone, isTrue);

      await saveService.incrementTotalRuns();
      expect(saveService.totalRuns, 1);
      await saveService.incrementTotalRuns();
      expect(saveService.totalRuns, 2);
    });

    test('resetProgress resets only best_score and total_runs', () async {
      SharedPreferences.setMockInitialValues({
        'best_score': 500,
        'total_runs': 42,
        'total_coins': 75,
        'sound_enabled': false,
        'haptics_enabled': false,
        'first_run_done': true,
        'beam_hint_shown': true,
        'pit_hint_shown': true,
      });
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.bestScore, 500);
      expect(saveService.totalRuns, 42);
      expect(saveService.totalCoins, 75);
      expect(saveService.beamHintShown, isTrue);
      expect(saveService.pitHintShown, isTrue);

      await saveService.resetProgress();

      expect(saveService.bestScore, 0);
      expect(saveService.totalRuns, 0);
      expect(saveService.totalCoins, 0);
      // Preserved settings and hints
      expect(saveService.soundEnabled, isFalse);
      expect(saveService.hapticsEnabled, isFalse);
      expect(saveService.firstRunDone, isTrue);
      expect(saveService.beamHintShown, isTrue);
      expect(saveService.pitHintShown, isTrue);
    });

    test('Safe migration from schema v1 to v2 adds total_coins', () async {
      SharedPreferences.setMockInitialValues({
        'schema_version': 1,
        'best_score': 350,
        'total_runs': 12,
      });
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.schemaVersion, 2);
      expect(saveService.totalCoins, 0);
      expect(saveService.bestScore, 350);
      expect(saveService.totalRuns, 12);
    });

    test('addCoins updates totalCoins and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.totalCoins, 0);
      int notifiedCoins = 0;
      saveService.totalCoinsNotifier.addListener(() {
        notifiedCoins = saveService.totalCoinsNotifier.value;
      });

      await saveService.addCoins(15);
      expect(saveService.totalCoins, 15);
      expect(notifiedCoins, 15);

      await saveService.addCoins(10);
      expect(saveService.totalCoins, 25);
      expect(notifiedCoins, 25);

      // Non-positive amounts have no effect
      await saveService.addCoins(0);
      expect(saveService.totalCoins, 25);
      await saveService.addCoins(-5);
      expect(saveService.totalCoins, 25);
    });

    test('beamHintShown and pitHintShown default to false and persist when set', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.beamHintShown, isFalse);
      await saveService.setBeamHintShown(true);
      expect(saveService.beamHintShown, isTrue);

      expect(saveService.pitHintShown, isFalse);
      await saveService.setPitHintShown(true);
      expect(saveService.pitHintShown, isTrue);
    });
  });
}
