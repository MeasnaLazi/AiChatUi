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
    
    private let player = Player()
    private let recorder = Recorder()
    private let videoCapturer = VideoCapturer()
    
    private var recorderCallBack: RecorderCallBack?
    private var videoCallBack: VideoCallBack?
    
    var captureSession: AVCaptureSession {
        return videoCapturer.session
    }
    
    init() {
        setUpSession()
        recorder.delegate = self
        videoCapturer.delegate = self
    }
    
    deinit {
        player.cleanUp()
        recorder.cleanUp()
        videoCapturer.cleanUp()
        
        removeSession()
    }
    
    func startPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?) {
        player.play(data: data) { buffer in
            if let buffering {
                buffering(buffer)
            }
        }
    }
    
    func stopPlaying() {
        player.stop()
    }
    
    func startRecording(voiceRecording: @escaping RecorderCallBack, vedioRecording: @escaping VideoCallBack) {
        recorderCallBack = voiceRecording
        videoCallBack = vedioRecording
        
        recorder.start()
    }
    
    func stopRecording() {
        recorder.stop()
        resetRecordingCallBack()
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
    
    private func resetRecordingCallBack(){
        recorderCallBack = nil
        videoCallBack = nil
    }
}

extension CameraLivePlayerImp: RecorderDelegate {
    func recording(data: Data) {
        if let recorderCallBack {
            recorderCallBack(data)
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
