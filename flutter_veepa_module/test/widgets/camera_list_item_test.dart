import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/widgets/camera_list_item.dart';

void main() {
  testWidgets('CameraListItem displays device information',
      (WidgetTester tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST123',
      name: 'Veepa Camera 1',
      ipAddress: '192.168.1.100',
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraListItem(
            device: device,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Veepa Camera 1'), findsOneWidget);
    expect(find.text('IP: 192.168.1.100'), findsOneWidget);
    expect(find.textContaining('TEST123'), findsOneWidget);
    expect(find.text('Found via LAN scan'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });

  testWidgets('CameraListItem shows correct icon for LAN scan',
      (WidgetTester tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST1',
      name: 'Camera',
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraListItem(device: device, onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.wifi), findsOneWidget);
  });

  testWidgets('CameraListItem shows correct icon for manual entry',
      (WidgetTester tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST2',
      name: 'Camera',
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraListItem(device: device, onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.text('Manually entered'), findsOneWidget);
  });

  testWidgets('CameraListItem shows correct icon for cloud lookup',
      (WidgetTester tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST3',
      name: 'Camera',
      discoveryMethod: DiscoveryMethod.cloudLookup,
      discoveredAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraListItem(device: device, onTap: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud), findsOneWidget);
    expect(find.text('Found via cloud'), findsOneWidget);
  });

  testWidgets('CameraListItem handles null IP address',
      (WidgetTester tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST4',
      name: 'Cloud Camera',
      ipAddress: null,
      discoveryMethod: DiscoveryMethod.cloudLookup,
      discoveredAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraListItem(device: device, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Cloud Camera'), findsOneWidget);
    expect(find.textContaining('IP:'), findsNothing);
  });
}
