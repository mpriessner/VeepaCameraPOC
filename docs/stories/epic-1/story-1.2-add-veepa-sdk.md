# Story 1.2: Add Veepa SDK Dependencies

> **Epic**: 1 - Project Setup
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** developer,
**I want** the Veepa SDK integrated into the Flutter project,
**So that** I can access camera discovery, connection, and streaming functionality.

---

## Acceptance Criteria

- [ ] AC1: Veepa SDK Dart source files copied to `lib/sdk/` directory
- [ ] AC2: Native iOS library (`libVSTC.a`) properly linked
- [ ] AC3: All required iOS permissions added to Info.plist
- [ ] AC4: `pubspec.yaml` updated with all SDK dependencies
- [ ] AC5: Project compiles without errors after SDK integration
- [ ] AC6: SDK classes can be imported in Dart code
- [ ] AC7: iOS build succeeds with native library linked

---

## Technical Specification

### SDK Source Location

The Veepa SDK is located at:
```
/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/
```

### Files to Copy

#### Dart Source Files
Copy from `flutter-sdk-demo/lib/` to `flutter_veepa_module/lib/sdk/`:

```
lib/sdk/
├── app_p2p_api.dart           # P2P connection API
├── app_player.dart            # Video player controller
├── app_dart.dart              # Native FFI interface
├── camera_device/
│   ├── camera_device.dart     # Main device class
│   ├── camera_device_mixin.dart
│   └── commands/              # Hardware control commands
│       ├── alarm_command.dart
│       ├── camera_command.dart
│       ├── card_command.dart
│       ├── light_command.dart
│       ├── motor_command.dart
│       ├── params_command.dart
│       ├── plan_command.dart
│       ├── power_command.dart
│       ├── record_command.dart
│       ├── status_command.dart
│       ├── video_command.dart
│       └── wifi_command.dart
└── video_source/
    ├── video_source.dart
    ├── live_video_source.dart
    └── card_video_source.dart
```

#### Native iOS Library
Copy from `/Users/mpriessner/windsurf_repos/Veepaisdk/ios库/`:
- `libVSTC.a` (24.6 MB) → `flutter_veepa_module/.ios/Flutter/libVSTC.a`

### Required pubspec.yaml Dependencies

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

  # Required by Veepa SDK
  dio: ^5.0.0                    # HTTP client for API calls
  crypto: ^3.0.0                 # Cryptographic functions
  fast_gbk: ^1.0.0               # GBK encoding support (Chinese)
  path_provider: ^2.0.0          # File system paths
  shared_preferences: ^2.0.0     # Local storage
  permission_handler: ^11.0.0    # Runtime permissions

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

### iOS Info.plist Permissions

Add to `.ios/Runner/Info.plist`:

```xml
<!-- Camera Access -->
<key>NSCameraUsageDescription</key>
<string>VeepaCameraPOC needs camera access for video streaming from external cameras.</string>

<!-- Microphone Access -->
<key>NSMicrophoneUsageDescription</key>
<string>VeepaCameraPOC needs microphone access for audio streaming.</string>

<!-- Local Network Access (Required for camera discovery) -->
<key>NSLocalNetworkUsageDescription</key>
<string>VeepaCameraPOC needs local network access to discover and connect to Veepa cameras on your network.</string>

<!-- Bonjour Services for Discovery -->
<key>NSBonjourServices</key>
<array>
    <string>_camera._tcp</string>
    <string>_http._tcp</string>
</array>

<!-- Background Modes (Optional, for maintaining connection) -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### iOS Podfile Configuration

Update `.ios/Podfile` to link the native library:

```ruby
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}."
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Link Veepa native library
  pod 'VeepaSDK', :path => '../VeepaSDK.podspec'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

### VeepaSDK.podspec (Create This File)

Create `.ios/VeepaSDK.podspec`:

```ruby
Pod::Spec.new do |s|
  s.name             = 'VeepaSDK'
  s.version          = '1.0.0'
  s.summary          = 'Veepa Camera SDK native library'
  s.description      = 'Native iOS library for Veepa camera P2P connection and video streaming'
  s.homepage         = 'https://github.com/veepapoc'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'VeepaPOC' => 'dev@veepapoc.com' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '12.0'

  s.vendored_libraries = 'Flutter/libVSTC.a'

  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'VideoToolbox', 'AudioToolbox', 'CoreMedia', 'CoreVideo'
  s.libraries = 'z', 'c++'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end
```

### SDK Import Wrapper

Create `lib/sdk/veepa_sdk.dart` as a single import point:

```dart
/// Veepa SDK - Main export file
/// Import this file to access all SDK functionality
library veepa_sdk;

// Core APIs
export 'app_p2p_api.dart';
export 'app_player.dart';

// Camera Device
export 'camera_device/camera_device.dart';

// Video Sources
export 'video_source/video_source.dart';
export 'video_source/live_video_source.dart';

// Commands (export commonly used ones)
export 'camera_device/commands/motor_command.dart';
export 'camera_device/commands/video_command.dart';
```

