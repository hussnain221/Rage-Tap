import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/game/components/player.dart';
import 'package:rage_tap/game/painting/zap_painter.dart';

void main() {
  group('ZapPainter', () {
    test('renders all expressions without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (final expression in ZapExpression.values) {
        // Paint at default size and variations
        ZapPainter.paintZap(
          canvas,
          origin: const Offset(10, 10),
          size: 40.0,
          expression: expression,
          t: 0.5,
          scaleX: 1.0,
          scaleY: 1.0,
        );

        // Paint with squash/stretch
        ZapPainter.paintZap(
          canvas,
          origin: Offset.zero,
          size: 96.0,
          expression: expression,
          t: 1.5,
          scaleX: 0.85,
          scaleY: 1.2,
        );
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('idle expression handles blink cycle without throwing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // t in blink interval ([0, 0.15) mod 3.0)
      ZapPainter.paintZap(
        canvas,
        expression: ZapExpression.idle,
        t: 0.05,
      );

      // t outside blink interval
      ZapPainter.paintZap(
        canvas,
        expression: ZapExpression.idle,
        t: 1.5,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('Player expressions and squash/stretch', () {
    test('transitions expressions based on physics state', () {
      final player = Player();

      // Standalone (unmounted): grounded -> run
      expect(player.currentExpression, ZapExpression.run);

      // Airborne -> air
      player.y = -1000.0;
      player.grounded = false;
      player.vy = 0.0;
      expect(player.currentExpression, ZapExpression.air);

      // Scared takes precedence when timer active
      player.triggerScared();
      expect(player.currentExpression, ZapExpression.scared);

      // Scared decays with step() (0.5s > 0.4s scared duration, still airborne)
      player.step(0.5);
      expect(player.currentExpression, ZapExpression.air);

      // Landed -> run
      player.y = Player.groundY;
      player.grounded = true;
      expect(player.currentExpression, ZapExpression.run);

      // Override expression
      player.overrideExpression = ZapExpression.idle;
      expect(player.currentExpression, ZapExpression.idle);
      player.overrideExpression = null;
      expect(player.currentExpression, ZapExpression.run);
    });

    test('squash/stretch scales appropriately on takeoff and landing', () {
      final player = Player();
      expect(player.scaleX, 1.0);
      expect(player.scaleY, 1.0);

      player.triggerTakeoff();
      // Right at takeoff: progress = 1.0 -> scaleX ~ 0.85, scaleY ~ 1.20
      expect(player.scaleX, closeTo(0.85, 0.01));
      expect(player.scaleY, closeTo(1.20, 0.01));

      player.step(0.04);
      // Halfway: scale relaxes toward 1.0
      expect(player.scaleX, closeTo(0.925, 0.02));
      expect(player.scaleY, closeTo(1.10, 0.02));

      player.step(0.05);
      // Finished
      expect(player.scaleX, 1.0);
      expect(player.scaleY, 1.0);

      player.triggerLanding();
      // Right at landing: progress = 1.0 -> scaleX ~ 1.20, scaleY ~ 0.80
      expect(player.scaleX, closeTo(1.20, 0.01));
      expect(player.scaleY, closeTo(0.80, 0.01));

      player.resetAnimation();
      expect(player.scaleX, 1.0);
      expect(player.scaleY, 1.0);
    });
  });
}
