import SwiftUI

struct ContentView: View {
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "video.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Veepa Camera POC")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("SwiftUI Host Application")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {
                    showingCamera = true
                }) {
                    Label("Launch Camera", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding()
            .navigationTitle("VeepaPOC")
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPlaceholderView()
            }
        }
    }
}

struct CameraPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.gray)

            Text("Camera View Placeholder")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Flutter camera module will be integrated here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
