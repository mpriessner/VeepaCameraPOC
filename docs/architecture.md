# VeepaCameraPOC Architecture Document

> **Version**: 1.0
> **Status**: Draft
> **Created**: 2025-01-14
> **Method**: BMAD Architecture (Winston the Architect)

---

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-01-14 | 1.0 | Initial architecture document | BMAD Architect |

---

## 1. Executive Summary

This document defines the technical architecture for VeepaCameraPOC, a proof-of-concept validating Veepa IP camera integration using Flutter Add-to-App with a SwiftUI host. The architecture prioritizes:

- **Isolation**: Flutter module contains all camera logic, SwiftUI host remains native
- **Abstraction**: Protocol-based camera source design for future extensibility
- **Validation**: Frame extraction capability for downstream AI integration (Gemini)
- **Documentation**: All patterns captured for SciSymbioLens Phase 4 reuse

---

## 2. High-Level Architecture

### 2.1 System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           iOS Device (iOS 17+)                              │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    SwiftUI Host App (Phase 2)                         │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │                   CameraSourceProtocol                          │  │  │
│  │  │      connect() | disconnect() | startStream() | stopStream()    │  │  │
│  │  └──────────────────────────┬──────────────────────────────────────┘  │  │
│  │                             │                                          │  │
│  │  ┌──────────────────────────┴──────────────────────────────────────┐  │  │
│  │  │               VeepaCameraSource (Implementation)                │  │  │
│  │  │                                                                 │  │  │
│  │  │   ┌─────────────────────────────────────────────────────────┐   │  │  │
│  │  │   │              Platform Bridge (Swift Side)               │   │  │  │
│  │  │   │                                                         │   │  │  │
│  │  │   │  MethodChannel ────────────────────► Flutter            │   │  │  │
│  │  │   │  (Swift → Dart)        connect(), setPTZ()              │   │  │  │
│  │  │   │                                                         │   │  │  │
│  │  │   │  EventChannel  ◄──────────────────── Flutter            │   │  │  │
│  │  │   │  (Dart → Swift)        state, frameRate                 │   │  │  │
│  │  │   └─────────────────────────────────────────────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│  ┌─────────────────────────────────┴─────────────────────────────────────┐  │
│  │                    Flutter Module (Embedded)                          │  │
│  │                                                                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  Discovery  │  │ Connection  │  │   Player    │  │     PTZ     │  │  │
│  │  │   Service   │  │   Manager   │  │   Service   │  │   Service   │  │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │  │
│  │         │                │                │                │         │  │
│  │  ┌──────┴────────────────┴────────────────┴────────────────┴──────┐  │  │
│  │  │                    Veepa SDK Wrapper                           │  │  │
│  │  │   CameraDevice | AppPlayerController | AppP2PApi               │  │  │
│  │  └────────────────────────────┬───────────────────────────────────┘  │  │
│  │                               │                                       │  │
│  │  ┌────────────────────────────┴───────────────────────────────────┐  │  │
│  │  │                  Native Layer (libVSTC.a)                      │  │  │
│  │  │              FFI Bridge | Video Decoding | P2P Protocol        │  │  │
│  │  └────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ P2P Connection (Wi-Fi)
                                      ▼
                            ┌─────────────────┐
                            │  Veepa Camera   │
                            │   (IP Camera)   │
                            └─────────────────┘
