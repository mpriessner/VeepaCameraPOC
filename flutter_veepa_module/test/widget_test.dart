import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/main.dart';

void main() {
  testWidgets('App launches and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());
    await tester.pumpAndSettle();

    expect(find.text('VeepaCameraPOC'), findsOneWidget);
    expect(find.text('Veepa Camera POC'), findsOneWidget);
  });

  testWidgets('HomeScreen shows SDK status indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('SDK Status:'), findsOneWidget);
  });

  testWidgets('HomeScreen shows camera icon', (WidgetTester tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('HomeScreen shows Find Cameras button when SDK ready', (WidgetTester tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());
    await tester.pumpAndSettle();

    expect(find.text('Find Cameras'), findsOneWidget);
    expect(find.textContaining('Ready'), findsOneWidget);
  });
}