---

## Implementation Tasks

### Task 1: Create SDK Directory Structure
```bash
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/camera_device/commands
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/video_source
```

**Verification**: Directories exist

### Task 2: Copy Veepa SDK Dart Files
```bash
# Copy main SDK files
cp /Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/app_p2p_api.dart \
   /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/

cp /Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/app_player.dart \
   /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/

# Copy camera_device folder
cp -r /Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/camera_device/* \
   /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/camera_device/
```

**Verification**: All .dart files copied

### Task 3: Update Import Paths in Copied Files
SDK files have relative imports that need adjustment. Update imports to use package paths:

```dart
// Change from:
import '../app_p2p_api.dart';

// To:
import 'package:flutter_veepa_module/sdk/app_p2p_api.dart';
```

**Verification**: No import errors after changes

### Task 4: Update pubspec.yaml with Dependencies
Add all required dependencies as specified in Technical Specification.

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter pub get
```

**Verification**: `flutter pub get` succeeds

### Task 5: Copy Native iOS Library
```bash
cp /Users/mpriessner/windsurf_repos/Veepaisdk/ios库/libVSTC.a \
   /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/.ios/Flutter/
```

**Verification**: File exists and is ~24.6 MB

### Task 6: Create VeepaSDK.podspec
Create the podspec file as specified in Technical Specification.

**Verification**: File created at `.ios/VeepaSDK.podspec`

### Task 7: Update iOS Podfile
Update `.ios/Podfile` to link the native library.

**Verification**: Podfile contains VeepaSDK pod reference

### Task 8: Add iOS Permissions to Info.plist
Add all required permissions to `.ios/Runner/Info.plist`.

**Verification**: All permission keys present in plist

### Task 9: Run Pod Install
```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/.ios
pod install
```

**Verification**: Pod install succeeds

### Task 10: Create SDK Export File
Create `lib/sdk/veepa_sdk.dart` with all exports.

**Verification**: File created with correct exports

### Task 11: Verify SDK Import
Update `main.dart` to import SDK:

```dart
import 'package:flutter_veepa_module/sdk/veepa_sdk.dart';
```

**Verification**: No import errors

### Task 12: Build iOS Project
```bash
flutter build ios --no-codesign
```

**Verification**: Build succeeds with exit code 0

---

## Test Cases

### TC1.2.1: SDK Files Copied Successfully
**Type**: Automated (Script)
**Priority**: P0

```bash
#!/bin/bash
SDK_DIR="/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk"

# Check required files
FILES=(
    "app_p2p_api.dart"
    "app_player.dart"
    "veepa_sdk.dart"
    "camera_device/camera_device.dart"
)

for file in "${FILES[@]}"; do
    if [ ! -f "$SDK_DIR/$file" ]; then
        echo "FAIL: Missing $file"
        exit 1
    fi
    echo "PASS: Found $file"
done

echo "All SDK files present!"
```

**Given**: SDK copy tasks executed
**When**: Verification script runs
**Then**: All required files exist

---

### TC1.2.2: Native Library Linked
**Type**: Automated (Script)
**Priority**: P0

```bash
#!/bin/bash
LIB_PATH="/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/.ios/Flutter/libVSTC.a"

if [ ! -f "$LIB_PATH" ]; then
    echo "FAIL: libVSTC.a not found"
    exit 1
fi

# Check file size (should be ~24MB)
SIZE=$(stat -f%z "$LIB_PATH")
if [ "$SIZE" -lt 20000000 ]; then
    echo "FAIL: libVSTC.a too small ($SIZE bytes)"
    exit 1
fi

echo "PASS: libVSTC.a found and valid size ($SIZE bytes)"
```

**Given**: Native library copy task executed
**When**: Verification script runs
**Then**: Library exists and has correct size

---

### TC1.2.3: Dependencies Resolve
**Type**: Automated (CI)
**Priority**: P0

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter pub get
echo "Exit code: $?"
```

**Given**: Updated pubspec.yaml with all dependencies
**When**: `flutter pub get` is executed
**Then**: All dependencies resolve successfully

---

### TC1.2.4: SDK Import Test
**Type**: Automated (Unit Test)
**Priority**: P0

```dart
// test/sdk_import_test.dart
import 'package:flutter_test/flutter_test.dart';

// Import SDK to verify it compiles
import 'package:flutter_veepa_module/sdk/veepa_sdk.dart';

void main() {
  test('SDK exports are accessible', () {
    // These should not throw if SDK is properly configured
    expect(ClientConnectState.values, isNotEmpty);
    expect(ClientChannelType.P2P_CMD_CHANNEL, isNotNull);
  });

  test('SDK classes can be instantiated (mocked)', () {
    // Verify key types exist
    expect(ClientConnectState.CONNECT_STATUS_CONNECTING, isNotNull);
    expect(ClientConnectState.CONNECT_STATUS_ONLINE, isNotNull);
  });
}
```