```

### 2.2 Architecture Principles

| Principle | Description | Rationale |
|-----------|-------------|-----------|
| **Layer Isolation** | Each layer only knows about the layer directly below it | Enables testing, reduces coupling |
| **Protocol-First** | Define protocols/interfaces before implementations | Supports mocking, future extensibility |
| **State Machines** | All services use explicit state machines | Predictable behavior, testable transitions |
| **Error Boundaries** | Each service handles its own errors | Prevents cascading failures |
| **Observable State** | Services expose state via streams/callbacks | Enables reactive UI, logging |

---

## 3. Technology Stack

### 3.1 Phase 1: Flutter Module

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **Language** | Dart | >=2.17.0 | Primary language |
| **Framework** | Flutter | >=3.0.0 | UI and SDK integration |
| **Camera SDK** | Veepa SDK | N/A | Camera control and streaming |
| **State Management** | ChangeNotifier | Flutter | Simple observable services |
| **Networking** | SDK P2P API | N/A | Camera connection |
| **Testing** | flutter_test | Flutter | Unit and widget tests |

### 3.2 Phase 2: SwiftUI Host

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **Language** | Swift | 5.9+ | Primary language |
| **Framework** | SwiftUI | iOS 17+ | UI framework |
| **Integration** | Flutter Add-to-App | N/A | Embed Flutter module |
| **Bridge** | Platform Channels | Flutter | Swift ↔ Dart communication |
| **Project Gen** | XcodeGen | Latest | Project file generation |
| **Testing** | XCTest | Xcode | Unit and UI tests |

### 3.3 Critical Dependencies

| Dependency | Source | Size | Notes |
|------------|--------|------|-------|
| `libVSTC.a` | Veepa SDK | 24.6 MB | **arm64 only** - no simulator support |
| `app_p2p_api.dart` | Veepa SDK | ~11 KB | P2P connection management |
| `app_player.dart` | Veepa SDK | ~31 KB | Video player with FFI |
| `camera_device/` | Veepa SDK | Multiple | Device and command classes |

---

## 4. Component Architecture

### 4.1 Flutter Module Components

```
flutter_veepa_module/
├── lib/
│   ├── main.dart                    # Entry point (Phase 1 standalone)
│   │
│   ├── services/                    # Business Logic Layer
│   │   ├── veepa_sdk_manager.dart   # SDK initialization
│   │   ├── veepa_discovery_service.dart  # Camera discovery
│   │   ├── veepa_connection_manager.dart # Connection lifecycle
│   │   ├── veepa_player_service.dart     # Video playback
│   │   ├── veepa_ptz_service.dart        # PTZ controls
│   │   ├── frame_extraction_service.dart # Raw frame access
│   │   └── disconnection_handler.dart    # Disconnect recovery
│   │
│   ├── models/                      # Data Models
│   │   ├── discovered_device.dart   # Camera device info
│   │   ├── connection_state.dart    # Connection states
│   │   ├── player_state.dart        # Player states
│   │   └── extracted_frame.dart     # Frame data model
│   │
│   ├── screens/                     # UI Screens
│   │   ├── discovery_screen.dart    # Camera list
│   │   ├── connection_screen.dart   # Connection status
│   │   └── video_screen.dart        # Video + controls
│   │
│   ├── widgets/                     # Reusable UI Components
│   │   ├── camera_list_item.dart
│   │   ├── connection_status.dart
│   │   ├── ptz_controls.dart
│   │   ├── video_error_widget.dart
│   │   └── disconnection_overlay.dart
│   │
│   ├── platform/                    # Platform Channel (Phase 2)
│   │   ├── camera_method_channel.dart  # Receives Swift calls
│   │   └── camera_event_channel.dart   # Sends events to Swift
│   │
│   └── sdk/                         # Veepa SDK (copied)
│       ├── veepa_sdk.dart           # Export file
│       ├── app_p2p_api.dart
│       ├── app_player.dart
│       └── camera_device/
│
└── test/                            # Tests
    ├── services/
    ├── models/
    └── widgets/
```

### 4.2 iOS Host Components (Phase 2)

```
ios_host_app/
├── VeepaPOC/
│   ├── App/
│   │   ├── VeepaPOCApp.swift        # App entry point
│   │   └── AppDelegate.swift        # Flutter engine init
│   │
│   ├── Views/
│   │   ├── ContentView.swift        # Main view
│   │   └── FlutterContainerView.swift # Flutter wrapper
│   │
│   ├── Services/
│   │   ├── FlutterEngineManager.swift # Engine lifecycle
│   │   └── CameraEventReceiver.swift  # Event handling
│   │
│   ├── Protocols/
│   │   └── CameraSourceProtocol.swift # Abstract camera interface
│   │
│   └── Bridge/
│       └── VeepaCameraChannel.swift   # Method channel calls
│
└── project.yml                      # XcodeGen config
```

---

## 5. Service Layer Architecture

### 5.1 Service Dependency Graph

```
                    ┌─────────────────────┐
                    │  VeepaSDKManager    │
                    │  (Singleton)        │
                    │  - initialize()     │
                    │  - state: SDKState  │
                    └──────────┬──────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ VeepaDiscovery   │ │ VeepaConnection  │ │ VeepaPTZService  │
