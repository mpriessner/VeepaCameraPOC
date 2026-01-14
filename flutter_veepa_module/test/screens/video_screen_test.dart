import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/screens/video_screen.dart';
import 'package:veepa_camera_poc/services/veepa_player_service.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';
import 'package:veepa_camera_poc/services/disconnection_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DiscoveredDevice createTestDevice({String name = 'Test Camera'}) {
    return DiscoveredDevice(
      deviceId: 'TEST123',
      name: name,
      ipAddress: '192.168.1.100',
      port: 80,
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );
  }

  setUp(() {
    // Reset all singletons before each test
    VeepaPlayerService().reset();
    VeepaConnectionManager().reset();
    DisconnectionHandler().reset();
  });

  tearDown(() {
    VeepaPlayerService().reset();
    VeepaConnectionManager().reset();
    DisconnectionHandler().reset();
  });

  group('VideoScreen', () {
    testWidgets('shows device name in controls overlay', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice(name: 'My Test Camera');

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Device name shown in top bar
        expect(find.text('My Test Camera'), findsOneWidget);
      });
    });

    testWidgets('shows error state when not connected', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Since not connected, player goes to error state and shows VideoErrorWidget
        // VideoErrorWidget displays an error title (one of the VideoErrorType titles)
        expect(
          find.text('Video Error').evaluate().isNotEmpty ||
              find.text('Network Error').evaluate().isNotEmpty ||
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty,
          true,
        );
      });
    });

    testWidgets('shows controls overlay initially', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Controls should be visible initially (use IconButton finder to avoid
        // conflicting with VideoErrorWidget's OutlinedButton.icon back button)
        expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
        expect(find.widgetWithIcon(IconButton, Icons.bug_report), findsOneWidget);
      });
    });

    testWidgets('controls toggle on tap', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Controls visible initially (use IconButton finder to avoid
        // conflicting with VideoErrorWidget's OutlinedButton.icon)
        expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);

        // Tap to toggle controls off
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        // Controls should be hidden now
        expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsNothing);

        // Tap again to show controls
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        // Controls visible again
        expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
      });
    });

    testWidgets('debug panel shows when debug button tapped', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Debug panel not visible initially
        expect(find.text('Debug Info'), findsNothing);

        // Tap debug button
        await tester.tap(find.byIcon(Icons.bug_report));
        await tester.pump();

        // Debug panel should be visible
        expect(find.text('Debug Info'), findsOneWidget);
        expect(find.text('Player: '), findsOneWidget);
        expect(find.text('Connection: '), findsOneWidget);
        expect(find.text('FPS: '), findsOneWidget);
        expect(find.text('Device ID: '), findsOneWidget);
        expect(find.text('IP: '), findsOneWidget);
      });
    });

    testWidgets('debug panel toggles off', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Tap debug button to show
        await tester.tap(find.byIcon(Icons.bug_report));
        await tester.pump();
        expect(find.text('Debug Info'), findsOneWidget);

        // Tap again to hide
        await tester.tap(find.byIcon(Icons.bug_report));
        await tester.pump();
        expect(find.text('Debug Info'), findsNothing);
      });
    });

    testWidgets('shows connection status indicator', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Connection state shown (Disconnected when not connected)
        expect(find.text('Disconnected'), findsOneWidget);
      });
    });

    testWidgets('has back button', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Use IconButton finder to find controls overlay back button
        // (VideoErrorWidget also has arrow_back in OutlinedButton.icon)
        expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
      });
    });

    testWidgets('has play/pause button', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Play/pause button exists
        expect(find.byIcon(Icons.play_circle), findsOneWidget);
      });
    });

    testWidgets('uses correct aspect ratio', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // AspectRatio widget with 16/9 exists
        final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
        expect(aspectRatio.aspectRatio, 16 / 9);
      });
    });

    testWidgets('has black background', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Scaffold has black background
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.black);
      });
    });

    testWidgets('shows error state with retry button when error', (tester) async {
      await tester.runAsync(() async {
        final device = createTestDevice();

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Since we're not connected, player should show error state
        // with "Try Again" button (from VideoErrorWidget using ElevatedButton.icon)
        expect(find.text('Try Again'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
      });
    });

    testWidgets('handles device without IP', (tester) async {
      await tester.runAsync(() async {
        final device = DiscoveredDevice(
          deviceId: 'TEST',
          name: 'Test Camera',
          ipAddress: null,
          port: 80,
          discoveryMethod: DiscoveryMethod.cloudLookup,
          discoveredAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(home: VideoScreen(device: device)),
        );
        await tester.pump();

        // Should not crash and show device name
        expect(find.text('Test Camera'), findsOneWidget);
      });
    });
  });
}
