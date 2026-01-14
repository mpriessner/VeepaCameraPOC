# VeepaCameraPOC Product Requirements Document (PRD)

> **Version**: 1.0
> **Status**: Draft
> **Phase**: 1 - Pure Flutter Validation
> **Method**: BMAD

---

## 1. Goals and Background Context

### 1.1 Goals

- Validate Veepa SDK integration in a Flutter application
- Prove camera discovery, connection, and live video streaming
- Establish patterns for Flutter Add-to-App integration with SwiftUI
- Document all learnings for SciSymbioLens Phase 4 integration
- Create reusable code templates and abstractions

### 1.2 Background Context

SciSymbioLens needs external Wi-Fi camera support for Phase 4. The Veepa SDK is Flutter-based while SciSymbioLens is native SwiftUI. This POC validates the Flutter Add-to-App approach before committing to it in the main project.

The Veepa SDK provides:
- P2P connection to Veepa IP cameras
- Live video streaming
- PTZ (Pan-Tilt-Zoom) controls
- Recording capabilities

This POC focuses on proving the core integration works, not building a production-ready app.

### 1.3 Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-01-14 | 1.0 | Initial PRD for Phase 1 & 2 | BMAD |

---

## 2. Requirements

### 2.1 Functional Requirements

#### SDK Integration
- **FR1**: The app SHALL initialize the Veepa SDK on startup
- **FR2**: The app SHALL handle SDK initialization failures gracefully

#### Camera Discovery
- **FR3**: The app SHALL discover Veepa cameras on the local network
- **FR4**: The app SHALL display discovered cameras in a list
- **FR5**: The app SHALL allow manual IP entry if discovery fails

#### Camera Connection
- **FR6**: The app SHALL connect to a selected camera via P2P
- **FR7**: The app SHALL display connection status (connecting, connected, failed)
- **FR8**: The app SHALL handle connection timeouts gracefully
- **FR9**: The app SHALL support reconnection after disconnection

#### Video Streaming
- **FR10**: The app SHALL display live video from connected camera
- **FR11**: The app SHALL show video at minimum 15 FPS
- **FR12**: The app SHALL handle video stream interruptions

#### PTZ Controls (Phase 1)
- **FR13**: The app SHALL support pan left/right controls
- **FR14**: The app SHALL support tilt up/down controls
- **FR15**: The app SHALL support zoom in/out controls

#### Flutter Add-to-App (Phase 2)
- **FR16**: SwiftUI host SHALL embed Flutter module
- **FR17**: Platform Channel SHALL pass camera control commands
- **FR18**: Platform Channel SHALL pass video frame events
- **FR19**: SwiftUI SHALL display Flutter video view

### 2.2 Non-Functional Requirements

#### Performance
- **NFR1**: Camera discovery SHALL complete within 5 seconds
- **NFR2**: P2P connection SHALL establish within 10 seconds
- **NFR3**: Video stream SHALL maintain 15+ FPS
- **NFR4**: PTZ commands SHALL respond within 500ms

#### Reliability
- **NFR5**: App SHALL recover from connection loss
- **NFR6**: App SHALL handle network changes gracefully
- **NFR7**: App SHALL not crash on SDK errors

#### Usability
- **NFR8**: Connection status SHALL be clearly visible
- **NFR9**: Error messages SHALL be user-friendly
- **NFR10**: Controls SHALL be responsive to touch

#### Documentation
- **NFR11**: All learnings SHALL be documented in LEARNINGS.md
- **NFR12**: Code SHALL include comments for non-obvious logic
- **NFR13**: Integration patterns SHALL be documented for reuse

---

## 3. User Interface Design Goals

### 3.1 Phase 1: Flutter POC

Simple, functional UI for testing:

1. **Discovery Screen**
   - List of discovered cameras
   - Manual IP entry option
   - Refresh button

2. **Camera View**
   - Full-screen video preview
   - Connection status indicator
   - PTZ control buttons (overlay)
   - Disconnect button

3. **Error States**
   - Connection failed dialog
   - No cameras found message
   - SDK initialization error

### 3.2 Phase 2: SwiftUI Host

Minimal host for Flutter integration testing:

