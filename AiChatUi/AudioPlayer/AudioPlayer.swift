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
    
    private var player = Player()
    private var recorder = Recorder()
    private var recordingCallBack: ((Data)->())?
    
    init() {
        setUpSession()
        recorder.delegate = self
    }
    
    deinit {
        removeSession()
        player.cleanUp()
        recorder.cleanUp()
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
    
    func startRecording(recording: @escaping (Data) -> ()) {
        recordingCallBack = recording
        recorder.start()
    }
    
    func stopRecording() {
        recorder.stop()
    }
    
    func recording(data: Data) {
        if let recordingCallBack {
            recordingCallBack(data)
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
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("AudioPlayerImg: Failed to deactivate audio session - \(error)")
        }
    }
}
