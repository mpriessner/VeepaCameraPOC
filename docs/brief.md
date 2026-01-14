# Project Brief: VeepaCameraPOC

> **Status**: Draft v1.0
> **Created**: 2025-01-14
> **Method**: BMAD Interactive Elicitation
> **Parent Project**: SciSymbioLens (Phase 4 preparation)

---

## Executive Summary

**VeepaCameraPOC** is a proof-of-concept Flutter application designed to validate the integration of Veepa IP cameras with iOS applications. This POC will establish patterns and learnings for integrating external Wi-Fi cameras into the SciSymbioLens iOS app (Phase 4).

**Primary Problem**: The Veepa SDK is Flutter-based while SciSymbioLens is a native SwiftUI app. We need to prove that Flutter Add-to-App can successfully bridge these worlds and enable live video streaming from Veepa cameras.

**Key Value Proposition**: De-risk the SciSymbioLens Phase 4 implementation by isolating and solving the external camera integration challenges in a dedicated POC environment.

---

## Problem Statement

### Current Pain Points

1. **SDK Framework Mismatch**: Veepa SDK is designed for Flutter, SciSymbioLens is native SwiftUI
2. **Undocumented Native APIs**: The native iOS library (`libVSTC.a`) has no usable headers for direct Swift integration
3. **Proprietary Protocol**: Veepa uses a custom P2P protocol, not standard RTSP/ONVIF
4. **Chinese Documentation**: Most SDK documentation is in Chinese, requiring reverse engineering
5. **Integration Uncertainty**: No proven path exists for SwiftUI ↔ Flutter ↔ Veepa camera data flow

### Why Existing Solutions Fall Short

- **Direct Native Integration**: Headers are Flutter plugin declarations, not usable C/Objective-C APIs
- **RTSP/ONVIF Alternatives**: Veepa cameras don't support standard streaming protocols
- **Pure Flutter Rewrite**: Would abandon all existing SciSymbioLens SwiftUI work

### Urgency

**High** - SciSymbioLens Phase 4 depends on external camera support. Validating this now prevents costly surprises later.

---

## Proposed Solution

A two-phase proof-of-concept approach:

### Phase 1: Pure Flutter Validation
1. Create a minimal Flutter app using the Veepa SDK
2. Prove we can discover, connect to, and stream from a Veepa camera
3. Validate PTZ controls and basic camera operations
4. Document the SDK's actual behavior and quirks

### Phase 2: Flutter Add-to-App Integration
1. Create a minimal SwiftUI host app
2. Embed the Flutter module from Phase 1
3. Establish Platform Channels for video frame transfer
4. Prove end-to-end video flow: Veepa Camera → Flutter → Swift

### Key Differentiators from Alternative Approaches

| Approach | Risk Level | Why We Chose Flutter Add-to-App |
|----------|------------|--------------------------------|
| Pure Native (reverse engineer) | High | No headers, undocumented APIs, high crash risk |
| Flutter Add-to-App | Medium | Uses SDK as intended, documented path |
| Full Flutter Rewrite | Low | Loses all existing SwiftUI work |

---

## Target Users

### Primary User Segment: Development Team

- **Profile**: Developers working on SciSymbioLens
- **Technical Level**: Advanced (iOS/Swift, Flutter/Dart)
- **Current Workflow**: Native SwiftUI development
- **Pain Points**: Need to integrate external camera without rewriting app
- **Goals**:
  - Validate Flutter Add-to-App integration pattern
  - Create reusable templates for SciSymbioLens
  - Document learnings and pitfalls

### Secondary User Segment: Lab Researchers (End Users)

- **Profile**: Scientists using SciSymbioLens with specialized cameras
- **Technical Level**: General consumer
- **Current Workflow**: Use phone camera only
- **Goals**:
  - Connect external Wi-Fi cameras to AI-powered analysis
  - Get live video from specialized lab equipment

---

## Goals & Success Metrics

### Business Objectives

- **De-risk SciSymbioLens Phase 4**: Validate integration approach before committing
- **Reduce Integration Time**: Create templates and patterns for reuse
- **Knowledge Capture**: Document all learnings for future reference

### Technical Success Metrics

| Metric | Target | Verification |
|--------|--------|-------------|
| Camera Discovery | Works on local network | Manual test with real camera |
| P2P Connection | Establishes within 10 seconds | Automated timing test |
| Live Video Stream | Displays at 15+ FPS | Visual verification |
| PTZ Control | Responds within 500ms | Manual test |
| Platform Channel | Passes video frame data | Unit test |

### Definition of Done (Per Phase)

| Phase | Success Criteria |
|-------|------------------|
| Phase 1 | Flutter app connects to Veepa camera and displays live video |
| Phase 2 | SwiftUI app embeds Flutter module and receives video frames |

---

## MVP Scope

### Phase 1: Pure Flutter POC

**Core Features (Must Have)**:
- [ ] Flutter project with Veepa SDK dependencies
- [ ] Camera discovery on local network (LAN scan)
- [ ] P2P connection establishment
- [ ] Live video stream display
- [ ] Basic PTZ controls (up/down/left/right/zoom)
- [ ] Connection status feedback

**Out of Scope for Phase 1**:
- Recording to local storage
- Cloud upload
- Multiple camera support
- Audio streaming
- Advanced camera settings

### Phase 2: Flutter Add-to-App POC

