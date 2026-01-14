import SwiftUI
import Flutter

/// SwiftUI wrapper for Flutter view controller
struct FlutterContainerView: UIViewControllerRepresentable {
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

#Preview {
    FlutterCameraView()
}