│ Service          │ │ Manager          │ │                  │
│                  │ │                  │ │ - startMove()    │
│ - startScan()    │ │ - connect()      │ │ - stopMove()     │
│ - stopScan()     │ │ - disconnect()   │ │ - direction      │
│ - devices[]      │ │ - state          │ │ - speed          │
└──────────────────┘ └────────┬─────────┘ └──────────────────┘
                              │
                              │ requires connected state
                              ▼
                    ┌──────────────────┐
                    │ VeepaPlayer      │
                    │ Service          │
                    │                  │
                    │ - start()        │
                    │ - stop()         │
                    │ - state          │
                    │ - textureId      │
                    └────────┬─────────┘
                             │
                             │ provides texture
                             ▼
                    ┌──────────────────┐
                    │ FrameExtraction  │
                    │ Service          │
                    │                  │
                    │ - startExtract() │
                    │ - stopExtract()  │
                    │ - frameStream    │
                    └──────────────────┘
```

### 5.2 State Machines

#### SDK Initialization States

```
                    ┌─────────────────┐
                    │  Uninitialized  │
                    └────────┬────────┘
                             │ initialize()
                             ▼
                    ┌─────────────────┐
                    │  Initializing   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │ success                      │ failure
              ▼                              ▼
    ┌─────────────────┐            ┌─────────────────┐
    │   Initialized   │            │     Failed      │
    │   (Ready)       │            │                 │
    └─────────────────┘            └────────┬────────┘
                                            │ retry
                                            └──► Uninitialized
```

#### Connection States

```
    ┌─────────────────┐
    │  Disconnected   │◄────────────────────────────────┐
    └────────┬────────┘                                  │
             │ connect()                                 │
             ▼                                           │
    ┌─────────────────┐                                  │
    │   Connecting    │──────────────────┐               │
    └────────┬────────┘                  │               │
             │ success                    │ timeout/     │
             ▼                           │ error        │
    ┌─────────────────┐                  │               │
    │    Connected    │                  │               │
    └────────┬────────┘                  │               │
             │ connection lost           │               │
             ▼                           │               │
    ┌─────────────────┐                  │               │
    │  Reconnecting   │──────────────────┤               │
    │  (auto retry)   │                  │               │
    └────────┬────────┘                  │               │
             │ max retries               ▼               │
             │                  ┌─────────────────┐      │
             └─────────────────►│     Error       │──────┘
                                └─────────────────┘
                                         │ disconnect()
                                         └──► Disconnected
```

#### Player States

```
    ┌─────────────────┐
    │    Stopped      │◄───────────────────┐
    └────────┬────────┘                     │
             │ start()                      │
             ▼                              │
    ┌─────────────────┐                     │
    │   Buffering     │                     │
    └────────┬────────┘                     │
             │ frames available             │
             ▼                              │ stop()
    ┌─────────────────┐                     │
    │    Playing      │─────────────────────┤
    └────────┬────────┘                     │
             │ error                        │
             ▼                              │
    ┌─────────────────┐                     │
    │     Error       │─────────────────────┘
    └─────────────────┘
```

---

## 6. Data Flow Architecture

### 6.1 Video Frame Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Video Frame Journey                            │
└─────────────────────────────────────────────────────────────────────────┘

1. CAMERA CAPTURE
   ┌─────────────┐
   │ Veepa       │ H.264/H.265 encoded frames
   │ Camera      │─────────────────────────────────►
   └─────────────┘

2. P2P TRANSPORT
   ┌─────────────┐
   │ P2P Layer   │ Encrypted via proprietary protocol
   │ (libVSTC)   │─────────────────────────────────►
   └─────────────┘

3. DECODE (Native)
   ┌─────────────┐
   │ FFI/Native  │ Hardware decode → YUV/RGB buffer
   │ Decoder     │─────────────────────────────────►
   └─────────────┘

4. TEXTURE RENDER (Flutter)
   ┌─────────────┐
   │ AppPlayer   │ Renders to Flutter Texture
   │ Controller  │─────────────────────────────────►
   └─────────────┘

5. DISPLAY (Flutter UI)
   ┌─────────────┐
   │ Texture     │ Displays on screen
   │ Widget      │─────────────────────────────────►
   └─────────────┘

6. FRAME EXTRACTION (Optional)
   ┌─────────────┐
   │ Frame       │ Extract to Uint8List for AI
   │ Extraction  │─────────────────────────────────►
   └─────────────┘

7. PLATFORM CHANNEL (Phase 2)
   ┌─────────────┐
   │ Event       │ Status/metrics to Swift
   │ Channel     │ (NOT raw frames - too slow)
   └─────────────┘
```

