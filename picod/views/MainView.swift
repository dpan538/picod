//
//  MainView.swift
//  picod
//

import Combine
import SwiftUI

struct MainView: View {
    @StateObject private var camera = CameraManager()
    @State private var cameraAllowed = false
    @State private var permissionDenied = false
    @State private var result: CaptureResult?

    var body: some View {
        NavigationStack {
            Group {
                if let result {
                    resultView(result)
                } else if cameraAllowed, camera.isConfigured, camera.setupError == nil {
                    CameraView(
                        camera: camera,
                        statusLine: "DAY 001 · CYCLE 01",
                        onCancel: {
                            camera.stopSession()
                        },
                        onCapture: { image in
                            camera.stopSession()
                            let pixelated = PixelProcessor.pixelate(image: image)
                            self.result = CaptureResult(original: image, pixelated: pixelated)
                        }
                    )
                } else if permissionDenied || camera.setupError != nil {
                    permissionOrErrorView
                } else {
                    ProgressView("准备相机…")
                }
            }
            .navigationTitle("picod")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let ok = await CameraPermission.requestIfNeeded()
                if ok {
                    cameraAllowed = true
                    camera.configureSession()
                } else {
                    permissionDenied = true
                }
            }
            .onChange(of: camera.isConfigured) { _, configured in
                guard configured, camera.setupError == nil, result == nil else { return }
                camera.startSession()
            }
        }
    }

    private var permissionOrErrorView: some View {
        VStack(spacing: 16) {
            if let message = camera.setupError {
                Text(message)
                    .multilineTextAlignment(.center)
            } else {
                Text("需要相机权限才能拍照。")
                    .multilineTextAlignment(.center)
            }
            Button("重试") {
                Task {
                    let ok = await CameraPermission.requestIfNeeded()
                    permissionDenied = !ok
                    if ok {
                        cameraAllowed = true
                        camera.configureSession()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func resultView(_ result: CaptureResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                labeledImage(title: "原图", image: result.original)
                labeledImage(title: "50×50 像素化", image: result.pixelated)

                Button("再拍一张") {
                    self.result = nil
                    camera.startSession()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    private func labeledImage(title: String, image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    MainView()
}
