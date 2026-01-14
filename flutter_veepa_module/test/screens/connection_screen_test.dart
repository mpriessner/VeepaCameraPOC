import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/screens/connection_screen.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionScreen UI', () {
    late DiscoveredDevice testDevice;

    setUp(() {
      testDevice = DiscoveredDevice(
        deviceId: 'TEST123',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 8080,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );
      VeepaConnectionManager().reset();
      VeepaSDKManager().reset();
    });

    tearDown(() {
      VeepaConnectionManager().reset();
      VeepaSDKManager().reset();
    });

    testWidgets('shows app bar with Connecting title', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.text('Connecting'), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows device name', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.text('Test Camera'), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows device IP with port', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.text('192.168.1.100:8080'), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows camera icon', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.byIcon(Icons.videocam), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows close button in app bar', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.byIcon(Icons.close), findsWidgets);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows cancel button while connecting', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.text('Cancel'), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows CircularProgressIndicator while connecting', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('shows connection status text', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: testDevice)),
        );
        await tester.pump();

        // Should show either Connecting... or Reconnecting... depending on timing
        final connectingFinder = find.text('Connecting...');
        final reconnectingFinder = find.text('Reconnecting...');
        expect(
          connectingFinder.evaluate().isNotEmpty ||
              reconnectingFinder.evaluate().isNotEmpty,
          isTrue,
        );

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('handles device without IP gracefully', (tester) async {
      final deviceNoIP = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'No IP Camera',
        ipAddress: null,
        port: 80,
        discoveryMethod: DiscoveryMethod.manual,
        discoveredAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: deviceNoIP)),
        );
        await tester.pump();

        expect(find.text('No IP Camera'), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });

    testWidgets('cancel button navigates back', (tester) async {
      bool popped = false;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConnectionScreen(device: testDevice),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Cancel'));
        VeepaConnectionManager().reset();
        await tester.pump();
        await tester.pump();
      });

      expect(popped, isTrue);
    });

    testWidgets('default port 80 shows IP only', (tester) async {
      final deviceDefaultPort = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 80,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ConnectionScreen(device: deviceDefaultPort)),
        );
        await tester.pump();

        expect(find.text('192.168.1.100'), findsOneWidget);

        VeepaConnectionManager().reset();
      });
    });
  });

  group('ConnectionState UI helpers', () {
    test('displayName returns correct strings', () {
      expect(ConnectionState.disconnected.displayName, 'Disconnected');
      expect(ConnectionState.connecting.displayName, 'Connecting...');
      expect(ConnectionState.connected.displayName, 'Connected');
      expect(ConnectionState.reconnecting.displayName, 'Reconnecting...');
      expect(ConnectionState.error.displayName, 'Connection Failed');
    });
  });
}
