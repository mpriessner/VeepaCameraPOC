import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/video_error_type.dart';
import 'package:veepa_camera_poc/widgets/video_error_widget.dart';

void main() {
  group('VideoErrorWidget', () {
    testWidgets('shows network error info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.networkError,
              technicalError: 'Socket closed',
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Network Error'), findsOneWidget);
      expect(find.textContaining('WiFi'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('shows buffering timeout error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.bufferingTimeout,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Video Loading Timeout'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('shows decode error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.decodeError,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Video Format Error'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('shows stream ended error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.streamEnded,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Stream Ended'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    });

    testWidgets('shows player error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.playerError,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Player Error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows unknown error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.unknown,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Video Error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button triggers callback', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.bufferingTimeout,
              onRetry: () => retryCalled = true,
              onGoBack: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      expect(retryCalled, isTrue);
    });

    testWidgets('go back button triggers callback', (tester) async {
      bool goBackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.networkError,
              onRetry: () {},
              onGoBack: () => goBackCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go Back'));
      expect(goBackCalled, isTrue);
    });

    testWidgets('shows recovery hint for recoverable errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.bufferingTimeout,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('This error may resolve automatically'), findsOneWidget);
    });

    testWidgets('does not show recovery hint for non-recoverable errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.decodeError,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('This error may resolve automatically'), findsNothing);
    });

    testWidgets('shows technical details in debug mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.playerError,
              technicalError: 'SDK_ERROR_CODE_42',
              showTechnicalDetails: true,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('SDK_ERROR_CODE_42'), findsOneWidget);
    });

    testWidgets('hides technical details by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.playerError,
              technicalError: 'SDK_ERROR_CODE_42',
              showTechnicalDetails: false,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('SDK_ERROR_CODE_42'), findsNothing);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoErrorWidget(
              errorType: VideoErrorType.unknown,
              onRetry: () {},
              onGoBack: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.color, Colors.black);
    });
  });
}
