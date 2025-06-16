//
//  VideoPlayer.swift
//  AiChatUi
//
//  Created by Measna on 15/6/25.
//
import AVFoundation

protocol CameraLivePlayer {
    var captureSession: AVCaptureSession { get }
    
    func startPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?)
    func stopPlaying()
    func startRecording(voiceRecording: @escaping (Data)->(), vedioRecording: @escaping (Data)->())
    func stopRecording()
    func startCamera()
    func stopCamera()
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
        setUpSession()
        videoCapturer.delegate = self
    }
    
    deinit {
        audioPlayer.stopRecording()
        audioPlayer.stopPlaying()
        videoCapturer.cleanUp()
        
        removeSession()
    }
    
    func startPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?) {
        audioPlayer.startPlaying(data: data) { buffer in
            if let buffering {
                buffering(buffer)
            }
        }
    }
    
    func stopPlaying() {
        audioPlayer.stopPlaying()
    }
    
    func startRecording(voiceRecording: @escaping RecorderCallBack, vedioRecording: @escaping VideoCallBack) {
        videoCallBack = vedioRecording
        
        audioPlayer.startRecording { data in
            voiceRecording(data)
        }
    }
    
    func stopRecording() {
        audioPlayer.stopRecording()
        videoCallBack = nil
    }
    
    func startCamera() {
        videoCapturer.start()
    }

    func stopCamera() {
        videoCapturer.stop()
    }
    
    private func setUpSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
    
        } catch {
            print("CameraLivePlayerImp: Failed to start - \(error)")
        }
    }
    
    private func removeSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch {
            print("CameraLivePlayerImp: Failed to deactivate audio session - \(error)")
        }
    }
}

extension CameraLivePlayerImp: VideoCapturerDelegate {
    func videoCapturer(_ capturer: VideoCapturer, didCaptureFrame data: Data) {
        if let videoCallBack {
            videoCallBack(data)
        }
    }
}