1. **Main View**
   - Button to launch Flutter camera module
   - Status display (connected/disconnected)
   - Frame rate indicator

2. **Flutter Container**
   - Embedded Flutter view for video
   - Native controls for starting/stopping

---

## 4. Technical Assumptions

### 4.1 Repository Structure

```
VeepaCameraPOC/
├── flutter_veepa_module/          # Flutter module
│   ├── lib/
│   │   ├── main.dart              # Entry point (Phase 1 standalone)
│   │   ├── veepa_camera.dart      # Camera connection wrapper
│   │   ├── veepa_player.dart      # Video player wrapper
│   │   ├── veepa_discovery.dart   # Device discovery
│   │   ├── platform_bridge.dart   # Platform channel (Phase 2)
│   │   └── ui/                    # UI components
│   ├── test/                      # Unit tests
│   └── pubspec.yaml
├── ios_host_app/                  # SwiftUI host (Phase 2)
│   ├── VeepaPOC/
│   │   ├── ContentView.swift
│   │   ├── FlutterBridge.swift
│   │   └── CameraSourceProtocol.swift
│   └── project.yml
└── docs/
    ├── brief.md
    ├── prd.md
    ├── stories/
    └── LEARNINGS.md
```

### 4.2 Testing Requirements

- **Unit Tests**: Connection state machine, discovery logic
- **Integration Tests**: SDK initialization, P2P connection
- **Manual Tests**: Video streaming, PTZ controls with real camera
- **Hardware Required**: Physical Veepa camera on local network

### 4.3 Additional Technical Assumptions

- Flutter SDK available and working
- Veepa camera accessible on local network
- iOS 17+ device for Phase 2 testing
- Veepa SDK files copied from `/Users/mpriessner/windsurf_repos/Veepaisdk/`

---

## 5. Epic List

### Phase 1 Epics (Flutter POC)

| Epic | Title | Goal |
|------|-------|------|
| **Epic 1** | Project Setup | Initialize Flutter project with Veepa SDK |
| **Epic 2** | Camera Discovery | Discover cameras on local network |
| **Epic 3** | Camera Connection | Establish P2P connection to camera |
| **Epic 4** | Video Streaming | Display live video from camera |
| **Epic 5** | PTZ Controls | Implement pan/tilt/zoom controls |

### Phase 2 Epics (Flutter Add-to-App)

| Epic | Title | Goal |
|------|-------|------|
| **Epic 6** | SwiftUI Host Setup | Create minimal SwiftUI host app |
| **Epic 7** | Flutter Embedding | Embed Flutter module in SwiftUI |
| **Epic 8** | Platform Bridge | Create Platform Channel for communication |
| **Epic 9** | Integration Testing | Verify end-to-end video flow |

---

## 6. Epic Details

---

### Epic 1: Project Setup

**Goal**: Initialize Flutter project with Veepa SDK dependencies and verify SDK loads correctly.

---

#### Story 1.1: Initialize Flutter Project

**As a** developer,
**I want** a properly configured Flutter project,
**So that** I can build the POC app.

**Acceptance Criteria**:
1. Flutter project created with `flutter create`
2. Project name set to `flutter_veepa_module`
3. Minimum iOS deployment target set to iOS 10.0
4. Project builds successfully on iOS simulator
5. Basic "Hello World" screen displays

**Tests**:
- [ ] `flutter pub get` succeeds
- [ ] `flutter build ios` succeeds
- [ ] App launches on iOS simulator without crash

---

#### Story 1.2: Add Veepa SDK Dependencies

**As a** developer,
**I want** the Veepa SDK added to the project,
**So that** I can access camera functionality.

**Acceptance Criteria**:
1. Veepa SDK source files copied to project
2. `pubspec.yaml` updated with SDK path dependency
3. Native iOS library (`libVSTC.a`) linked
4. Required iOS permissions added to Info.plist
5. Project compiles with SDK included

**Tests**:
- [ ] `flutter pub get` succeeds with SDK
- [ ] No compilation errors related to SDK
- [ ] iOS build includes `libVSTC.a`

---

#### Story 1.3: Verify SDK Initialization

**As a** developer,
**I want** to verify the SDK initializes correctly,
**So that** I can use camera features.

