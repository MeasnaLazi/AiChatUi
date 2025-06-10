import SwiftUI
import AVFoundation

// MARK: - AudioStreamer
actor AudioStreamer {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private var inputFormat: AVAudioFormat!
    private var outputFormat: AVAudioFormat!

    var isRunning = false
    
    func start(url: URL) async throws {
            guard !isRunning else { return }
            isRunning = true

            webSocketTask = session.webSocketTask(with: url)
            webSocketTask?.resume()

            
            inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        
            // Ensure outputFormat is what the server will send.
            // If the server sends mono 16kHz and input is stereo 48kHz, this will be an issue.
            // For now, assuming echo:
            outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, // Or whatever format the server actually sends
                                         sampleRate: 24000, // Or server's sample rate
                                         channels: 1, // Or server's channel count
                                         interleaved: false) // Or server's interleaved status
            // If you are sure server sends same as input, then:
            // outputFormat = inputFormat
        
//        playerNode.volume = 1.0

            // Setup audio playback
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)

            // It's good practice to prepare the engine
            audioEngine.prepare()

            try audioEngine.start()
            playerNode.play() // Ensure playerNode starts playing to accept buffers

            try startSending() // This installs the tap
            Task { await startReceiving() } // This starts the receive loop
        }

//    func start(url: URL) async throws {
//        guard !isRunning else { return }
//        isRunning = true
//
//        webSocketTask = session.webSocketTask(with: url)
//        webSocketTask?.resume()
//
//        inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
//        outputFormat = inputFormat // use the same format to avoid errors
//
//        // Setup audio playback
//        audioEngine.attach(playerNode)
//        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)
//
//        try audioEngine.start()
//        playerNode.play()
//
//        try startSending()
//        Task { await startReceiving() }
//    }

    func stop() async {
        isRunning = false
        webSocketTask?.cancel()
        audioEngine.stop()
        playerNode.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    // MARK: - Send
    private func startSending() throws {
        let inputNode = audioEngine.inputNode
        
        let hardwareFormat = inputNode.outputFormat(forBus: 0) // Native format
            guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, // Or .pcmFormatFloat32
                                                  sampleRate: 16000.0,
                                                  channels: 1, // Assuming mono
                                                  interleaved: hardwareFormat.isInterleaved) else { // Or false if you deinterleave
                print("Failed to create target audio format")
                // Handle error, maybe throw
                return
            }

            var converter: AVAudioConverter?
            if hardwareFormat != targetFormat { // Only create converter if formats differ
                converter = AVAudioConverter(from: hardwareFormat, to: targetFormat)
                if converter == nil {
                    print("Failed to create audio converter from \(hardwareFormat) to \(targetFormat)")
                    // Handle error
                    return
                }
            }
            print("Hardware format: \(hardwareFormat), Target format: \(targetFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] (buffer, time) in
            //                guard let self = self else { return }
            
            guard let actorInstance = self else { return }
            
            Task{
                
                var bufferToSend = buffer
                if let converter = converter {
                    // Need to create an output buffer for the converter
                    let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * (targetFormat.sampleRate / hardwareFormat.sampleRate))
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
                
                guard let data = await actorInstance.bufferToData(buffer: bufferToSend, format: targetFormat) else {
                    print("data invald! bufferToData returned nil.")
                      if bufferToSend.floatChannelData == nil {
                          print("Reason: bufferToSend.floatChannelData was nil. This means the buffer is likely not PCM Float32 non-interleaved.")
                          print("Actual buffer format - commonFormat: \(bufferToSend.format.commonFormat.rawValue), isInterleaved: \(bufferToSend.format.isInterleaved)")
                      }
                    return
                } // Use targetFormat here
   
                
                do {
                    let base64 = data.base64EncodedString()
                    let payload: [String: String] = ["mime_type": "audio/pcm", "data": base64] // Consider adding format details to mime_type or payload
                    
                    var jsonStringFromEncoder: String?
                    let encoder = JSONEncoder()
                    
                    // For a more compact JSON string (good for network transmission), remove .prettyPrinted
                    encoder.outputFormatting = .prettyPrinted // Makes the JSON string human-readable with indentation
                    
                    let jsonData = try encoder.encode(payload)
                    jsonStringFromEncoder = String(data: jsonData, encoding: .utf8)
                    
                    if let jsonStr = jsonStringFromEncoder {
                        Task {
                            await actorInstance.send(jsonStr)
                        }
                        //                        print("JSON String (from JSONEncoder):\n\(jsonStr)")
                    } else {
                        print("JSONEncoder: Could not convert JSON data to UTF-8 string.")
                    }
                } catch {
                    print("JSONEncoder Error: Failed to encode dictionary to JSON - \(error.localizedDescription)")
                }
            }
        }
        
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
//            guard let data = self.bufferToData(buffer: buffer, format: self.inputFormat) else { return }
//            let base64 = data.base64EncodedString()
//            let payload: [String: String] = ["mime_type": "audio/pcm", "data": base64]
////            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
////                  let jsonString = String(data: jsonData, encoding: .utf8) else { return }
//            
//            var jsonStringFromEncoder: String?
//           let encoder = JSONEncoder()
//
//           // For a more compact JSON string (good for network transmission), remove .prettyPrinted
//           encoder.outputFormatting = .prettyPrinted // Makes the JSON string human-readable with indentation
//
//           do {
//               let jsonData = try encoder.encode(payload)
//               jsonStringFromEncoder = String(data: jsonData, encoding: .utf8)
//
//               if let jsonStr = jsonStringFromEncoder {
//                   Task {
//                       await self.send(jsonStr)
//                   }
////                        print("JSON String (from JSONEncoder):\n\(jsonStr)")
//               } else {
//                   print("JSONEncoder: Could not convert JSON data to UTF-8 string.")
//               }
//           } catch {
//               print("JSONEncoder Error: Failed to encode dictionary to JSON - \(error.localizedDescription)")
//           }
//
//   
//        }
    }
    
    private func startReceiving() async {
        print("StartReceiving: Entered receive loop.")
        while isRunning {
            guard let task = webSocketTask else {
                print("StartReceiving: WebSocketTask is nil, cannot receive.")
                // Consider setting isRunning = false here or handling reconnection
                await Task.yield() // Prevent tight loop if task is nil
                continue
            }
            do {
                print("StartReceiving: Waiting to receive message...")
                let result = try await task.receive() // No optional chaining if we guard above
                switch result {
                case .string(let jsonString):
                    print("StartReceiving: Received string.")
                    // ... your existing processing logic ...
                    if let data = jsonString.data(using: .ascii),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: String], // Added try? for safety
                       let base64 = json["data"],
                       let audioData = Data(base64Encoded: base64) {
                        
                        print("Receiving audio data chunk.")
                        
                        print("AUDIO DEBUG: Received audioData.count: \(audioData.count) bytes.")
                            if audioData.isEmpty {
                                print("AUDIO DEBUG: audioData is empty, skipping buffer creation.")
                                continue
                            }
                            print("AUDIO DEBUG: Using self.outputFormat: \(self.outputFormat)")
                        

                        if let buffer = self.dataToPCMBuffer(data: audioData, format: outputFormat) {
                            if buffer.frameLength > 0 {
                                    // Await the asynchronous version of the function
                                    await self.playerNode.scheduleBuffer(buffer) // The simplest async version
                                    
                                    // Ensure the player is running. This check is still useful.
                                    if !self.playerNode.isPlaying {
                                        self.playerNode.play()
                                    }
                                }
                        } else {
                            print("StartReceiving: Failed to convert data to PCM buffer.")
                        }
                    } else {
                        print("StartReceiving: Failed to parse received JSON or decode base64.")
                    }
                case .data(let data):
                    print("StartReceiving: Received binary data: \(data.count) bytes. (Currently unhandled)")
                    // Handle binary data if your server might send it
                @unknown default:
                    print("StartReceiving: Received unknown message type.")
                }
            } catch {
                print("StartReceiving: Receive error: \(error.localizedDescription)")
                // Check if the error is a cancellation error (e.g., when stop() is called)
                // or a more critical network error.
                if (error as NSError).code == NSURLErrorCancelled || (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == Int(ECONNABORTED) {
                    print("StartReceiving: Connection cancelled or aborted. Expected if stopping.")
                } else {
                    print("StartReceiving: Unhandled receive error. Consider stopping the stream or attempting to reconnect.")
                    // Depending on the error, you might want to stop everything.
                    // For now, we will break, but ensure isRunning reflects this.
                }
                // If any error occurs, it's often best to consider the receiving loop compromised.
                // You might want to trigger a full stop from here.
//                await MainActor.run { // If you need to update @Published vars from the ViewModel
                     self.isRunning = false // Ensure the loop condition will terminate
//                }
                break // Exit the loop on error
            }
        }
        print("StartReceiving: Exited receive loop. isRunning: \(isRunning)")
    }

    private func send(_ string: String) async {
        guard isRunning else { return }
        do {
            try await webSocketTask?.send(.string(string))
            print("Sending...")
        } catch {
            print("Send error: \(error)")
        }
    }

    // MARK: - Receive
