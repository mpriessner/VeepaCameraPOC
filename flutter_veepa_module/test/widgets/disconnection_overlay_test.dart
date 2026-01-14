import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/widgets/disconnection_overlay.dart';

void main() {
  group('DisconnectionOverlay', () {
    testWidgets('shows Connection Lost when not reconnecting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: false,
            ),
          ),
        ),
      );

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.byIcon(Icons.signal_wifi_off), findsOneWidget);
    });

    testWidgets('shows Reconnecting... when reconnecting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: true,
              reconnectAttempt: 2,
              maxAttempts: 3,
            ),
          ),
        ),
      );

      expect(find.text('Reconnecting...'), findsOneWidget);
      expect(find.text('Attempt 2 of 3'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('shows error message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              errorMessage: 'Custom error message',
              isReconnecting: false,
            ),
          ),
        ),
      );

      expect(find.text('Custom error message'), findsOneWidget);
    });

    testWidgets('shows default message when no error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: false,
            ),
          ),
        ),
      );

      expect(find.text('The connection to the camera was lost.'), findsOneWidget);
    });

    testWidgets('shows Retry button when not reconnecting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: false,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Camera List'), findsOneWidget);
    });

    testWidgets('hides buttons when reconnecting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
      expect(find.text('Camera List'), findsNothing);
    });

    testWidgets('shows progress indicator when reconnecting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: true,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Retry button calls onRetry callback', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () => retryCalled = true,
              onGoBack: () {},
              isReconnecting: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('Camera List button calls onGoBack callback', (tester) async {
      bool goBackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () => goBackCalled = true,
              isReconnecting: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Camera List'));
      expect(goBackCalled, isTrue);
    });

    testWidgets('shows correct attempt count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: true,
              reconnectAttempt: 1,
              maxAttempts: 5,
            ),
          ),
        ),
      );

      expect(find.text('Attempt 1 of 5'), findsOneWidget);
    });

    testWidgets('uses correct colors for states', (tester) async {
      // Test not reconnecting - red icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: false,
            ),
          ),
        ),
      );

      final Icon iconNotReconnecting = tester.widget(find.byIcon(Icons.signal_wifi_off));
      expect(iconNotReconnecting.color, Colors.red);

      // Test reconnecting - orange icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisconnectionOverlay(
              onRetry: () {},
              onGoBack: () {},
              isReconnecting: true,
            ),
          ),
        ),
      );

      final Icon iconReconnecting = tester.widget(find.byIcon(Icons.sync));
      expect(iconReconnecting.color, Colors.orange);
    });
  });
}
