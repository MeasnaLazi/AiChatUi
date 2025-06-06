import SwiftUI
import AVFoundation

enum AudioPlayerError: Error {
    case noPermission
    case targetFormatInvalid
}

class AudioPlayer {

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private var inputFormat: AVAudioFormat!
    private var outputFormat: AVAudioFormat!
    
    func start() async throws {
        
        try configureAudioSession()
        
        let hasPermission = await requestMicrophonePermission()
        if !hasPermission {
            print("Permission denied. We should disable recording features.")
            throw AudioPlayerError.noPermission
        }
    
        inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                     sampleRate: 24000,
                                     channels: 2,
                                     interleaved: false)

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)
        
        audioEngine.prepare()

        try audioEngine.start()
        playerNode.play()
    }

    func stop() {
        audioEngine.stop()
        playerNode.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    func recording(steaming: @escaping(Data)->()) throws {
        let inputNode = audioEngine.inputNode
        let sourceFormat = inputNode.outputFormat(forBus: 0)
        
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                               sampleRate: 16000.0,
                                               channels: 1,
                                               interleaved: sourceFormat.isInterleaved) else {
            print("Failed to create target audio format")
            throw AudioPlayerError.targetFormatInvalid
        }
        
        var converter: AVAudioConverter?
        if sourceFormat != targetFormat {
            converter = AVAudioConverter(from: sourceFormat, to: targetFormat)
            
            if converter == nil {
                print("Failed to create audio converter from \(sourceFormat) to \(targetFormat)")
                throw AudioPlayerError.targetFormatInvalid
            }
        }
        
        print("Source format: \(sourceFormat), Target format: \(targetFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: sourceFormat) { [weak self] (buffer, time) in
            guard let selfInstance = self else {
                print("self is nil...")
                return
            }
            
            var bufferToSend = buffer
            
            if let converter = converter {
                let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * (targetFormat.sampleRate / sourceFormat.sampleRate))
                guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
                    print("Failed to create converted buffer")
                    return
                }
                
                var error: NSError?
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
                if status == .error || error != nil {
                    print("Error during audio conversion: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                convertedBuffer.frameLength = outputFrameCapacity // Or based on actual output of converter
                bufferToSend = convertedBuffer
            }
            
            guard let data = selfInstance.bufferToData(buffer: bufferToSend, format: targetFormat) else {
                print("data invald! bufferToData returned nil.")
                if bufferToSend.floatChannelData == nil {
                    print("The buffer is likely not PCM Float32 non-interleaved.")
                    print("Actual buffer format: \(bufferToSend.format.commonFormat.rawValue), isInterleaved: \(bufferToSend.format.isInterleaved)")
                }
                return
            }
            
            steaming(data)
        }
    }
    
    func playing(data: Data, buffered: (AVAudioPCMBuffer)->()) {
        if data.isEmpty {
            print("data is empty, skipping buffer creation.")
            return
        }
        
        guard let buffer = self.dataToPCMBuffer(data: data, format: outputFormat) else {
            print("Failed to convert data to PCM buffer.")
            return
        }
        
        if buffer.frameLength > 0 {
            self.playerNode.scheduleBuffer(buffer)
            buffered(buffer)
            if !self.playerNode.isPlaying {
                self.playerNode.play()
            }
        } else {
            print("frameLength < 0")
        }
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try session.setActive(true)
        print("AVAudioSession configured and activated.")
    }
    
    private func requestMicrophonePermission() async -> Bool {
       return await withCheckedContinuation { continuation in
           AVAudioApplication.requestRecordPermission { granted in
               continuation.resume(returning: granted)
           }
       }
    }
    
    private func bufferToData(buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Data? {
        let frameLength = Int(buffer.frameLength)

        if format.commonFormat == .pcmFormatFloat32 && !format.isInterleaved {
            guard let floatChannelData = buffer.floatChannelData else {
                print("Error: outputFormat is not Float32 non-interleaved.")
                return nil
            }
            let floatPtr = floatChannelData[0]
            var int16Buffer = [Int16](repeating: 0, count: frameLength)
            for i in 0..<frameLength {
                int16Buffer[i] = Int16(max(-1.0, min(1.0, floatPtr[i])) * Float(Int16.max))
            }
            
            return Data(bytes: &int16Buffer, count: frameLength * MemoryLayout<Int16>.size)

        } else if format.commonFormat == .pcmFormatInt16 && !format.isInterleaved {
            guard let int16ChannelData = buffer.int16ChannelData else { return nil }
            let int16Ptr = int16ChannelData[0]
            return Data(bytes: int16Ptr, count: frameLength * MemoryLayout<Int16>.size)
        } else {
            print("Unsupported format or format is interleaved and not handled by this simple version. Format: \(format)")
            return nil
        }
    }
    
    private func dataToPCMBuffer(data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameLength = UInt32(data.count / 2)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
            print("dataToPCMBuffer Error: Failed to create buffer.")
            return nil
        }
        
        buffer.frameLength = frameLength

        guard let floatChannelData = buffer.floatChannelData else {
            print("Error: outputFormat is not Float32 non-interleaved.")
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
