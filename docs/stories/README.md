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

## Execution Order

Execute stories sequentially within each epic:

```
Epic 1 (Setup) → Epic 2 (Discovery) → Epic 3 (Connection) → Epic 4 (Video) → Epic 5 (PTZ)
                                    ↓
                            Phase 1 Complete
                                    ↓
Epic 6 (Host) → Epic 7 (Embedding) → Epic 8 (Bridge) → Epic 9 (Testing)
                                    ↓
                            Phase 2 Complete
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
