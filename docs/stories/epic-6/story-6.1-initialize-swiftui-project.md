# Story 6.1: Initialize SwiftUI Project

> **Epic**: 6 - SwiftUI Host Setup (Phase 2)
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** developer,
**I want** a SwiftUI host application,
**So that** I can embed the Flutter camera module.

---

## Acceptance Criteria

- [ ] AC1: SwiftUI project created at `/ios_host_app/`
- [ ] AC2: Project uses iOS 17+ deployment target
- [ ] AC3: Project uses XcodeGen for configuration
- [ ] AC4: Basic ContentView with placeholder UI
- [ ] AC5: Project builds and runs on simulator
- [ ] AC6: MVVM architecture established
- [ ] AC7: Project structure follows SciSymbioLens patterns

---

## Technical Specification

### Project Structure

```
ios_host_app/
├── project.yml                # XcodeGen configuration
├── VeepaPOC/
│   ├── App/
│   │   ├── VeepaPOCApp.swift   # App entry point
│   │   └── AppDelegate.swift    # For Flutter engine
│   ├── Views/
│   │   ├── ContentView.swift    # Main view
│   │   └── CameraContainerView.swift
│   ├── ViewModels/
│   │   └── CameraViewModel.swift
│   ├── Models/
│   │   └── CameraState.swift
│   ├── Services/
│   │   └── FlutterBridge.swift
│   └── Protocols/
│       └── CameraSourceProtocol.swift
├── Resources/
│   └── Assets.xcassets
└── Tests/
    └── VeepaPOCTests/
```

### project.yml (XcodeGen)

```yaml
name: VeepaPOC
options:
  bundleIdPrefix: com.veepapoc
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.0"

settings:
  base:
    SWIFT_VERSION: "5.9"
    TARGETED_DEVICE_FAMILY: "1,2"

targets:
  VeepaPOC:
    type: application
    platform: iOS
    sources:
      - path: VeepaPOC
    resources:
      - path: Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.veepapoc.host
        INFOPLIST_FILE: VeepaPOC/Info.plist
        CODE_SIGN_STYLE: Automatic
        DEVELOPMENT_TEAM: ""
    dependencies:
      - framework: Flutter.xcframework
        embed: true
      - framework: FlutterPluginRegistrant.xcframework
        embed: true

  VeepaPOCTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: Tests/VeepaPOCTests
    dependencies:
      - target: VeepaPOC
```

### VeepaPOCApp.swift

```swift
import SwiftUI

@main
struct VeepaPOCApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### AppDelegate.swift

```swift
import UIKit
import Flutter

class AppDelegate: NSObject, UIApplicationDelegate {
    lazy var flutterEngine: FlutterEngine = {
        let engine = FlutterEngine(name: "veepa_camera_engine")
        engine.run()
        return engine
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Pre-warm Flutter engine
        _ = flutterEngine
        return true
    }
}
```

### ContentView.swift

```swift
import SwiftUI

struct ContentView: View {
    @State private var showingCamera = false
    @State private var connectionStatus = "Disconnected"

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                // Title
                Text("Veepa Camera POC")
                    .font(.title)
                    .fontWeight(.bold)

                // Status
                HStack {
                    Circle()
                        .fill(connectionStatus == "Connected" ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(connectionStatus)
                        .foregroundStyle(.secondary)
                }

                // Phase indicator
                Text("Phase 2: SwiftUI Host")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer().frame(height: 32)

                // Launch camera button
                Button {
                    showingCamera = true
                } label: {
                    Label("Open Camera", systemImage: "video.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("VeepaPOC")
            .fullScreenCover(isPresented: $showingCamera) {
                // Flutter camera view will go here
                Text("Flutter Camera View (Coming in Story 7.2)")
                    .overlay(alignment: .topTrailing) {
                        Button("Close") {
                            showingCamera = false
                        }
                        .padding()
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
```

---

## Implementation Tasks

### Task 1: Create Project Directory Structure
```bash
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/ios_host_app/VeepaPOC/{App,Views,ViewModels,Models,Services,Protocols}
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/ios_host_app/Resources/Assets.xcassets
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/ios_host_app/Tests/VeepaPOCTests
```

**Verification**: Directories exist

### Task 2: Create project.yml
Create XcodeGen configuration file.

**Verification**: Valid YAML syntax

### Task 3: Create Swift Source Files
Create VeepaPOCApp.swift, AppDelegate.swift, ContentView.swift.

**Verification**: No syntax errors

### Task 4: Generate Xcode Project
```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/ios_host_app
xcodegen generate
```

**Verification**: .xcodeproj created

### Task 5: Build and Run
```bash
xcodebuild -project VeepaPOC.xcodeproj -scheme VeepaPOC -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

**Verification**: Build succeeds

---

## Test Cases

### TC6.1.1: Project Generation
**Type**: Automated (Script)
**Priority**: P0

```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/ios_host_app
xcodegen generate
[ -d "VeepaPOC.xcodeproj" ] && echo "PASS" || echo "FAIL"
```

**Given**: project.yml exists
**When**: `xcodegen generate` runs
**Then**: .xcodeproj is created

---

### TC6.1.2: Build Success
**Type**: Automated (CI)
**Priority**: P0

**Given**: Xcode project generated
**When**: Build command executed
**Then**: Build succeeds without errors

---

### TC6.1.3: Manual App Launch Test
**Type**: Manual
**Priority**: P0

**Steps**:
1. Open VeepaPOC.xcodeproj in Xcode
2. Select iPhone 15 Pro simulator
3. Press Run (Cmd+R)
4. Wait for app to launch

**Expected Results**:
- [ ] App launches without crash
- [ ] ContentView displays correctly
- [ ] "Open Camera" button visible
- [ ] Status shows "Disconnected"

---

## Definition of Done

- [ ] All acceptance criteria verified
- [ ] XcodeGen configuration works
- [ ] App builds and runs
- [ ] Code committed with message: "feat(epic-6): Initialize SwiftUI project - Story 6.1"

---

## Dependencies

- **Depends On**: Phase 1 completion
- **Blocks**: Story 6.2, Story 7.1

---

## References

- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [SwiftUI App Life Cycle](https://developer.apple.com/documentation/swiftui/app)
- SciSymbioLens architecture patterns
