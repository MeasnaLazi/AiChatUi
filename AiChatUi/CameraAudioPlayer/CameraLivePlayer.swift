//
//  VideoPlayer.swift
//  AiChatUi
//
//  Created by Measna on 15/6/25.
//
import AVFoundation

protocol CameraLivePlayer: AudioPlayer {
    var captureSession: AVCaptureSession { get }
    func startVideoRecording(vedioRecording: @escaping (Data)->())
    func stopVideoRecording()
    func startCamera()
    func stopCamera()
    func switchCamera()
    func switchTorch()
}

class CameraLivePlayerImp : CameraLivePlayer {
    
    typealias RecorderCallBack = (Data)->()
    typealias VideoCallBack = (Data)->()
    
    private let audioPlayer = AudioPlayerImp()
    private let videoCapturer = VideoCapturer()
    
    private var videoCallBack: VideoCallBack?
    
    var captureSession: AVCaptureSession {
        return videoCapturer.session
    }
    
    init() {
        videoCapturer.delegate = self
    }
    
    deinit {
        audioPlayer.stopAudioRecording()
        audioPlayer.stopAudioPlaying()
        videoCapturer.stop()
    }
    
    func startAudioPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?) {
        audioPlayer.startAudioPlaying(data: data) { buffer in
            if let buffering {
                buffering(buffer)
            }
        }
    }
    
    func stopAudioPlaying() {
        audioPlayer.stopAudioPlaying()
    }
    
    func startAudioRecording(voiceRecording: @escaping (Data) -> ()) {
        audioPlayer.startAudioRecording { data in
            voiceRecording(data)
        }
    }
    
    func stopAudioRecording() {
        audioPlayer.stopAudioRecording()
    }
    
    func startVideoRecording(vedioRecording: @escaping (Data) -> ()) {
        videoCallBack = vedioRecording
    }
    
    func stopVideoRecording() {
        videoCallBack = nil
    }
    
    func startCamera() {
        videoCapturer.start()
    }

    func stopCamera() {
        videoCapturer.stop()
    }
    
    func switchCamera() {
        videoCapturer.switchCamera()
    }
    
    func switchTorch() {
        videoCapturer.switchTorch()
    }
}

extension CameraLivePlayerImp: VideoCapturerDelegate {
    func videoCapturer(_ capturer: VideoCapturer, didCaptureFrame data: Data) {
        if let videoCallBack {
            videoCallBack(data)
        }
    }
}
