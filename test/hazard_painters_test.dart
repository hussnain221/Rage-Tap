import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/painting/hazard_painters.dart';

void main() {
  group('HazardPainters', () {
    test('renders Spikes for counts 1, 2, and 3 without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (int count = 1; count <= 3; count++) {
        HazardPainters.paintSpikes(
          canvas,
          origin: Offset(count * 50.0, 0),
          count: count,
        );
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('renders Barrier with diagonal stripes and glow without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      HazardPainters.paintBarrier(
        canvas,
        origin: const Offset(20, 20),
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('renders Charging Block with chevrons and speed lines without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      HazardPainters.paintChargingBlock(
        canvas,
        origin: const Offset(30, 30),
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('renders Telegraph warning icon without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (double t = 0.0; t <= 1.0; t += 0.2) {
        HazardPainters.paintTelegraph(
          canvas,
          origin: const Offset(10, 10),
          t: t,
        );
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('renders Tall Wall with horizontal stripes, antenna, and glow without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (double t = 0.0; t <= 1.0; t += 0.25) {
        HazardPainters.paintTallWall(
          canvas,
          origin: const Offset(20, 20),
          t: t,
        );
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('renders Overhead Beam with drone body, column, tip, and rotors without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (double t = 0.0; t <= 1.0; t += 0.25) {
        HazardPainters.paintOverheadBeam(
          canvas,
          origin: const Offset(20, 20),
          t: t,
        );
      }

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('Obstacle hitboxes and dimensions remain unchanged', () {
      final spike1 = Obstacle.spike(x: 100, count: 1);
      expect(spike1.size.x, C.spikeW);
      expect(spike1.size.y, C.spikeH);
      expect(spike1.relativeHitbox.width, C.spikeW - (C.spikeHitX * 2));
      expect(spike1.relativeHitbox.height, C.spikeHitH);

      final spike3 = Obstacle.spike(x: 100, count: 3);
      expect(spike3.size.x, C.spikeW * 3);
      expect(spike3.size.y, C.spikeH);

      final barrier = Obstacle.barrier(x: 100);
      expect(barrier.size.x, C.barrierW);
      expect(barrier.size.y, C.barrierH);
      expect(barrier.relativeHitbox.width, C.barrierHitW);
      expect(barrier.relativeHitbox.height, C.barrierHitH);

      final tallWall = Obstacle.tallWall(x: 100);
      expect(tallWall.size.x, C.tallW);
      expect(tallWall.size.y, C.tallH);
      expect(tallWall.relativeHitbox.width, C.tallHitW);
      expect(tallWall.relativeHitbox.height, C.tallHitH);

      final charge = Obstacle.charging(x: 100);
      expect(charge.size.x, C.chargeW);
      expect(charge.size.y, C.chargeH);
      expect(charge.relativeHitbox.width, C.chargeHitW);
      expect(charge.relativeHitbox.height, C.chargeHitH);

      final beam = Obstacle.beam(x: 100);
      expect(beam.size.x, C.beamDroneW);
      expect(beam.size.y, C.beamBottomY - C.beamDroneTopY);
      expect(beam.relativeHitbox.width, C.beamHitW);
      expect(beam.relativeHitbox.height, C.beamBottomY - C.beamHitTopY);
      expect(beam.y, C.beamDroneTopY);
    });

    test('Obstacle.render invokes painter without error', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final spike = Obstacle.spike(x: 100, count: 2);
      final barrier = Obstacle.barrier(x: 100);
      final charge = Obstacle.charging(x: 100);
      final tallWall = Obstacle.tallWall(x: 100);
      final beam = Obstacle.beam(x: 100);

      spike.render(canvas);
      barrier.render(canvas);
      charge.render(canvas);
      tallWall.render(canvas);
      beam.render(canvas);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
