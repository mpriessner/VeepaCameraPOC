import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/ptz_direction.dart';

void main() {
  group('PTZDirection', () {
    test('has all expected values', () {
      expect(PTZDirection.values, contains(PTZDirection.stop));
      expect(PTZDirection.values, contains(PTZDirection.panLeft));
      expect(PTZDirection.values, contains(PTZDirection.panRight));
      expect(PTZDirection.values, contains(PTZDirection.tiltUp));
      expect(PTZDirection.values, contains(PTZDirection.tiltDown));
      expect(PTZDirection.values, contains(PTZDirection.panLeftTiltUp));
      expect(PTZDirection.values, contains(PTZDirection.panLeftTiltDown));
      expect(PTZDirection.values, contains(PTZDirection.panRightTiltUp));
      expect(PTZDirection.values, contains(PTZDirection.panRightTiltDown));
      expect(PTZDirection.values.length, 9);
    });

    test('all command codes are unique', () {
      final codes = PTZDirection.values.map((d) => d.commandCode).toSet();
      expect(codes.length, PTZDirection.values.length);
    });

    test('stop has command code 0', () {
      expect(PTZDirection.stop.commandCode, 0);
    });

    test('pan left has correct command code', () {
      expect(PTZDirection.panLeft.commandCode, 4);
    });

    test('pan right has correct command code', () {
      expect(PTZDirection.panRight.commandCode, 6);
    });

    test('tilt up has correct command code', () {
      expect(PTZDirection.tiltUp.commandCode, 2);
    });

    test('tilt down has correct command code', () {
      expect(PTZDirection.tiltDown.commandCode, 8);
    });

    group('displayName', () {
      test('all directions have display names', () {
        for (final direction in PTZDirection.values) {
          expect(direction.displayName, isNotEmpty);
        }
      });

      test('stop display name is Stop', () {
        expect(PTZDirection.stop.displayName, 'Stop');
      });
    });

    group('isPan', () {
      test('panLeft is pan', () {
        expect(PTZDirection.panLeft.isPan, isTrue);
      });

      test('panRight is pan', () {
        expect(PTZDirection.panRight.isPan, isTrue);
      });

      test('tiltUp is not pan only', () {
        expect(PTZDirection.tiltUp.isPan, isFalse);
      });

      test('panLeftTiltUp is pan', () {
        expect(PTZDirection.panLeftTiltUp.isPan, isTrue);
      });

      test('stop is not pan', () {
        expect(PTZDirection.stop.isPan, isFalse);
      });
    });

    group('isTilt', () {
      test('tiltUp is tilt', () {
        expect(PTZDirection.tiltUp.isTilt, isTrue);
      });

      test('tiltDown is tilt', () {
        expect(PTZDirection.tiltDown.isTilt, isTrue);
      });

      test('panLeft is not tilt only', () {
        expect(PTZDirection.panLeft.isTilt, isFalse);
      });

      test('panRightTiltDown is tilt', () {
        expect(PTZDirection.panRightTiltDown.isTilt, isTrue);
      });

      test('stop is not tilt', () {
        expect(PTZDirection.stop.isTilt, isFalse);
      });
    });

    test('diagonal directions are both pan and tilt', () {
      expect(PTZDirection.panLeftTiltUp.isPan, isTrue);
      expect(PTZDirection.panLeftTiltUp.isTilt, isTrue);
      expect(PTZDirection.panLeftTiltDown.isPan, isTrue);
      expect(PTZDirection.panLeftTiltDown.isTilt, isTrue);
      expect(PTZDirection.panRightTiltUp.isPan, isTrue);
      expect(PTZDirection.panRightTiltUp.isTilt, isTrue);
      expect(PTZDirection.panRightTiltDown.isPan, isTrue);
      expect(PTZDirection.panRightTiltDown.isTilt, isTrue);
    });
  });

  group('ZoomDirection', () {
    test('has all expected values', () {
      expect(ZoomDirection.values, contains(ZoomDirection.stop));
      expect(ZoomDirection.values, contains(ZoomDirection.zoomIn));
      expect(ZoomDirection.values, contains(ZoomDirection.zoomOut));
      expect(ZoomDirection.values.length, 3);
    });

    test('all command codes are unique', () {
      final codes = ZoomDirection.values.map((d) => d.commandCode).toSet();
      expect(codes.length, ZoomDirection.values.length);
    });

    test('stop has command code 0', () {
      expect(ZoomDirection.stop.commandCode, 0);
    });

    test('zoomIn has correct command code', () {
      expect(ZoomDirection.zoomIn.commandCode, 16);
    });

    test('zoomOut has correct command code', () {
      expect(ZoomDirection.zoomOut.commandCode, 32);
    });

    group('displayName', () {
      test('all zoom directions have display names', () {
        for (final direction in ZoomDirection.values) {
          expect(direction.displayName, isNotEmpty);
        }
      });

      test('zoomIn display name is Zoom In', () {
        expect(ZoomDirection.zoomIn.displayName, 'Zoom In');
      });

      test('zoomOut display name is Zoom Out', () {
        expect(ZoomDirection.zoomOut.displayName, 'Zoom Out');
      });
    });
  });
}