**Acceptance Criteria**:
1. SDK initialization code added to app startup
2. Initialization success/failure logged
3. Error handling for initialization failure
4. App displays initialization status on screen
5. Can proceed to next screen on success

**Tests**:
- [ ] Unit test: SDK initialization mock
- [ ] Manual test: SDK initializes on real device
- [ ] Manual test: Error shown if SDK fails

---

### Epic 2: Camera Discovery

**Goal**: Discover Veepa cameras available on the local network.

---

#### Story 2.1: Implement Device Discovery Service

**As a** developer,
**I want** a service that discovers cameras,
**So that** users can see available cameras.

**Acceptance Criteria**:
1. `VeepaDiscovery` class created
2. Uses SDK's LAN scan functionality
3. Returns list of discovered devices
4. Handles timeout after 5 seconds
5. Supports manual refresh

**Tests**:
- [ ] Unit test: Discovery state machine
- [ ] Unit test: Timeout handling
- [ ] Manual test: Discovers real camera on network

---

#### Story 2.2: Create Discovery UI

**As a** user,
**I want** to see available cameras,
**So that** I can select one to connect.

**Acceptance Criteria**:
1. Discovery screen displays list of cameras
2. Each camera shows name/ID
3. Loading indicator during discovery
4. "No cameras found" message if empty
5. Refresh button to retry discovery
6. Tap on camera navigates to connection screen

**Tests**:
- [ ] Unit test: UI state changes
- [ ] Manual test: UI displays discovered cameras
- [ ] Manual test: Refresh button works

---

#### Story 2.3: Manual IP Entry

**As a** user,
**I want** to enter a camera IP manually,
**So that** I can connect if discovery fails.

**Acceptance Criteria**:
1. "Manual Entry" button on discovery screen
2. Dialog with IP address text field
3. Basic IP format validation
4. Proceeds to connection with entered IP
5. Saves last used IP for convenience

**Tests**:
- [ ] Unit test: IP validation logic
- [ ] Manual test: Manual entry connects to camera

---

### Epic 3: Camera Connection

**Goal**: Establish P2P connection to a Veepa camera.

---

#### Story 3.1: Implement Connection Manager

**As a** developer,
**I want** a connection manager service,
**So that** connection logic is centralized.

**Acceptance Criteria**:
1. `VeepaConnectionManager` class created
2. Manages P2P connection lifecycle
3. Exposes connection state as stream
4. Supports connect/disconnect operations
5. Handles connection timeouts (10 second limit)
6. Implements reconnection on disconnect

**Tests**:
- [ ] Unit test: Connection state transitions
- [ ] Unit test: Timeout handling
- [ ] Integration test: Connect to real camera

---

#### Story 3.2: Connection UI and Status

**As a** user,
**I want** to see connection status,
**So that** I know if the camera is ready.

**Acceptance Criteria**:
1. Connection status indicator visible
2. States: Disconnected, Connecting, Connected, Error
3. Error message shown on failure
4. Retry button on connection failure
5. Automatic navigation to video screen on success

**Tests**:
- [ ] Unit test: Status display logic
- [ ] Manual test: Status updates correctly
- [ ] Manual test: Retry works after failure

---

#### Story 3.3: Handle Disconnection

**As a** user,
**I want** the app to handle disconnections gracefully,
**So that** I don't lose control of the camera.

**Acceptance Criteria**:
1. Disconnection detected within 2 seconds
2. User notified of disconnection
3. Automatic reconnection attempted (3 retries)
4. Option to return to camera list
5. No crashes on unexpected disconnect

**Tests**:
- [ ] Unit test: Reconnection logic
- [ ] Manual test: Recover from network drop
- [ ] Manual test: Clean disconnect flow

---

### Epic 4: Video Streaming

**Goal**: Display live video from the connected camera.

---

#### Story 4.1: Implement Video Player Service

**As a** developer,
**I want** a video player service,
**So that** I can display camera video.

**Acceptance Criteria**:
1. `VeepaPlayer` class wraps SDK player
2. Starts/stops video stream
3. Exposes player state (playing, paused, error)
4. Reports frame rate for diagnostics
5. Handles stream errors gracefully