//    private func startReceiving() async {
//        while isRunning {
//                    do {
//                        guard let result = try await webSocketTask?.receive() else { continue }
//                        switch result {
//                        case .string(let jsonString):
//                            guard let data = jsonString.data(using: .utf8),
//                                  let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
//                                  let base64 = json["data"],
//                                  let audioData = Data(base64Encoded: base64) else { continue }
//                            
//                            print("Receiving")
//
//                            if let buffer = self.dataToPCMBuffer(data: audioData, format: outputFormat) {
//                                self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
//                            }
//                        default:
//                            print("Unsupported WebSocket message")
//                        }
//                    } catch {
//                        print("Receive error: \(error)")
//                        break
//                    }
//                }
//    }

    // MARK: - Helpers
    private func bufferToData(buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Data? {
        
        let frameLength = Int(buffer.frameLength)
            // Assuming mono for simplicity in this example, or processing the first channel.
            // For multi-channel, you'd need to handle all channels.

            if format.commonFormat == .pcmFormatFloat32 && !format.isInterleaved {
                guard let floatChannelData = buffer.floatChannelData else { return nil }
                let floatPtr = floatChannelData[0] // Channel 0
                var int16Buffer = [Int16](repeating: 0, count: frameLength)
                for i in 0..<frameLength {
                    int16Buffer[i] = Int16(max(-1.0, min(1.0, floatPtr[i])) * Float(Int16.max))
                }
                return Data(bytes: &int16Buffer, count: frameLength * MemoryLayout<Int16>.size)

            } else if format.commonFormat == .pcmFormatInt16 && !format.isInterleaved {
                guard let int16ChannelData = buffer.int16ChannelData else { return nil }
                let int16Ptr = int16ChannelData[0] // Channel 0
                return Data(bytes: int16Ptr, count: frameLength * MemoryLayout<Int16>.size)

            } else {
                print("bufferToData: Unsupported format or format is interleaved and not handled by this simple version. Format: \(format)")
                return nil
            }
        
//        guard let channelData = buffer.floatChannelData else { return nil }
//        let floatPointer = channelData.pointee
//        let frameLength = Int(buffer.frameLength)
//
//        var int16Buffer = [Int16](repeating: 0, count: frameLength)
//        for i in 0..<frameLength {
//            let sample = floatPointer[i]
//            int16Buffer[i] = Int16(max(-1.0, min(1.0, sample)) * Float(Int16.max))
//        }
//
//        return Data(bytes: &int16Buffer, count: frameLength * MemoryLayout<Int16>.size)
    }

    private func dataToPCMBuffer(data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
//        let frameLength = UInt32(data.count) / 2
//        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else { return nil }
//        buffer.frameLength = frameLength
//
//        guard let floatChannelData = buffer.floatChannelData else { return nil }
//        for i in 0..<Int(frameLength) {
//            let sample = Int16(bitPattern: UInt16(data[2*i]) | UInt16(data[2*i+1]) << 8)
//            floatChannelData[0][i] = Float(sample) / Float(Int16.max)
//        }
//
//        return buffer
        
        let frameLength = UInt32(data.count) / 2 // Correct for mono 16-bit PCM
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
                print("dataToPCMBuffer Error: Failed to create buffer.")
                return nil
            }
            buffer.frameLength = frameLength

            // 'format' (self.outputFormat) must be Float32 for this to work
            guard let floatChannelData = buffer.floatChannelData else {
                print("dataToPCMBuffer Error: outputFormat is not Float32 non-interleaved.")
                return nil
            }

            // --- Adjust Gain Factor ---
            // Your previous peak raw Int16 was ~4192.
            // Normalized peak: 4192 / 32767 ≈ 0.128
            // To get this to ~0.8 (a reasonable loud level): 0.8 / 0.128 ≈ 6.25
            // This is a significant gain. Start lower and test.
            let gainFactor: Float = 4.0 // << START with 3.0 or 4.0 and adjust by listening

            var maxDebugRawSample: Int16 = 0
            var maxDebugFloatSample: Float = 0.0

            for i in 0..<Int(frameLength) {
                // Ensure we don't read past the end of the data for two bytes
                guard (2*i + 1) < data.count else {
                    print("dataToPCMBuffer: Warning - trying to read Int16 past end of data at index \(2*i)")
                    if i < Int(frameLength) { floatChannelData[0][i] = 0.0 } // Fill rest of this channel with 0 if error
                    // If this happens, frameLength might be miscalculated or data truncated.
                    // For simplicity, we might just break, but then buffer.frameLength would be too large.
                    // Better to ensure frameLength calculation is robust or pre-validate data.count.
                    // Given data.count is a multiple of 4 from logs, and channelCount=1, data.count/2 should be fine.
                    break // Exit loop if data is unexpectedly short
                }

                // Parse as Little-Endian Int16
                let sample = Int16(bitPattern: UInt16(data[2*i]) | UInt16(data[2*i+1]) << 8)
                
                if abs(sample) > maxDebugRawSample { maxDebugRawSample = abs(sample) }

                var floatSample = Float(sample) / Float(Int16.max) // Normalize
                floatSample *= gainFactor // Apply gain

                // Clamp to prevent clipping
                floatSample = max(-1.0, min(1.0, floatSample))
                
                if abs(floatSample) > maxDebugFloatSample { maxDebugFloatSample = abs(floatSample) }

                if i < Int(frameLength) { // Check 'i' against current potentially modified frameLength if we broke loop
                     floatChannelData[0][i] = floatSample
                }
            }
            
            if frameLength > 0 {
                print("Max raw LE Int16: \(maxDebugRawSample), Max float after gain & clamp: \(maxDebugFloatSample)")
            }
            return buffer
        
//        let frameLength = UInt32(data.count) / 2
//            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else { return nil }
//            buffer.frameLength = frameLength
//
//            guard let floatChannelData = buffer.floatChannelData else {
//                print("dataToPCMBuffer: Error - outputFormat is not Float32 non-interleaved, cannot get floatChannelData.")
//                return nil
//            }
//
//            // --- Determine a Gain Factor ---
//            // Your peak is ~0.128. If you want it to be, for example, ~0.7 to 0.8:
//            // Target Peak / Current Peak = Gain Factor
//            // 0.7 / 0.128 ≈ 5.4
//            // Let's try a more conservative gain first, e.g., 3.0 or 4.0.
//            // Too much gain can amplify noise or cause clipping if some packets are louder.
//            let gainFactor: Float = 4.0 // << TRY ADJUSTING THIS VALUE (e.g., 2.0, 3.0, 4.0, 5.0)
//
//            var maxDebugRawSample: Int16 = 0
//            var maxDebugFloatSample: Float = 0.0
//
//            for i in 0..<Int(frameLength) {
//                let sample = Int16(bitPattern: UInt16(data[2*i]) | UInt16(data[2*i+1]) << 8)
//
//                if abs(sample) > maxDebugRawSample { maxDebugRawSample = abs(sample) } // For debug
//
//                var floatSample = Float(sample) / Float(Int16.max) // Normalize
//                floatSample *= gainFactor // Apply gain
//
//                // IMPORTANT: Clamp the sample to prevent clipping if gain pushes it beyond -1.0 or 1.0
//                floatSample = max(-1.0, min(1.0, floatSample))
//
//                if abs(floatSample) > maxDebugFloatSample { maxDebugFloatSample = abs(floatSample) } // For debug
//
//                floatChannelData[0][i] = floatSample
//            }
//
//            if frameLength > 0 {
//                print("Max raw Int16: \(maxDebugRawSample), Max float after gain & clamp: \(maxDebugFloatSample)")
//            }
//            return buffer
    }
}

// MARK: - ViewModel
@MainActor
class AudioStreamingViewModel: ObservableObject {
    private let streamer = AudioStreamer()
    @Published var isStreaming = false

    func startStreaming() async {
        guard let url = URL(string: "ws://192.168.1.89:8000/ws/lazi_session?is_audio=true") else { return }
        do {
            try await streamer.start(url: url)
            isStreaming = true
        } catch {
            print("Start error: \(error)")
        }
    }

    func stopStreaming() {
        Task {
            await streamer.stop()
            isStreaming = false
        }
    }
}

// MARK: - SwiftUI View
struct AudioStreamingView: View {
    @StateObject private var viewModel = AudioStreamingViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.isStreaming ? "Streaming..." : "Stopped")
                .font(.headline)

            Button(action: {
                if viewModel.isStreaming {
                    viewModel.stopStreaming()
                } else {
                    Task { await viewModel.startStreaming() }
                }
            }) {
                Text(viewModel.isStreaming ? "Stop" : "Start")
                    .padding()
                    .background(viewModel.isStreaming ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}