**Core Features (Must Have)**:
- [ ] Minimal SwiftUI host application
- [ ] Embedded Flutter module
- [ ] Platform Channel for video frames
- [ ] Camera source abstraction protocol
- [ ] Basic UI to switch camera on/off

**Out of Scope for Phase 2**:
- Full SciSymbioLens UI integration
- Gemini AI integration
- Gallery/media management
- Production-ready error handling

### MVP Success Criteria

The POC is successful when:
1. A Veepa camera video stream displays in a SwiftUI view
2. Video frame data can be extracted for processing (simulating Gemini input)
3. The integration pattern is documented and reproducible

---

## Post-MVP Vision

### SciSymbioLens Phase 4 Integration

Once POC is validated:
1. Port Flutter module to SciSymbioLens project
2. Create `CameraSource` protocol with `LocalCameraSource` and `RemoteCameraSource` implementations
3. Update UI to support camera source switching
4. Enable all existing features (recording, AI analysis) with external camera

### Long-term Vision

- Support multiple Veepa camera models
- Support other IP camera brands (if they provide Flutter/native SDKs)
- Enable multi-camera streaming for complex lab setups

---

## Technical Considerations

### Platform Requirements

- **Target Platforms**: iOS 17+ (primary), potentially Android later
- **Flutter Version**: >=3.0.0
- **Dart Version**: >=2.17.0
- **Xcode**: 15.0+

### Technology Stack

| Component | Technology |
|-----------|------------|
| POC App (Phase 1) | Flutter/Dart |
| Host App (Phase 2) | SwiftUI (iOS 17+) |
| Camera SDK | Veepa SDK (libVSTC.a + Flutter plugins) |
| Video Player | SDK's AppPlayerController |
| Connection | SDK's P2P API |
| Integration | Flutter Add-to-App |
| Bridge | Platform Channels (MethodChannel/EventChannel) |

### Architecture Considerations

```
┌─────────────────────────────────────────────────────────────┐
│                  SwiftUI Host App (Phase 2)                 │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              CameraSourceProtocol                      │ │
│  │   (Abstract interface for camera sources)              │ │
│  └──────────────────┬─────────────────────────────────────┘ │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────────┐ │
│  │           FlutterBridge (Platform Channel)             │ │
│  │   - startCamera() / stopCamera()                       │ │
│  │   - onVideoFrame(callback)                             │ │
│  │   - ptzControl(direction)                              │ │
│  └──────────────────┬─────────────────────────────────────┘ │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────────┐ │
│  │           Flutter Module (Veepa SDK)                   │ │
│  │   - CameraDevice connection                            │ │
│  │   - AppPlayerController video                          │ │
│  │   - PTZ commands                                       │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Veepa Camera   │
                    │  (Wi-Fi/P2P)    │
                    └─────────────────┘
```

### Security Considerations

- Camera credentials stored securely (iOS Keychain)
- P2P connection uses vendor's encryption
- No cloud services in POC (all local network)

---

## Constraints & Assumptions

### Constraints

- **Budget**: Personal project, minimal infrastructure costs
- **Timeline**: POC should validate approach within days, not weeks
- **Resources**: Solo development with AI assistance
- **Hardware**: Requires physical Veepa camera for testing

### Key Assumptions

1. User has a Veepa camera available and working
2. Camera is on same local network as development device
3. Veepa SDK works as documented (we'll verify in Phase 1)
4. Flutter Add-to-App works with iOS 17+
5. Platform Channels can handle video frame data efficiently

---

## Risks & Open Questions

### Key Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SDK doesn't work as expected | High | Medium | Phase 1 validates this first |
| Platform Channel latency too high | Medium | Low | Test with frame rate metrics |
| Flutter Add-to-App conflicts | Medium | Low | Use isolated module pattern |
| Camera P2P connection unstable | Medium | Medium | Implement reconnection logic |

### Open Questions

1. What is the actual frame format from the SDK? (RGB, YUV, encoded?)
2. Can we extract raw frames without rendering first?
3. What's the memory overhead of Flutter Add-to-App?
4. Does the SDK support background connection?

### Areas Needing Research

- Flutter Add-to-App best practices for video streaming
- Platform Channel optimization for high-frequency data
- iOS memory management with embedded Flutter

---

## Appendices

### A. Related Projects

- **SciSymbioLens**: Parent project that will receive this integration
- **Veepaisdk**: Source SDK repository at `/Users/mpriessner/windsurf_repos/Veepaisdk`

### B. Key SDK Files

| File | Purpose |
|------|---------|
| `flutter-sdk-demo/lib/app_p2p_api.dart` | P2P connection API |
| `flutter-sdk-demo/lib/app_player.dart` | Video player controller |
| `flutter-sdk-demo/lib/camera_device/` | Camera device management |
| `ios库/libVSTC.a` | Native iOS static library |

### C. References

- [Flutter Add-to-App Documentation](https://docs.flutter.dev/add-to-app)
- [Platform Channels Guide](https://docs.flutter.dev/platform-integration/platform-channels)
- SciSymbioLens PRD: `/Users/mpriessner/windsurf_repos/SciSymbioLens/docs/prd.md`

---

## Next Steps

1. **Create PRD** - Detailed requirements with epics and stories
2. **Set up Flutter project** - Initialize with Veepa SDK dependencies
3. **Implement Phase 1** - Prove camera connection works
4. **Document learnings** - Capture everything for SciSymbioLens integration
5. **Implement Phase 2** - Prove Flutter Add-to-App pattern works

---

*Generated using BMAD methodology*
