//
//  AudioPlayer.swift
//  AiChatUi
//
//  Created by Measna on 12/6/25.
//
import AVFoundation

protocol AudioPlayer {
    func startPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?)
    func stopPlaying()
    func startRecording(recording: @escaping (Data)->())
    func stopRecording()
}

class AudioPlayerImp: AudioPlayer, RecorderDelegate {
    
    typealias RecorderCallBack = (Data)->()
    
    private let player = Player()
    private let recorder = Recorder()
    private var recorderCallBack: RecorderCallBack?
    
    init() {
        setUpSession()
        recorder.delegate = self
    }
    
    deinit {
        player.cleanUp()
        recorder.cleanUp()
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
    
    func startRecording(recording: @escaping RecorderCallBack) {
        recorderCallBack = recording
        recorder.start()
    }
    
    func stopRecording() {
        recorder.stop()
    }
    
    func recording(data: Data) {
        if let recorderCallBack {
            recorderCallBack(data)
        }
    }
    
    private func setUpSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
    
        } catch {
            print("AudioPlayerImg: Failed to start - \(error)")
        }
    }
    
    private func removeSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch {
            print("AudioPlayerImg: Failed to deactivate audio session - \(error)")
        }
    }
}