### 6.2 Command Flow (PTZ Example)

```
Phase 1 (Flutter Only):
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  User    │───►│  PTZ     │───►│  Camera  │───►│  Veepa   │
│  Tap     │    │  Service │    │  Device  │    │  Camera  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘

Phase 2 (SwiftUI → Flutter):
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  SwiftUI │───►│  Method  │───►│  Dart    │───►│  Camera  │───►│  Veepa   │
│  Button  │    │  Channel │    │  Handler │    │  Device  │    │  Camera  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

---

## 7. Platform Channel Design

### 7.1 Channel Names

| Channel | Type | Direction | Purpose |
|---------|------|-----------|---------|
| `com.veepapoc/camera` | MethodChannel | Swift → Dart | Commands (connect, PTZ) |
| `com.veepapoc/camera_events` | MethodChannel | Dart → Swift | Status events |

### 7.2 Method Channel API (Swift → Dart)

```dart
// Channel: com.veepapoc/camera

// Connect to camera
{
  "method": "connect",
  "arguments": {
    "deviceId": "string",      // Camera ID or IP
    "password": "string?"      // Optional password
  }
}
// Returns: void or FlutterError

// Disconnect from camera
{
  "method": "disconnect",
  "arguments": null
}
// Returns: void

// PTZ Control
{
  "method": "setPTZ",
  "arguments": {
    "direction": "string",     // up|down|left|right|stop
    "speed": "int"             // 1-10
  }
}
// Returns: void or FlutterError

// Get current state
{
  "method": "getState",
  "arguments": null
}
// Returns: {
//   "connectionState": "string",
//   "playerState": "string",
//   "frameRate": "double",
//   "isConnected": "bool"
// }
```

### 7.3 Event Channel API (Dart → Swift)

```dart
// Channel: com.veepapoc/camera_events_out

// Connection state change
{
  "type": "connectionState",
  "state": "connected|disconnected|connecting|error",
  "timestamp": 1234567890
}

// Player state change
{
  "type": "playerState",
  "state": "playing|stopped|buffering|error",
  "timestamp": 1234567890
}

// Frame rate update
{
  "type": "frameRate",
  "fps": 24.5,
  "timestamp": 1234567890
}

// Error event
{
  "type": "error",
  "message": "Error description",
  "code": "ERROR_CODE",
  "timestamp": 1234567890
}
```

### 7.4 Important: Frame Data Transfer

**EventChannel is NOT suitable for raw video frames.**

For future frame extraction to Swift (e.g., for Gemini API):

| Approach | Performance | Complexity | Recommendation |
|----------|-------------|------------|----------------|
| EventChannel | Poor (serialization) | Low | Status only |
| FFI Shared Memory | Excellent | High | Large frames |
| Platform Texture | Good | Medium | If supported |
| Native Processing | Excellent | High | Process in native |

**Current design**: Extract frames in Flutter, process in Flutter. If Swift needs frames, use FFI.

---

## 8. Error Handling Strategy

### 8.1 Error Categories

| Category | Examples | Handling |
|----------|----------|----------|
| **SDK Errors** | Init failure, API errors | Log + user message + retry option |
| **Connection Errors** | Timeout, network loss | Auto-reconnect (3 attempts) |
| **Video Errors** | Decode failure, stream end | Display error widget + retry |
| **Platform Errors** | Channel failure | Fallback + log |

### 8.2 Error Flow

```dart
// All services follow this pattern:

class ServiceError {
  final String code;
  final String message;
  final String userMessage;
  final bool isRecoverable;
  final dynamic originalError;
}

// Services expose errors via stream:
Stream<ServiceError> get errorStream;

