//
//  Player.swift
//  AiChatUi
//
//  Created by Measna on 12/6/25.
//

import AVFoundation

class Player {
    private let playbackEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let playbackFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                               sampleRate: 24_000.0,
                                               channels: 2,
                                               interleaved: false)!
    init() {
        setupEngine()
    }
    
    func play(data: Data, buffered: (AVAudioPCMBuffer)->()) {
        if data.isEmpty {
            print("Player: Data is empty, skipping buffer creation.")
            return
        }
                
        guard let buffer = self.dataToPCMBuffer(data: data, format: playbackFormat) else {
            print("Player: Failed to convert data to PCM buffer.")
            return
        }
                
        if buffer.frameLength > 0 {
            buffered(buffer)
            self.playerNode.scheduleBuffer(buffer)
            
            if !self.playerNode.isPlaying {
                self.playerNode.play()
            }
        } else {
            print("Player: frameLength < 0")
        }
    }
    
    func stop() {
        self.playerNode.stop()
    }
    
    func cleanUp() {
        stop()
        self.playbackEngine.inputNode.removeTap(onBus: 0)
        self.playbackEngine.stop()
    }
    
    private func setupEngine() {
        playbackEngine.attach(playerNode)
        playbackEngine.connect(playerNode, to: playbackEngine.mainMixerNode, format: playbackFormat)
        
        do {
            try playbackEngine.start()
            playerNode.play()
            print("Player: Engine started.")
        } catch {
            print("Player: Could not start engine - \(error)")
        }
    }
    
    private func dataToPCMBuffer(data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
            
        let frameLength = UInt32(data.count / 2)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
            print("Player: dataToPCMBuffer Error - Failed to create buffer.")
            return nil
        }
        
        buffer.frameLength = frameLength

        guard let floatChannelData = buffer.floatChannelData else {
            print("Player: outputFormat is not Float32 non-interleaved.")
            return nil
        }

        let gainFactor: Float = 4.0
        let leftChannel = floatChannelData[0]
        let rightChannel = floatChannelData[1]

        data.withUnsafeBytes { rawBufferPointer in
            let int16Buffer = rawBufferPointer.bindMemory(to: Int16.self)

            for i in 0..<Int(frameLength) {
                let sample = int16Buffer[i]
                var floatSample = Float(sample) / 32768.0
                floatSample *= gainFactor
                floatSample = max(-1.0, min(1.0, floatSample))

                leftChannel[i] = floatSample
                rightChannel[i] = floatSample
            }
        }
        
        return buffer
    }
}
