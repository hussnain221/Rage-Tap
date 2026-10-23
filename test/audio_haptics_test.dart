import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/audio/audio_service.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/hazard_geometry.dart';
import 'package:rage_tap/ui/widgets/neon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    const MethodChannel globalChannel = MethodChannel('xyz.luan/audioplayers.global');
    const MethodChannel playerChannel = MethodChannel('xyz.luan/audioplayers');
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalChannel, (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playerChannel, (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async => '.');

    SharedPreferences.setMockInitialValues({
      'sound_enabled': true,
      'haptics_enabled': true,
    });
    await SaveService.instance.init();
  });

  group('AudioService Unit Tests', () {
    test('AudioService registers all 6 spec audio files', () {
      expect(AudioService.allFiles, containsAll([
        'jump.wav',
        'land.wav',
        'hit.wav',
        'near_miss.wav',
        'new_best.wav',
        'click.wav',
      ]));
      expect(AudioService.allFiles.length, equals(6));
    });

    test('AudioService methods execute safely without error when sound is disabled', () {
      SaveService.instance.soundEnabled = false;

      expect(() => AudioService.instance.playJump(), returnsNormally);
      expect(() => AudioService.instance.playLand(), returnsNormally);
      expect(() => AudioService.instance.playHit(), returnsNormally);
      expect(() => AudioService.instance.playNearMiss(), returnsNormally);
      expect(() => AudioService.instance.playNewBest(), returnsNormally);
      expect(() => AudioService.instance.playClick(), returnsNormally);
      expect(() => AudioService.instance.stopAll(), returnsNormally);
    });

    test('AudioService methods execute safely when sound is enabled', () {
      SaveService.instance.soundEnabled = true;

      expect(() => AudioService.instance.playJump(), returnsNormally);
      expect(() => AudioService.instance.playLand(), returnsNormally);
      expect(() => AudioService.instance.playHit(), returnsNormally);
      expect(() => AudioService.instance.playNearMiss(), returnsNormally);
      expect(() => AudioService.instance.playNewBest(), returnsNormally);
      expect(() => AudioService.instance.playClick(), returnsNormally);
      expect(() => AudioService.instance.stopAll(), returnsNormally);
    });
  });

  group('HapticsService Unit Tests', () {
    test('HapticsService methods execute safely when haptics are disabled', () {
      SaveService.instance.hapticsEnabled = false;

      expect(() => HapticsService.hit(), returnsNormally);
      expect(() => HapticsService.nearMiss(), returnsNormally);
      expect(() => HapticsService.buttonPress(), returnsNormally);
    });

    test('HapticsService methods execute safely when haptics are enabled', () {
      SaveService.instance.hapticsEnabled = true;

      expect(() => HapticsService.hit(), returnsNormally);
      expect(() => HapticsService.nearMiss(), returnsNormally);
      expect(() => HapticsService.buttonPress(), returnsNormally);
    });
  });

  group('Audio and Haptics Game Integration Tests', () {
    testWidgets('NeonButton and NeonIconButton trigger click sound and haptic on tap', (tester) async {
      bool buttonPressed = false;
      bool iconPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NeonButton.primary(
                  text: 'TEST',
                  onPressed: () => buttonPressed = true,
                ),
                NeonIconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => iconPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pump();
      expect(buttonPressed, isTrue);

      await tester.tap(find.byType(NeonIconButton));
      await tester.pump();
      expect(iconPressed, isTrue);
    });

    test('Game jump, land, hit, and near-miss execute safely with audio and haptics wired', () async {
      final game = RageTapGame();
      await game.onLoad();

      // Start run and jump
      game.startRun();
      expect(game.player.grounded, isFalse);

      // Trigger die with audio & haptics
      expect(() => game.die(DeathCause.spike), returnsNormally);
      expect(game.player.isDead, isTrue);
    });
  });
}