**Given**: SDK files integrated
**When**: Import test runs
**Then**: SDK types are accessible without errors

---

### TC1.2.5: iOS Permissions Present
**Type**: Automated (Script)
**Priority**: P1

```bash
#!/bin/bash
PLIST="/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/.ios/Runner/Info.plist"

KEYS=(
    "NSCameraUsageDescription"
    "NSMicrophoneUsageDescription"
    "NSLocalNetworkUsageDescription"
)

for key in "${KEYS[@]}"; do
    if ! grep -q "$key" "$PLIST"; then
        echo "FAIL: Missing permission key: $key"
        exit 1
    fi
    echo "PASS: Found $key"
done

echo "All permissions present!"
```

**Given**: Info.plist updated with permissions
**When**: Verification script runs
**Then**: All required permission keys present

---

### TC1.2.6: Pod Install Success
**Type**: Automated (CI)
**Priority**: P0

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/.ios
pod install --repo-update
echo "Exit code: $?"
```

**Given**: Podfile and podspec configured
**When**: `pod install` is executed
**Then**: Pods install successfully

---

### TC1.2.7: iOS Build with SDK
**Type**: Automated (CI)
**Priority**: P0

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter build ios --no-codesign --debug
echo "Exit code: $?"
```

**Given**: SDK fully integrated
**When**: `flutter build ios` is executed
**Then**: Build completes successfully

---

### TC1.2.8: Flutter Analyze with SDK
**Type**: Automated (CI)
**Priority**: P1

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter analyze lib/sdk/
```

**Given**: SDK files with updated imports
**When**: `flutter analyze` is executed
**Then**: No errors (warnings acceptable for third-party code)

---

### TC1.2.9: Manual Build Verification
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Story 1.1 completed
- Xcode installed
- CocoaPods installed

**Steps**:
1. Open terminal
2. Navigate to `flutter_veepa_module`
3. Run `flutter clean`
4. Run `flutter pub get`
5. Navigate to `.ios` directory
6. Run `pod install`
7. Run `flutter build ios --no-codesign`
8. Open Xcode project and verify libVSTC.a is linked

**Expected Results**:
- [ ] No errors during pub get
- [ ] Pod install completes successfully
- [ ] iOS build completes successfully
- [ ] In Xcode: libVSTC.a visible under Frameworks
- [ ] No linker errors related to SDK

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC7) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] SDK can be imported in Dart code without errors
- [ ] iOS build succeeds with native library linked
- [ ] Code committed with message: "feat(epic-1): Integrate Veepa SDK - Story 1.2"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 1.1 (Initialize Flutter Project)
- **Blocks**: Story 1.3 (Verify SDK Initialization)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Import path issues | High | High | Carefully update all imports |
| Native library architecture mismatch | High | Medium | Check library architectures with `lipo -info` |
| Missing SDK dependencies | Medium | Medium | Check original pubspec for all deps |
| Podfile configuration errors | Medium | Medium | Follow exact podspec format |
| Simulator build fails (arm64) | Medium | High | Exclude arm64 for simulator in podspec |

---

## Troubleshooting Guide

### Error: "Could not find module 'xxx'"
**Cause**: Import path not updated correctly
**Solution**: Verify all imports use `package:flutter_veepa_module/sdk/...`

### Error: "Undefined symbols for architecture"
**Cause**: Native library not linked or wrong architecture
**Solution**:
1. Verify libVSTC.a copied to correct location
2. Run `lipo -info libVSTC.a` to check architectures
3. Ensure podspec excludes arm64 for simulator

### Error: "Pod not found: VeepaSDK"
**Cause**: Podspec path incorrect
**Solution**: Verify VeepaSDK.podspec exists at `.ios/VeepaSDK.podspec`

### Error: Permission denied
**Cause**: iOS permissions not configured
**Solution**: Ensure all permission keys added to Info.plist

---

## References

- [Veepa SDK Analysis](/Users/mpriessner/windsurf_repos/Veepaisdk/SDK_ANALYSIS.md)
- [Flutter Add-to-App iOS](https://docs.flutter.dev/add-to-app/ios/project-setup)
- [CocoaPods Podspec](https://guides.cocoapods.org/syntax/podspec.html)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC1.2.1 | | | |
| TC1.2.2 | | | |
| TC1.2.3 | | | |
| TC1.2.4 | | | |
| TC1.2.5 | | | |
| TC1.2.6 | | | |
| TC1.2.7 | | | |
| TC1.2.8 | | | |
| TC1.2.9 | | | |

---
