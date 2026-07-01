import AVFoundation
import Combine
import UIKit

final class CameraManager: NSObject, ObservableObject {
    @Published private(set) var isConfigured = false
    @Published private(set) var setupError: String?

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "picod.camera.session")
    private var captureCompletion: ((UIImage?) -> Void)?

    func configureSession() {
        setupError = nil

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isConfigured else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            defer { self.session.commitConfiguration() }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.publishConfigurationFailure("Camera device is unavailable.")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.session.canAddInput(input) else {
                    self.publishConfigurationFailure("Camera input cannot be attached.")
                    return
                }
                self.session.addInput(input)
            } catch {
                self.publishConfigurationFailure(error.localizedDescription)
                return
            }

            guard self.session.canAddOutput(self.photoOutput) else {
                self.publishConfigurationFailure("Camera output cannot be attached.")
                return
            }
            self.session.addOutput(self.photoOutput)

            DispatchQueue.main.async {
                self.isConfigured = true
                self.setupError = nil
            }
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard isConfigured else {
            completion(nil)
            return
        }

        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func publishConfigurationFailure(_ message: String) {
        DispatchQueue.main.async {
            self.isConfigured = false
            self.setupError = message
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image: UIImage?
        if error == nil, let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        } else {
            image = nil
        }

        DispatchQueue.main.async {
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}
