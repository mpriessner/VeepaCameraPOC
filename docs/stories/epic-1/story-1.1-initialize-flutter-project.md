# Story 1.1: Initialize Flutter Project

> **Epic**: 1 - Project Setup
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small

---

## User Story

**As a** developer,
**I want** a properly configured Flutter project as a module,
**So that** I can build the POC app and later embed it in SwiftUI.

---

## Acceptance Criteria

- [ ] AC1: Flutter module project created at `/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/`
- [ ] AC2: Project uses Flutter module template (not app template) for Add-to-App compatibility
- [ ] AC3: Minimum Dart SDK version set to `>=2.17.0 <4.0.0`
- [ ] AC4: iOS deployment target set to iOS 12.0 in Podfile
- [ ] AC5: Project builds successfully with `flutter build ios --no-codesign`
- [ ] AC6: App displays test screen with "VeepaCameraPOC" title
- [ ] AC7: Basic project structure follows Flutter best practices

---

## Technical Specification

### Project Creation Command

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC
flutter create --template=module --org=com.veepapoc --project-name=flutter_veepa_module flutter_veepa_module
```

### Why Module Template?

The `--template=module` creates a Flutter module that:
1. Can run standalone for Phase 1 testing
2. Can be embedded in a host app (SwiftUI) for Phase 2
3. Generates `.ios/` and `.android/` hidden folders for platform integration
4. Creates proper `pubspec.yaml` for module packaging

### Required Directory Structure

```
flutter_veepa_module/
├── lib/
│   └── main.dart                 # Entry point
├── test/
│   └── widget_test.dart          # Basic widget tests
├── .ios/                         # iOS integration (hidden, auto-generated)
├── .android/                     # Android integration (hidden, auto-generated)
├── pubspec.yaml                  # Dependencies and metadata
├── analysis_options.yaml         # Linter configuration
└── README.md                     # Module documentation
```

### pubspec.yaml Configuration

```yaml
name: flutter_veepa_module
description: Veepa Camera POC - Flutter module for camera integration
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=2.17.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

### Initial main.dart

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const VeepaCameraPOCApp());
}

