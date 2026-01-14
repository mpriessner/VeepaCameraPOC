import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/player_state.dart';

void main() {
  group('PlayerState', () {
    test('has all expected values', () {
      expect(PlayerState.values, contains(PlayerState.stopped));
      expect(PlayerState.values, contains(PlayerState.buffering));
      expect(PlayerState.values, contains(PlayerState.playing));
      expect(PlayerState.values, contains(PlayerState.paused));
      expect(PlayerState.values, contains(PlayerState.error));
      expect(PlayerState.values.length, 5);
    });
  });

  group('PlayerStateExtension', () {
    group('isActive', () {
      test('returns false for stopped', () {
        expect(PlayerState.stopped.isActive, false);
      });

      test('returns true for buffering', () {
        expect(PlayerState.buffering.isActive, true);
      });

      test('returns true for playing', () {
        expect(PlayerState.playing.isActive, true);
      });

      test('returns true for paused', () {
        expect(PlayerState.paused.isActive, true);
      });

      test('returns false for error', () {
        expect(PlayerState.error.isActive, false);
      });
    });

    group('isPlaying', () {
      test('returns true only for playing state', () {
        expect(PlayerState.stopped.isPlaying, false);
        expect(PlayerState.buffering.isPlaying, false);
        expect(PlayerState.playing.isPlaying, true);
        expect(PlayerState.paused.isPlaying, false);
        expect(PlayerState.error.isPlaying, false);
      });
    });

    group('canPlay', () {
      test('returns true for stopped', () {
        expect(PlayerState.stopped.canPlay, true);
      });

      test('returns false for buffering', () {
        expect(PlayerState.buffering.canPlay, false);
      });

      test('returns false for playing', () {
        expect(PlayerState.playing.canPlay, false);
      });

      test('returns false for paused', () {
        expect(PlayerState.paused.canPlay, false);
      });

      test('returns true for error', () {
        expect(PlayerState.error.canPlay, true);
      });
    });

    group('displayName', () {
      test('returns Stopped for stopped', () {
        expect(PlayerState.stopped.displayName, 'Stopped');
      });

      test('returns Buffering... for buffering', () {
        expect(PlayerState.buffering.displayName, 'Buffering...');
      });

      test('returns Playing for playing', () {
        expect(PlayerState.playing.displayName, 'Playing');
      });

      test('returns Paused for paused', () {
        expect(PlayerState.paused.displayName, 'Paused');
      });

      test('returns Error for error', () {
        expect(PlayerState.error.displayName, 'Error');
      });
    });
  });
}
