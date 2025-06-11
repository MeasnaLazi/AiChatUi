//
//  AudioSessionManager.swift
//  AiChatUi
//
//  Created by Measna on 10/6/25.
//

import Foundation
import AVFoundation
import WebRTC

class AudioSessionManager {

    static let shared = AudioSessionManager()
    private var isAudioEnabled = false

    private init() {
        // Listen for notifications about audio session interruptions (e.g., phone calls)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    func configure() {
        guard !isAudioEnabled else {
            print("Audio session is already configured and enabled.")
            return
        }
        
        print("🎤 Configuring and enabling audio session...")
        let rtcSession = RTCAudioSession.sharedInstance()
        
        // Lock the session for configuration
        rtcSession.lockForConfiguration()
        
        do {
            // Set the category and mode
            try rtcSession.setCategory(AVAudioSession.Category.playAndRecord,
                                       with: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try rtcSession.setMode(AVAudioSession.Mode.voiceChat)
            
            // This is the CRITICAL step that activates the WebRTC audio unit
            rtcSession.isAudioEnabled = true
            self.isAudioEnabled = true
            
            // Manually override output to speaker (this is a strong way to ensure output)
            try rtcSession.overrideOutputAudioPort(.speaker)
            
            print("✅ Audio Session configured and audio unit enabled successfully.")
            
        } catch {
            print("❌ Error configuring audio session: \(error.localizedDescription)")
        }
        
        // Unlock the session
        rtcSession.unlockForConfiguration()
    }

    func deactivate() {
        guard isAudioEnabled else { return }
        
        print("🎤 Deactivating audio session.")
        let rtcSession = RTCAudioSession.sharedInstance()
        rtcSession.lockForConfiguration()
        do {
            // Explicitly disable the audio unit
            rtcSession.isAudioEnabled = false
            self.isAudioEnabled = false
        } catch {
            print("❌ Error deactivating audio session: \(error.localizedDescription)")
        }
        rtcSession.unlockForConfiguration()
    }

    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            print("Audio session interruption began.")
            // The audio unit is automatically disabled by the system.
            self.isAudioEnabled = false
        } else if type == .ended {
            print("Audio session interruption ended.")
            // Check if we should re-activate the audio session
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("Resuming audio session.")
                    configure()
                }
            }
        }
    }
}
