import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/background.dart';
import 'package:rage_tap/game/components/ground.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Background and Ground components', () {
    test('Background has priority -10 and Ground has priority 0', () {
      final bg = Background();
      final ground = Ground();
      expect(bg.priority, -10);
      expect(ground.priority, 0);
      expect(bg.size.x, C.worldW);
      expect(bg.size.y, C.worldH);
      expect(ground.size.x, C.worldW);
      expect(ground.size.y, C.worldH - C.groundTopY);
    });

    test('Background and Ground update and render smoothly', () async {
      final game = RageTapGame();
      await game.onLoad();

      final bg = game.world.children.whereType<Background>().first;
      final ground = game.world.children.whereType<Ground>().first;
      expect(bg, isNotNull);
      expect(ground, isNotNull);

      // Verify rendering in ready state
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      bg.render(canvas);
      ground.render(canvas);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);

      // Update in ready state (drift at 20 units/s)
      game.update(0.1);

      // Switch to playing state and update
      game.state.value = GameState.playing;
      game.update(0.1);

      // Verify rendering in playing state
      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);
      bg.render(canvas2);
      ground.render(canvas2);
      final picture2 = recorder2.endRecording();
      expect(picture2, isNotNull);

      // Update across full 720-unit tile loop without NaN or crash
      for (int i = 0; i < 100; i++) {
        game.update(0.1);
      }

      game.disposeGame();
    });
  });
}