**Tests**:
- [ ] Unit test: Player state machine
- [ ] Integration test: Player starts with real camera
- [ ] Manual test: Video displays on screen

---

#### Story 4.2: Video Display UI

**As a** user,
**I want** to see live video from the camera,
**So that** I can monitor what the camera sees.

**Acceptance Criteria**:
1. Full-screen video display
2. Video fills available space (aspect fit)
3. Loading indicator while buffering
4. Frame rate indicator (debug mode)
5. Video starts automatically on connection

**Tests**:
- [ ] Manual test: Video displays at 15+ FPS
- [ ] Manual test: No significant latency (<500ms)
- [ ] Manual test: Handles portrait/landscape

---

#### Story 4.3: Handle Video Errors

**As a** user,
**I want** video errors handled gracefully,
**So that** I can continue using the app.

**Acceptance Criteria**:
1. Video error detected and logged
2. Error message displayed to user
3. Retry button available
4. Option to return to camera list
5. App doesn't crash on video error

**Tests**:
- [ ] Unit test: Error state handling
- [ ] Manual test: Recovery from stream interruption

---

### Epic 5: PTZ Controls

**Goal**: Implement pan/tilt/zoom controls for the camera.

---

#### Story 5.1: Implement PTZ Command Service

**As a** developer,
**I want** a PTZ command service,
**So that** I can control camera movement.

**Acceptance Criteria**:
1. `VeepaPTZController` class created
2. Pan left/right commands
3. Tilt up/down commands
4. Zoom in/out commands
5. Stop command when button released
6. Command response time logged

**Tests**:
- [ ] Unit test: Command generation
- [ ] Integration test: Commands sent to real camera
- [ ] Manual test: Camera responds to commands

---

#### Story 5.2: PTZ Control UI

**As a** user,
**I want** on-screen controls for PTZ,
**So that** I can move the camera.

**Acceptance Criteria**:
1. Directional pad overlay (up/down/left/right)
2. Zoom buttons (+ / -)
3. Controls semi-transparent over video
4. Press-and-hold for continuous movement
5. Release stops movement
6. Controls can be hidden/shown

**Tests**:
- [ ] Manual test: Pan left/right works
- [ ] Manual test: Tilt up/down works
- [ ] Manual test: Zoom in/out works
- [ ] Manual test: Stop on release works

---

### Epic 6: SwiftUI Host Setup (Phase 2)

**Goal**: Create minimal SwiftUI host application for Flutter embedding.

---

#### Story 6.1: Initialize SwiftUI Project

**As a** developer,
**I want** a SwiftUI host app,
**So that** I can embed the Flutter module.

**Acceptance Criteria**:
1. SwiftUI project created with XcodeGen
2. iOS 17+ deployment target
3. Basic ContentView with placeholder
4. Project builds and runs on simulator

**Tests**:
- [ ] `xcodegen generate` succeeds
- [ ] App builds and launches

---

#### Story 6.2: Define Camera Source Protocol

**As a** developer,
**I want** an abstract camera protocol,
**So that** I can support multiple camera sources.

**Acceptance Criteria**:
1. `CameraSourceProtocol` defined in Swift
2. Methods: connect(), disconnect(), startStream(), stopStream()
3. Properties: connectionState, isStreaming
4. Events: onFrame callback
5. Documentation for future implementers

**Tests**:
- [ ] Protocol compiles correctly
- [ ] Mock implementation passes tests

---

### Epic 7: Flutter Embedding (Phase 2)

**Goal**: Embed Flutter module in SwiftUI host.

---

#### Story 7.1: Configure Flutter Add-to-App

**As a** developer,
**I want** Flutter embedded in the SwiftUI app,
**So that** I can use the Veepa SDK.

**Acceptance Criteria**:
1. Flutter module added to iOS project
2. Flutter engine initialized on app launch
3. Flutter view can be presented
4. No conflicts with SwiftUI lifecycle
5. Memory properly managed

**Tests**:
- [ ] Flutter view displays in SwiftUI
- [ ] No memory leaks on view present/dismiss

---

#### Story 7.2: Create Flutter Container View

