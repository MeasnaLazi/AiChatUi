//
//  AudioPlayer.swift
//  AiChatUi
//
//  Created by Measna on 12/6/25.
//
import AVFoundation

protocol AudioPlayer {
    func startAudioPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?)
    func stopAudioPlaying()
    func startAudioRecording(voiceRecording: @escaping (Data)->())
    func stopAudioRecording()
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
    
    func startAudioPlaying(data: Data, buffering: ((AVAudioPCMBuffer)->())?) {
        player.play(data: data) { buffer in
            if let buffering {
                buffering(buffer)
            }
        }
    }
    
    func stopAudioPlaying() {
        player.stop()
    }
    
    func startAudioRecording(voiceRecording: @escaping RecorderCallBack) {
        recorderCallBack = voiceRecording
        recorder.start()
    }
    
    func stopAudioRecording() {
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
