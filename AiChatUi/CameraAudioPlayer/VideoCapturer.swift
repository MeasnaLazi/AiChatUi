//
//  VideoCapturer.swift
//  AiChatUi
//
//  Created by Measna on 15/6/25.
//

import AVFoundation
import UIKit

protocol VideoCapturerDelegate: AnyObject {
    func videoCapturer(_ capturer: VideoCapturer, didCaptureFrame data: Data)
}

class VideoCapturer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    weak var delegate: VideoCapturerDelegate?
    
    var session: AVCaptureSession {
        return captureSession
    }
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.example.video.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "com.example.video.output.queue")

    override init() {
        super.init()
        setupCaptureSession()
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.checkPermissionsAndStartRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            print("VideoCapturer: Session stopped.")
        }
    }
    
    func cleanUp() {
        stop()
    }

    private func checkPermissionsAndStartRunning() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if !self.captureSession.isRunning {
                print("VideoCapturer: Starting session...")
                self.captureSession.startRunning()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.checkPermissionsAndStartRunning()
                }
            }
        default:
            print("VideoCapturer: Camera access has been denied or is restricted.")
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
            print("VideoCapturer: FATAL - Could not create camera input.")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
        
        print("VideoCapturer: Session configured successfully in init.")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        guard let jpegData = convertPixelBufferToJPEG(pixelBuffer) else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            if let self {
                self.delegate?.videoCapturer(self, didCaptureFrame: jpegData)
            }
        }
    }
    
    private func convertPixelBufferToJPEG(_ pixelBuffer: CVPixelBuffer) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        return uiImage.jpegData(compressionQuality: 0.7)
    }
}
