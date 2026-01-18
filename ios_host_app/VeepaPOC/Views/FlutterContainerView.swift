import SwiftUI
import Flutter

/// SwiftUI wrapper for Flutter view controller
struct FlutterContainerView: UIViewControllerRepresentable {
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        print("[FlutterContainerView] makeUIViewController called")

        // Ensure engine is initialized
        if FlutterEngineManager.shared.engine == nil {
            print("[FlutterContainerView] Engine not initialized, initializing now...")
            FlutterEngineManager.shared.initializeEngine()
        }

        guard let vc = FlutterEngineManager.shared.getViewController() else {
            print("[FlutterContainerView] ERROR: Could not get Flutter view controller")
            // Return a placeholder instead of crashing
            let errorVC = UIViewController()
            errorVC.view.backgroundColor = .systemRed
            let label = UILabel()
            label.text = "Flutter engine failed to initialize"
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            errorVC.view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: errorVC.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: errorVC.view.centerYAnchor)
            ])
            return errorVC
        }

        print("[FlutterContainerView] Returning FlutterViewController")
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
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