// UI subscribes and displays appropriate message:
errorStream.listen((error) {
  if (error.isRecoverable) {
    showRetryDialog(error.userMessage);
  } else {
    showErrorScreen(error.userMessage);
  }
});
```

---

## 9. Testing Architecture

### 9.1 Test Pyramid

```
                    ┌───────────────┐
                    │   E2E Tests   │  Manual (device required)
                    │   (Device)    │  Full flow with real camera
                    └───────────────┘
                   ╱                 ╲
          ┌───────────────────────────────┐
          │       Integration Tests       │  Semi-automated
          │   (Mocked SDK, real services) │  Service interactions
          └───────────────────────────────┘
         ╱                                 ╲
┌─────────────────────────────────────────────────┐
│                   Unit Tests                    │  Automated
│  Services (mocked deps) | Models | Widgets      │  CI-friendly
└─────────────────────────────────────────────────┘
```

### 9.2 Test Environment Matrix

| Test Type | Simulator | Physical Device |
|-----------|-----------|-----------------|
| Unit Tests (pure logic) | Yes | Yes |
| Widget Tests | Yes | Yes |
| SDK Integration | **No** (arm64 only) | **Required** |
| Camera Connection | No | **Required** |
| Video Streaming | No | **Required** |
| Platform Channel | No | **Required** |

### 9.3 Mocking Strategy

```dart
// Protocol-based mocking for services
abstract class VeepaConnectionManagerProtocol {
  ConnectionState get state;
  Stream<ConnectionState> get stateStream;
  Future<void> connect(DiscoveredDevice device);
  Future<void> disconnect();
}

// Real implementation
class VeepaConnectionManager implements VeepaConnectionManagerProtocol { ... }

// Mock for testing
class MockConnectionManager implements VeepaConnectionManagerProtocol {
  ConnectionState _state = ConnectionState.disconnected;
  // ... test-controlled behavior
}
```

---

## 10. Security Considerations

### 10.1 Credentials

| Item | Storage | Notes |
|------|---------|-------|
| Camera password | iOS Keychain (Phase 2) | Encrypted at rest |
| Last used IP | SharedPreferences | Non-sensitive |
| Device ID | Memory only | Not persisted |

### 10.2 Network Security

- P2P connection uses Veepa's proprietary encryption
- All communication on local network (no cloud in POC)
- No external API calls except to camera

### 10.3 Code Security

- No hardcoded credentials
- SDK files not committed to public repos
- Native library (`libVSTC.a`) is vendor proprietary

---

## 11. Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| SDK Initialization | < 1 second | Timer in service |
| Camera Discovery | < 5 seconds | Timer in service |
| P2P Connection | < 10 seconds | Timer in service |
| First Frame Display | < 5 seconds | Timer from connect |
| Video Frame Rate | >= 15 FPS | FPS counter |
| PTZ Command Latency | < 500ms | Round-trip timer |
| Frame Extraction | >= 5 FPS | Extraction service |
| Memory (video playing) | < 200 MB | Xcode profiler |

---

## 12. Project Structure

### 12.1 Repository Layout

```
VeepaCameraPOC/
├── .bmad-core/                    # BMAD methodology files
├── .ralph/                        # RALPH automation
├── .claude/                       # Claude Code config
│
├── docs/
│   ├── brief.md                   # Project brief
│   ├── prd.md                     # Product requirements
│   ├── architecture.md            # This document
│   ├── LEARNINGS.md               # Integration learnings
│   ├── feedback_for_veepa_poc.md  # AI validation feedback
│   └── stories/                   # User stories
│       ├── README.md
│       ├── epic-1/                # Project Setup
│       ├── epic-2/                # Camera Discovery
│       ├── epic-3/                # Camera Connection
│       ├── epic-4/                # Video Streaming
│       ├── epic-5/                # PTZ Controls
│       ├── epic-6/                # SwiftUI Host (Phase 2)
│       ├── epic-7/                # Flutter Embedding (Phase 2)
│       ├── epic-8/                # Platform Bridge (Phase 2)
│       └── epic-9/                # Integration Testing (Phase 2)
│
├── flutter_veepa_module/          # Flutter Module (Phase 1)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── platform/
│   │   └── sdk/                   # Veepa SDK (copied)
│   ├── test/
│   ├── pubspec.yaml
│   └── .ios/                      # iOS build config
│
├── ios_host_app/                  # SwiftUI Host (Phase 2)
│   ├── VeepaPOC/
│   │   ├── App/
│   │   ├── Views/
│   │   ├── Services/
│   │   ├── Protocols/
│   │   └── Bridge/
│   ├── project.yml                # XcodeGen
│   └── Podfile
│
├── CLAUDE.md                      # Development instructions
└── README.md                      # Project overview
```

---

## 13. Development Workflow

### 13.1 Story Execution Order

```
Phase 1: Flutter POC
├── Epic 1: Project Setup
│   ├── Story 1.1: Initialize Flutter Project
│   ├── Story 1.2: Add Veepa SDK Dependencies
│   └── Story 1.3: Verify SDK Initialization
├── Epic 2: Camera Discovery
│   ├── Story 2.1: Device Discovery Service
│   ├── Story 2.2: Discovery UI
│   └── Story 2.3: Manual IP Entry
├── Epic 3: Camera Connection
│   ├── Story 3.1: Connection Manager
│   ├── Story 3.2: Connection UI
│   └── Story 3.3: Handle Disconnection
├── Epic 4: Video Streaming
│   ├── Story 4.1: Video Player Service
│   ├── Story 4.2: Video Display UI
│   ├── Story 4.3: Handle Video Errors
│   └── Story 4.4: Frame Extraction ← CRITICAL
└── Epic 5: PTZ Controls
    ├── Story 5.1: PTZ Command Service
    └── Story 5.2: PTZ Control UI

