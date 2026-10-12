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
      expect(saveService.soundEnabled, isTrue);
      expect(saveService.hapticsEnabled, isTrue);
      expect(saveService.firstRunDone, isFalse);
      expect(saveService.totalRuns, 0);
      expect(saveService.schemaVersion, 1);
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
        'sound_enabled': false,
        'haptics_enabled': false,
        'first_run_done': true,
      });
      final saveService = SaveService.instance;
      await saveService.init();

      expect(saveService.bestScore, 500);
      expect(saveService.totalRuns, 42);

      await saveService.resetProgress();

      expect(saveService.bestScore, 0);
      expect(saveService.totalRuns, 0);
      // Preserved settings
      expect(saveService.soundEnabled, isFalse);
      expect(saveService.hapticsEnabled, isFalse);
      expect(saveService.firstRunDone, isTrue);
    });
  });
}
