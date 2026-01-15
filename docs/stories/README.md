# VeepaCameraPOC - User Stories Index

## Phase 1: Pure Flutter POC

### Epic 1: Project Setup
| Story | Title | Status |
|-------|-------|--------|
| 1.1 | [Initialize Flutter Project](epic-1/story-1.1-initialize-flutter-project.md) | Draft |
| 1.2 | [Add Veepa SDK Dependencies](epic-1/story-1.2-add-veepa-sdk.md) | Draft |
| 1.3 | Verify SDK Initialization | Planned |

### Epic 2: Camera Discovery
| Story | Title | Status |
|-------|-------|--------|
| 2.1 | Implement Device Discovery Service | Planned |
| 2.2 | Create Discovery UI | Planned |
| 2.3 | Manual IP Entry | Planned |

### Epic 3: Camera Connection
| Story | Title | Status |
|-------|-------|--------|
| 3.1 | Implement Connection Manager | Planned |
| 3.2 | Connection UI and Status | Planned |
| 3.3 | Handle Disconnection | Planned |

### Epic 4: Video Streaming
| Story | Title | Status |
|-------|-------|--------|
| 4.1 | Implement Video Player Service | Planned |
| 4.2 | Video Display UI | Planned |
| 4.3 | Handle Video Errors | Planned |

### Epic 5: PTZ Controls
| Story | Title | Status |
|-------|-------|--------|
| 5.1 | Implement PTZ Command Service | Planned |
| 5.2 | PTZ Control UI | Planned |

---

## Phase 2: Flutter Add-to-App

### Epic 6: SwiftUI Host Setup
| Story | Title | Status |
|-------|-------|--------|
| 6.1 | Initialize SwiftUI Project | Planned |
| 6.2 | Define Camera Source Protocol | Planned |

### Epic 7: Flutter Embedding
| Story | Title | Status |
|-------|-------|--------|
| 7.1 | Configure Flutter Add-to-App | Planned |
| 7.2 | Create Flutter Container View | Planned |

### Epic 8: Platform Bridge
| Story | Title | Status |
|-------|-------|--------|
| 8.1 | Implement Method Channel | Planned |
| 8.2 | Implement Event Channel | Planned |

### Epic 9: Integration Testing
| Story | Title | Status |
|-------|-------|--------|
| 9.1 | End-to-End Connection Test | Planned |
| 9.2 | Document Learnings | Planned |

---

## Phase 3: Real Camera Integration

### Epic 10: QR Code Scanning
| Story | Title | Status |
|-------|-------|--------|
| 10.1 | [QR Scanner Service](epic-10/story-10.1-qr-scanner-service.md) | Done |
| 10.2 | [QR Scanner UI](epic-10/story-10.2-qr-scanner-ui.md) | Done |
| 10.3 | [Device Registration](epic-10/story-10.3-device-registration.md) | Done |

### Epic 11: WiFi Provisioning (CGI)
| Story | Title | Status |
|-------|-------|--------|
| 11.1 | [WiFi Discovery Service](epic-11/story-11.1-wifi-discovery-service.md) | Done |
| 11.2 | [AP Connection Flow](epic-11/story-11.2-ap-connection-flow.md) | Done |
| 11.3 | [WiFi Provisioning](epic-11/story-11.3-wifi-provisioning.md) | Done |

### Epic 12: SDK Integration
| Story | Title | Status |
|-------|-------|--------|
| 12.1 | [SDK Integration Service](epic-12/story-12.1-sdk-integration.md) | Done |
| 12.2 | [Real Connection Manager](epic-12/story-12.2-real-connection-manager.md) | Done |
| 12.3 | [Real Video Player](epic-12/story-12.3-real-video-player.md) | Done |
| 12.4 | [Real PTZ Controls](epic-12/story-12.4-real-ptz-controls.md) | Done |

### Epic 13: Hardware Testing
| Story | Title | Status |
|-------|-------|--------|
| 13.1 | [Hardware Test Suite](epic-13/story-13.1-hardware-test-suite.md) | Done |
| 13.2 | [Quality Gate Validation](epic-13/story-13.2-quality-gate-validation.md) | Done |
| 13.3 | [Integration Documentation](epic-13/story-13.3-integration-documentation.md) | Done |

### Epic 14: QR Visual Provisioning
| Story | Title | Status |
|-------|-------|--------|
| 14.1 | [QR Generation Service](epic-14/story-14.1-qr-generation-service.md) | Draft |
| 14.2 | [QR Display UI](epic-14/story-14.2-qr-display-ui.md) | Draft |
| 14.3 | [Camera Connection Detection](epic-14/story-14.3-camera-connection-detection.md) | Draft |
| 14.4 | [Visual Provisioning Flow](epic-14/story-14.4-visual-provisioning-flow.md) | Draft |

---

## Execution Order

Execute stories sequentially within each epic:

```
Phase 1: Pure Flutter POC
Epic 1 (Setup) → Epic 2 (Discovery) → Epic 3 (Connection) → Epic 4 (Video) → Epic 5 (PTZ)
                                    ↓
                            Phase 1 Complete
                                    ↓
Phase 2: Flutter Add-to-App
Epic 6 (Host) → Epic 7 (Embedding) → Epic 8 (Bridge) → Epic 9 (Testing)
                                    ↓
                            Phase 2 Complete
                                    ↓
Phase 3: Real Camera Integration
Epic 10 (QR Scan) → Epic 11 (CGI Provisioning) → Epic 12 (SDK) → Epic 13 (Testing)
                                    ↓
                            Phase 3 Complete
                                    ↓
Phase 3.1: QR Visual Provisioning
Epic 14 (QR Visual) → Story 14.1 → 14.2 → 14.3 → 14.4
                                    ↓
                        QR Provisioning Complete
```

---

## Story Status Legend

| Status | Meaning |
|--------|---------|
| Draft | Story written, not yet approved |
| Approved | Ready for implementation |
| InProgress | Currently being implemented |
| Review | Implementation complete, in QA |
| Done | Verified and complete |
| Planned | Not yet written |