Phase 2: Flutter Add-to-App
├── Epic 6: SwiftUI Host Setup
├── Epic 7: Flutter Embedding
├── Epic 8: Platform Bridge
└── Epic 9: Integration Testing
```

### 13.2 Commit Convention

```
feat(epic-N): Description - Story N.X

Examples:
- feat(epic-1): Initialize Flutter project - Story 1.1
- feat(epic-4): Frame extraction prototype - Story 4.4
- fix(epic-3): Connection timeout handling
- docs(epic-9): Document learnings
```

---

## 14. Key Design Decisions

### 14.1 Decision Log

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| Integration approach | Native, Pure Flutter, Add-to-App | **Flutter Add-to-App** | SDK is Flutter-based, preserves SwiftUI |
| State management | Riverpod, BLoC, ChangeNotifier | **ChangeNotifier** | Simple, sufficient for POC |
| Project generation | Manual, XcodeGen | **XcodeGen** | Reproducible builds |
| Platform channel | MethodChannel, Pigeon | **MethodChannel** | Simpler for POC scope |
| Frame extraction | Native, Flutter | **Flutter first** | Validate SDK capabilities first |

### 14.2 Architecture Tradeoffs

| Tradeoff | Choice | Impact |
|----------|--------|--------|
| Singleton services | Yes | Simpler code, harder to test |
| arm64-only SDK | Accept | No simulator testing |
| EventChannel for status only | Yes | FFI needed for frame data |

---

## 15. Future Considerations

### 15.1 SciSymbioLens Integration

When porting to SciSymbioLens:

1. **Copy Flutter module** as-is
2. **Implement CameraSourceProtocol** for both local and Veepa cameras
3. **Add camera source switcher** in UI
4. **Integrate frame extraction** with Gemini API pipeline

### 15.2 Extensibility Points

| Extension | Preparation |
|-----------|-------------|
| Multiple camera brands | CameraSourceProtocol abstraction |
| Background streaming | AppLifecycleState handling in Story 3.3 |
| Recording | Not in POC, but SDK supports it |
| Cloud upload | Not in POC scope |

---

## 16. Appendix

### A. SDK Reference

- **SDK Analysis**: `/Users/mpriessner/windsurf_repos/Veepaisdk/SDK_ANALYSIS.md`
- **Native Library**: `/Users/mpriessner/windsurf_repos/Veepaisdk/ios库/libVSTC.a`
- **Flutter SDK**: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/`

### B. Related Documents

- [Project Brief](brief.md)
- [Product Requirements](prd.md)
- [Story Files](stories/)
- [Integration Learnings](LEARNINGS.md)

### C. External References

- [Flutter Add-to-App](https://docs.flutter.dev/add-to-app)
- [Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [SwiftUI + Flutter](https://docs.flutter.dev/add-to-app/ios/add-flutter-screen)

---

*Generated using BMAD Architecture methodology*
