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
    private let sessionQueue = DispatchQueue(label: "dev.measna.video.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "dev.measna.video.output.queue")
    
    private var backCamera: AVCaptureDevice!
    private var frontCamera: AVCaptureDevice!
    private var backInput: AVCaptureInput!
    private var frontInput: AVCaptureInput!
    
    private var isBackCamera = true
    private var isTorch = false

    override init() {
        super.init()
        setCameraAndInput()
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
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        captureSession.removeInput(isBackCamera ? backInput : frontInput)
        captureSession.addInput(isBackCamera ? frontInput : backInput)
        isBackCamera = !isBackCamera
        
        captureSession.commitConfiguration()
    }
    
    func switchTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = isTorch ? .off : .on
                isTorch = !isTorch
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
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

        if captureSession.canAddInput(backInput) {
            captureSession.addInput(backInput)
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
    
    private func setCameraAndInput() {
        if let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
             backCamera = cameraDevice
        } else {
             fatalError("VideoCapturer: No back camera")
        }
        if let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
             frontCamera = cameraDevice
        } else {
             fatalError("VideoCapturer: No front camera")
        }
        if let input = try? AVCaptureDeviceInput(device: backCamera) {
            backInput = input
        } else {
            fatalError("VideoCapturer: Issue with create input from back camera")
        }
        if let input = try? AVCaptureDeviceInput(device: frontCamera) {
            frontInput = input
        } else {
            fatalError("VideoCapturer: Issue with create input from front camera")
        }
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
