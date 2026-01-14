import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/video_error_type.dart';

void main() {
  group('VideoErrorType', () {
    test('has all expected values', () {
      expect(VideoErrorType.values, contains(VideoErrorType.bufferingTimeout));
      expect(VideoErrorType.values, contains(VideoErrorType.decodeError));
      expect(VideoErrorType.values, contains(VideoErrorType.streamEnded));
      expect(VideoErrorType.values, contains(VideoErrorType.networkError));
      expect(VideoErrorType.values, contains(VideoErrorType.playerError));
      expect(VideoErrorType.values, contains(VideoErrorType.unknown));
      expect(VideoErrorType.values.length, 6);
    });
  });

  group('VideoErrorTypeExtension', () {
    group('userMessage', () {
      test('all error types have user messages', () {
        for (final type in VideoErrorType.values) {
          expect(type.userMessage, isNotEmpty);
        }
      });

      test('user messages are non-technical', () {
        for (final type in VideoErrorType.values) {
          final message = type.userMessage.toLowerCase();

          // Should not contain technical terms
          expect(message, isNot(contains('exception')));
          expect(message, isNot(contains('stack')));
          expect(message, isNot(contains('null')));
          expect(message, isNot(contains('error code')));

          // Should be helpful (meaningful length)
          expect(type.userMessage.length, greaterThan(20));
        }
      });

      test('bufferingTimeout message mentions connection', () {
        expect(
          VideoErrorType.bufferingTimeout.userMessage.toLowerCase(),
          contains('connection'),
        );
      });

      test('networkError message mentions WiFi', () {
        expect(
          VideoErrorType.networkError.userMessage.toLowerCase(),
          contains('wifi'),
        );
      });

      test('decodeError message mentions format', () {
        expect(
          VideoErrorType.decodeError.userMessage.toLowerCase(),
          contains('format'),
        );
      });

      test('streamEnded message mentions camera', () {
        expect(
          VideoErrorType.streamEnded.userMessage.toLowerCase(),
          contains('camera'),
        );
      });

      test('playerError message mentions restart', () {
        expect(
          VideoErrorType.playerError.userMessage.toLowerCase(),
          contains('restart'),
        );
      });
    });

    group('title', () {
      test('all error types have titles', () {
        for (final type in VideoErrorType.values) {
          expect(type.title, isNotEmpty);
        }
      });

      test('titles are concise', () {
        for (final type in VideoErrorType.values) {
          // Titles should be short
          expect(type.title.length, lessThan(30));
        }
      });
    });

    group('isRecoverable', () {
      test('bufferingTimeout is recoverable', () {
        expect(VideoErrorType.bufferingTimeout.isRecoverable, true);
      });

      test('networkError is recoverable', () {
        expect(VideoErrorType.networkError.isRecoverable, true);
      });

      test('decodeError is not recoverable', () {
        expect(VideoErrorType.decodeError.isRecoverable, false);
      });

      test('streamEnded is not recoverable', () {
        expect(VideoErrorType.streamEnded.isRecoverable, false);
      });

      test('playerError is not recoverable', () {
        expect(VideoErrorType.playerError.isRecoverable, false);
      });

      test('unknown is not recoverable', () {
        expect(VideoErrorType.unknown.isRecoverable, false);
      });
    });
  });
}