**As a** user,
**I want** to see the Flutter camera view,
**So that** I can use the camera.

**Acceptance Criteria**:
1. SwiftUI view wraps Flutter view
2. Full-screen Flutter camera display
3. Native button to dismiss Flutter view
4. Smooth transitions enter/exit

**Tests**:
- [ ] Manual test: Flutter view displays correctly
- [ ] Manual test: Dismiss returns to SwiftUI

---

### Epic 8: Platform Bridge (Phase 2)

**Goal**: Create Platform Channel for Swift ↔ Flutter communication.

---

#### Story 8.1: Implement Method Channel (Swift → Dart)

**As a** developer,
**I want** Swift to call Flutter methods,
**So that** I can control the camera from native code.

**Acceptance Criteria**:
1. MethodChannel defined in both Swift and Dart
2. `connect(deviceId)` method callable from Swift
3. `disconnect()` method callable from Swift
4. `setPTZ(direction)` method callable from Swift
5. Error handling for failed calls

**Tests**:
- [ ] Unit test: Method calls serialize correctly
- [ ] Integration test: Swift calls reach Dart

---

#### Story 8.2: Implement Event Channel (Dart → Swift)

**As a** developer,
**I want** Flutter to send events to Swift,
**So that** I can receive video frames and status.

**Acceptance Criteria**:
1. EventChannel defined in both Dart and Swift
2. Connection state changes streamed to Swift
3. Video frame events streamed (if needed)
4. Frame rate metrics available
5. Clean subscription management

**Tests**:
- [ ] Unit test: Events serialize correctly
- [ ] Integration test: Events received in Swift

---

### Epic 9: Integration Testing (Phase 2)

**Goal**: Verify end-to-end video flow works correctly.

---

#### Story 9.1: End-to-End Connection Test

**As a** developer,
**I want** to verify the full integration,
**So that** I know the POC is successful.

**Acceptance Criteria**:
1. SwiftUI app launches
2. Flutter module initializes
3. Camera connects via Platform Channel
4. Video displays in Flutter view
5. PTZ commands work from native controls

**Tests**:
- [ ] Manual test: Full flow works end-to-end
- [ ] Metrics: Connection time, frame rate, command latency

---

#### Story 9.2: Document Learnings

**As a** developer,
**I want** all learnings documented,
**So that** SciSymbioLens integration is easier.

**Acceptance Criteria**:
1. LEARNINGS.md created with all discoveries
2. Code patterns documented
3. Pitfalls and solutions noted
4. Integration checklist for SciSymbioLens
5. Performance metrics recorded

**Tests**:
- [ ] Documentation reviewed for completeness
- [ ] Code examples verified working

---

## 7. Test Summary

### Unit Tests (Automated)

| Area | Tests | Coverage Goal |
|------|-------|---------------|
| Discovery | State machine, timeout | 80% |
| Connection | State transitions, reconnection | 80% |
| Player | State machine, error handling | 70% |
| PTZ | Command generation | 70% |
| Platform Bridge | Serialization | 80% |

### Integration Tests (Semi-Automated)

| Area | Test | Verification |
|------|------|-------------|
| SDK Init | Initializes without error | Log output |
| Discovery | Finds camera on network | Device list |
| Connection | Establishes P2P link | State change |
| Video | Stream starts | Visual |

### Manual Tests (Hardware Required)

| Area | Test | Expected Result |
|------|------|-----------------|
| Discovery | Scan local network | Camera appears in list |
| Connection | Connect to camera | Status shows "Connected" |
| Video | View live stream | Smooth video at 15+ FPS |
| PTZ | Pan left | Camera moves left |
| PTZ | Tilt up | Camera moves up |
| PTZ | Zoom in | Image zooms |
| Disconnect | Kill network | Reconnection attempted |

---

## 8. Next Steps

1. **Execute Epic 1** - Set up Flutter project with SDK
2. **Validate SDK** - Ensure Veepa SDK initializes correctly
3. **Implement Discovery** - Find cameras on network
4. **Implement Connection** - Establish P2P link
5. **Implement Video** - Display live stream
6. **Proceed to Phase 2** - Flutter Add-to-App integration

---

*Generated using BMAD methodology*