class VeepaCameraPOCApp extends StatelessWidget {
  const VeepaCameraPOCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeepaCameraPOC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VeepaCameraPOC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Veepa Camera POC',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Phase 1: Flutter Module Ready',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

### iOS Podfile Configuration

After project creation, update `.ios/Flutter/podhelper.rb` is auto-managed.
For standalone testing, create `example/` app or use `flutter run`.

---

## Implementation Tasks

### Task 1: Create Flutter Module
```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC
flutter create --template=module --org=com.veepapoc --project-name=flutter_veepa_module flutter_veepa_module
```

**Verification**: Directory structure created with `lib/`, `test/`, `.ios/`, `.android/`

### Task 2: Update pubspec.yaml
- Set SDK constraints
- Add project description
- Configure Flutter settings

**Verification**: `flutter pub get` succeeds

### Task 3: Create Initial main.dart
- Replace default code with VeepaCameraPOC app
- Create HomeScreen widget
- Add placeholder UI

**Verification**: No lint errors, code compiles

### Task 4: Run Flutter Analyze
```bash
cd flutter_veepa_module
flutter analyze
```

**Verification**: No errors, warnings acceptable

### Task 5: Build iOS
```bash
flutter build ios --no-codesign
```

**Verification**: Build completes with exit code 0

### Task 6: Test on Simulator
```bash
# Create example app for testing
cd flutter_veepa_module
flutter create example
cd example
flutter run
```

**Verification**: App launches, shows "VeepaCameraPOC" title

### Task 7: Run Unit Tests
```bash
flutter test
```

**Verification**: Default tests pass

---

## Test Cases

### TC1.1.1: Project Structure Validation
**Type**: Automated (Script)
**Priority**: P0

```bash
#!/bin/bash
# test_project_structure.sh

PROJECT_DIR="/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module"

# Check required files exist
assert_file_exists() {
    if [ ! -f "$1" ]; then
        echo "FAIL: File not found: $1"
        exit 1
    fi
    echo "PASS: File exists: $1"
}

assert_dir_exists() {
    if [ ! -d "$1" ]; then
        echo "FAIL: Directory not found: $1"
        exit 1
    fi
    echo "PASS: Directory exists: $1"
}

assert_dir_exists "$PROJECT_DIR/lib"
assert_file_exists "$PROJECT_DIR/lib/main.dart"
assert_file_exists "$PROJECT_DIR/pubspec.yaml"
assert_dir_exists "$PROJECT_DIR/.ios"
assert_dir_exists "$PROJECT_DIR/.android"

echo "All structure tests passed!"
```

**Given**: Flutter create command executed
**When**: Structure validation script runs
**Then**: All required files and directories exist

---

### TC1.1.2: Pub Get Success
**Type**: Automated (CI)
**Priority**: P0

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter pub get
echo "Exit code: $?"
```

**Given**: Valid pubspec.yaml
**When**: `flutter pub get` is executed
**Then**: Command exits with code 0, no errors in output

---

### TC1.1.3: Flutter Analyze Clean
**Type**: Automated (CI)
**Priority**: P1

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter analyze --no-fatal-warnings
```

**Given**: Project with main.dart
**When**: `flutter analyze` is executed
**Then**: No errors reported (warnings acceptable)

---

### TC1.1.4: iOS Build Success
**Type**: Automated (CI)
**Priority**: P0

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter build ios --no-codesign --debug
echo "Exit code: $?"
```

**Given**: Valid Flutter module project
**When**: `flutter build ios --no-codesign` is executed
**Then**: Build completes with exit code 0

---

### TC1.1.5: Widget Test Pass
**Type**: Automated (Unit Test)
**Priority**: P1

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/main.dart';

void main() {
  testWidgets('HomeScreen displays VeepaCameraPOC title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VeepaCameraPOCApp());

    // Verify title is displayed
    expect(find.text('VeepaCameraPOC'), findsOneWidget);

    // Verify subtitle is displayed
    expect(find.text('Phase 1: Flutter Module Ready'), findsOneWidget);

    // Verify camera icon is displayed
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('App uses Material 3 theme', (WidgetTester tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
  });
}
```

**Given**: VeepaCameraPOCApp widget
**When**: Widget tests are executed
**Then**: Title, subtitle, and icon are found in widget tree

---

### TC1.1.6: Manual App Launch Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- iOS Simulator running (iPhone 15 Pro recommended)
- Flutter SDK installed and in PATH

**Steps**:
1. Open terminal
2. Navigate to `flutter_veepa_module` directory
3. Run `flutter run`
4. Wait for app to launch on simulator

**Expected Results**:
- [ ] App launches without crash
- [ ] AppBar shows "VeepaCameraPOC" title
- [ ] Camera icon displayed in center
- [ ] "Veepa Camera POC" text displayed
- [ ] "Phase 1: Flutter Module Ready" subtitle displayed
- [ ] Blue color scheme applied

**Screenshot Required**: Yes - capture home screen

---

### TC1.1.7: Hot Reload Functionality
**Type**: Manual
**Priority**: P2

**Steps**:
1. With app running, modify text in main.dart
2. Save file
3. Observe hot reload

**Expected Results**:
- [ ] Hot reload completes in < 2 seconds
- [ ] UI updates without app restart
- [ ] No errors in console

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC7) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] Code committed with message: "feat(epic-1): Initialize Flutter module project - Story 1.1"
- [ ] No lint errors
- [ ] Screenshot of running app captured
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: None (first story)
- **Blocks**: Story 1.2 (Add Veepa SDK)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Flutter SDK not installed | High | Low | Verify Flutter installation first |
| Module template issues | Medium | Low | Fall back to app template if needed |
| iOS build requires Xcode | Medium | Medium | Ensure Xcode 15+ installed |

---

## References

- [Flutter Module Template](https://docs.flutter.dev/add-to-app/flutter-modules)
- [Flutter Create Command](https://docs.flutter.dev/reference/flutter-cli#flutter-commands)
- [iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

*QA review results will be added after implementation*

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC1.1.1 | | | |
| TC1.1.2 | | | |
| TC1.1.3 | | | |
| TC1.1.4 | | | |
| TC1.1.5 | | | |
| TC1.1.6 | | | |
| TC1.1.7 | | | |

---
