# Story 7.2: Create Flutter Container View

> **Epic**: 7 - Flutter Embedding (Phase 2)
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** user,
**I want** to see the Flutter camera view within the native app,
**So that** I can use the external camera seamlessly.

---

## Acceptance Criteria

- [ ] AC1: SwiftUI view wraps Flutter view controller
- [ ] AC2: Full-screen Flutter camera display
- [ ] AC3: Native button to dismiss Flutter view
- [ ] AC4: Smooth enter/exit transitions
- [ ] AC5: Memory properly managed on dismiss
- [ ] AC6: Status bar handled correctly

---

## Technical Specification

### FlutterContainerView

Create `ios_host_app/VeepaPOC/Views/FlutterContainerView.swift`:

```swift
import SwiftUI
import Flutter

/// SwiftUI wrapper for Flutter view controller
struct FlutterContainerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> FlutterViewController {
        guard let vc = FlutterEngineManager.shared.getViewController() else {
            fatalError("Flutter engine not initialized")
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {
        // Handle updates if needed
    }
}

/// Full screen Flutter camera view with dismiss capability
struct FlutterCameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            // Flutter content
            FlutterContainerView(onDismiss: { dismiss() })
                .ignoresSafeArea()

            // Native overlay with dismiss button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}
```

### Updated ContentView

```swift
struct ContentView: View {
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            VStack {
                // ... existing content

                Button("Open Camera") {
                    showingCamera = true
                }
                .buttonStyle(.borderedProminent)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                FlutterCameraView()
            }
        }
    }
}
```

---

## Test Cases

### TC7.2.1: Flutter View Displays
**Type**: Manual
**Priority**: P0

**Steps**:
1. Launch app
2. Tap "Open Camera"
3. Verify Flutter view appears

### TC7.2.2: Dismiss Works
**Type**: Manual
**Priority**: P0

**Steps**:
1. Open Flutter view
2. Tap dismiss button
3. Verify return to native view

---

## Definition of Done

- [ ] Flutter view displays correctly
- [ ] Dismiss works smoothly
- [ ] No memory leaks
- [ ] Code committed with message: "feat(epic-7): Flutter container view - Story 7.2"
