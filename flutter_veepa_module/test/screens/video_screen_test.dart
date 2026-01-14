import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/screens/video_screen.dart';

void main() {
  group('VideoScreen', () {
    testWidgets('shows device name in app bar', (tester) async {
      final device = DiscoveredDevice(
        deviceId: 'TEST123',
        name: 'My Test Camera',
        ipAddress: '192.168.1.100',
        port: 80,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: VideoScreen(device: device)),
      );

      // App bar shows device name
      expect(find.text('My Test Camera'), findsOneWidget);
      // Body shows "Connected to: {name}"
      expect(find.text('Connected to: My Test Camera'), findsOneWidget);
    });

    testWidgets('shows placeholder text', (tester) async {
      final device = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 80,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: VideoScreen(device: device)),
      );

      expect(find.text('Video Screen'), findsOneWidget);
      expect(find.text('Coming in Epic 4'), findsOneWidget);
    });

    testWidgets('shows camera icon', (tester) async {
      final device = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 80,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: VideoScreen(device: device)),
      );

      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('shows connected status', (tester) async {
      final device = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 80,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: VideoScreen(device: device)),
      );

      expect(find.text('Connected to: Test Camera'), findsOneWidget);
    });

    testWidgets('shows IP address when available', (tester) async {
      final device = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 80,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: VideoScreen(device: device)),
      );

      expect(find.text('192.168.1.100'), findsOneWidget);
    });

    testWidgets('shows IP with port when non-default', (tester) async {
      final device = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        port: 8080,
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(home: VideoScreen(device: device)),
      );

      expect(find.text('192.168.1.100:8080'), findsOneWidget);
    });

    testWidgets('handles device without IP', (tester) async {
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

      // Should not crash and show device name in app bar and connected status
      expect(find.text('Test Camera'), findsOneWidget);
      expect(find.text('Connected to: Test Camera'), findsOneWidget);
    });
  });
}
