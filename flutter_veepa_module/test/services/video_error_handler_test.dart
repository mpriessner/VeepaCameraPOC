import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/video_error_type.dart';
import 'package:veepa_camera_poc/services/video_error_handler.dart';

void main() {
  group('VideoErrorHandler', () {
    group('classifyError', () {
      test('classifies timeout errors', () {
        expect(
          VideoErrorHandler.classifyError('Buffering timeout'),
          VideoErrorType.bufferingTimeout,
        );
        expect(
          VideoErrorHandler.classifyError('timeout exceeded'),
          VideoErrorType.bufferingTimeout,
        );
      });

      test('classifies network errors', () {
        expect(
          VideoErrorHandler.classifyError('Socket connection failed'),
          VideoErrorType.networkError,
        );
        expect(
          VideoErrorHandler.classifyError('Network unreachable'),
          VideoErrorType.networkError,
        );
        expect(
          VideoErrorHandler.classifyError('Connection refused'),
          VideoErrorType.networkError,
        );
      });

      test('classifies decode errors', () {
        expect(
          VideoErrorHandler.classifyError('Codec decode error'),
          VideoErrorType.decodeError,
        );
        expect(
          VideoErrorHandler.classifyError('Failed to decode frame'),
          VideoErrorType.decodeError,
        );
      });

      test('classifies stream ended errors', () {
        expect(
          VideoErrorHandler.classifyError('Stream ended unexpectedly'),
          VideoErrorType.streamEnded,
        );
        expect(
          VideoErrorHandler.classifyError('EOF reached'),
          VideoErrorType.streamEnded,
        );
      });

      test('classifies player errors', () {
        expect(
          VideoErrorHandler.classifyError('Player initialization failed'),
          VideoErrorType.playerError,
        );
        expect(
          VideoErrorHandler.classifyError('SDK error occurred'),
          VideoErrorType.playerError,
        );
      });

      test('returns unknown for unclassified errors', () {
        expect(
          VideoErrorHandler.classifyError('Random error message'),
          VideoErrorType.unknown,
        );
        expect(
          VideoErrorHandler.classifyError('Something went wrong'),
          VideoErrorType.unknown,
        );
      });

      test('handles case insensitivity', () {
        expect(
          VideoErrorHandler.classifyError('TIMEOUT ERROR'),
          VideoErrorType.bufferingTimeout,
        );
        expect(
          VideoErrorHandler.classifyError('NETWORK FAILED'),
          VideoErrorType.networkError,
        );
      });

      test('handles null-like values', () {
        expect(
          VideoErrorHandler.classifyError(null),
          VideoErrorType.unknown,
        );
        expect(
          VideoErrorHandler.classifyError(''),
          VideoErrorType.unknown,
        );
      });
    });

    group('getRetryDelay', () {
      test('returns 2 seconds for buffering timeout', () {
        expect(
          VideoErrorHandler.getRetryDelay(VideoErrorType.bufferingTimeout),
          const Duration(seconds: 2),
        );
      });

      test('returns 5 seconds for network error', () {
        expect(
          VideoErrorHandler.getRetryDelay(VideoErrorType.networkError),
          const Duration(seconds: 5),
        );
      });

      test('returns 3 seconds for other errors', () {
        expect(
          VideoErrorHandler.getRetryDelay(VideoErrorType.decodeError),
          const Duration(seconds: 3),
        );
        expect(
          VideoErrorHandler.getRetryDelay(VideoErrorType.streamEnded),
          const Duration(seconds: 3),
        );
        expect(
          VideoErrorHandler.getRetryDelay(VideoErrorType.playerError),
          const Duration(seconds: 3),
        );
        expect(
          VideoErrorHandler.getRetryDelay(VideoErrorType.unknown),
          const Duration(seconds: 3),
        );
      });
    });

    group('logError', () {
      test('does not throw', () {
        expect(
          () => VideoErrorHandler.logError(
            VideoErrorType.networkError,
            'Test error',
          ),
          returnsNormally,
        );
      });

      test('handles stack trace', () {
        expect(
          () => VideoErrorHandler.logError(
            VideoErrorType.playerError,
            'Test error',
            StackTrace.current,
          ),
          returnsNormally,
        );
      });
    });
  });
}
