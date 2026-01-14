# Story 7.1: Configure Flutter Add-to-App

> **Epic**: 7 - Flutter Embedding (Phase 2)
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** developer,
**I want** the Flutter module properly embedded in the SwiftUI app,
**So that** I can use the Veepa SDK's camera functionality from native code.

---

## Acceptance Criteria

- [ ] AC1: Flutter module added to iOS project via CocoaPods
- [ ] AC2: Flutter engine initialized on app launch
- [ ] AC3: Flutter view can be presented from SwiftUI
- [ ] AC4: No conflicts with SwiftUI lifecycle
- [ ] AC5: Memory properly managed (engine reuse)
- [ ] AC6: Debug and release builds work
- [ ] AC7: Hot reload works in debug mode

---

## Technical Specification

### Podfile Configuration

Update `ios_host_app/Podfile`:

```ruby
platform :ios, '17.0'

# Flutter module path
flutter_application_path = '../flutter_veepa_module'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'VeepaPOC' do
  use_frameworks!

  install_all_flutter_pods(flutter_application_path)
end

post_install do |installer|
  flutter_post_install(installer) if defined?(flutter_post_install)

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
```

### FlutterEngine Management

Create `ios_host_app/VeepaPOC/Services/FlutterEngineManager.swift`:

```swift
import Flutter
import FlutterPluginRegistrant

/// Manages Flutter engine lifecycle
class FlutterEngineManager {
    static let shared = FlutterEngineManager()

    private(set) var engine: FlutterEngine?

    private init() {}

    /// Initialize Flutter engine
    func initializeEngine() {
        guard engine == nil else { return }

        let newEngine = FlutterEngine(name: "veepa_camera_engine")
        newEngine.run()
        GeneratedPluginRegistrant.register(with: newEngine)

        engine = newEngine

        print("[FlutterEngine] Initialized successfully")
    }

    /// Get view controller for Flutter content
    func getViewController() -> FlutterViewController? {
        guard let engine = engine else {
            print("[FlutterEngine] Engine not initialized")
            return nil
        }

        return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }

    /// Cleanup engine
    func destroyEngine() {
        engine?.destroyContext()
        engine = nil
        print("[FlutterEngine] Destroyed")
    }
}
```

### Updated AppDelegate

```swift
import UIKit
import Flutter

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Flutter engine early
        FlutterEngineManager.shared.initializeEngine()
        return true
    }
}
```

---

## Implementation Tasks

### Task 1: Create Podfile
Create Podfile with Flutter module integration.

### Task 2: Run Pod Install
```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/ios_host_app
pod install
```

### Task 3: Create FlutterEngineManager
Create singleton for engine management.

### Task 4: Update AppDelegate
Initialize engine on app launch.

### Task 5: Build and Test
Verify Flutter engine initializes correctly.

---

## Test Cases

### TC7.1.1: Pod Install Success
**Type**: Automated
**Priority**: P0

### TC7.1.2: Engine Initialization
**Type**: Unit Test
**Priority**: P0

### TC7.1.3: ViewController Creation
**Type**: Integration Test
**Priority**: P0

---

## Definition of Done

- [ ] Pod install succeeds
- [ ] Flutter engine initializes without crash
- [ ] Flutter view controller can be created
- [ ] Code committed with message: "feat(epic-7): Configure Flutter Add-to-App - Story 7.1"
