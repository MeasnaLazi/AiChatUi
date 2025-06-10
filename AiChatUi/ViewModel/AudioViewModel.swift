//
//  AudioStreamingViewModel.swift
//  AiChatUi
//
//  Created by Measna on 4/6/25.
//
import SwiftUI
import Accelerate
import AVFoundation

@MainActor
class AudioViewModel: ObservableObject {
    private var webSocket: WebSocket?
    private let runRepository: RunRepository = RunRepositoryImp(requestExecute: APIClient())
    private let audioPlayer = AudioPlayer()
    private var eventStreamTask: Task<Void, Never>?
    
    @Published var isSpeaking = false
    @Published var webSocketStatus = "Connecting"
    @Published var audioLevel: CGFloat = 0.0
    
    func startConnection(sessionId: String) async {
        
        do {
            // This starts the audio engine.
            try await audioPlayer.activate()
        } catch {
            print("Failed to activate audio player: \(error)")
            webSocketStatus = "Error"
            return
        }
        
        guard let webSocket = try? await runRepository.runLive(sessionId: sessionId, query: ["is_audio" : "true"]) else {
            print("Can not create webSocket!")
            return
        }
        self.webSocket = webSocket
        await webSocket.connect()
        startListeningToWebSocket()
    }

    private func startListeningToWebSocket() {
        guard let webSocket = self.webSocket else {
            print("webSocket is not initialize!")
            return
        }
        
        eventStreamTask = Task {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for await event in webSocket.webSocketEvents {
                DispatchQueue.main.async {
                    switch event {
                    case .connected:
                        print("connected")
                        self.webSocketStatus = "Connected"
                    case .disconnected:
                        print("disconnected")
                        self.webSocketStatus = "Disconnected"
                        self.endConnection()
                    case .data(let data):
                        
                        print("...receiving data")
                        
//                        if self.isSpeaking {
//                            self.audioPlayer.stopPlaying()
//                            return
//                        }
                       
                        guard let receive = try? decoder.decode(Receive.self, from: data) else {
                            print("Can not decode binary data: \(data.count) bytes")
                            return
                        }
                        
                        if let turnComplete = receive.turnComplete, turnComplete {
                            print("Turn completed")
                            return
                        }
                        
                        if let interruped = receive.isInterruped, interruped {
                            print("Interruped")
                            self.audioPlayer.stopPlaying()
                            return
                        }
                        
                        guard let data = receive.data else {
                            print("data is emptry!")
                            return
                        }

                        print("...receiving data")
                        let audioData = Data(base64Encoded: data)
                        self.audioPlayer.playing(data: audioData!) { buffered in
                            DispatchQueue.main.async {
                                self.audioLevel = self.calculateAudioLevel(from: buffered)
                            }
                        }
                    case .error(let errorMessage):
                        print("error: \(errorMessage)")
                        self.webSocketStatus = "Error"
                    }
                }
            }

            DispatchQueue.main.async {
                if self.webSocketStatus != "Connected" && self.webSocketStatus != "Error" {
                    self.webSocketStatus = "Disconnected"
                }
                self.endConnection()
            }
        }
    }
    
    
    func startSpeaking() async throws {
        
        try audioPlayer.startRecording { [weak self] data in
            guard let self = self, let webSocket = self.webSocket else {
                return
            }
            print("sending data...")
            let dataString = self.createSendString(data: data)
            Task {
                  try? await webSocket.send(string: dataString)
            }
        }
    }
    
    func stopSpeaking() {
        isSpeaking = false
        audioPlayer.stopRecording()
    }
    
    deinit {
        Task { [weak self] in
            if let self {
                await self.stopSpeaking()
                await self.endConnection()
            }
        }
    }
    
    private func createSendString(data: Data) -> String {
        let base64 = data.base64EncodedString()
        let payload: [String: String] = ["mime_type": "audio/pcm", "data": base64]
        let encoder = JSONEncoder()

        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(payload) else {
            print("can not encode payload")
            return ""
        }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("can not convert to string")
            return ""
        }
        
        return jsonString
    }
        
    func endConnection() {
        guard let webSocket = self.webSocket else {
            print("webSocket is not initialize!")
            return
        }
        self.eventStreamTask?.cancel()
        self.eventStreamTask = nil
        
        Task {
            await webSocket.disconnect()
            self.webSocket = nil
            self.audioPlayer.deactivate()
            print("Connection cleaned up.")
        }
    }
    
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData else {
            return 0
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelDataPointer = UnsafeBufferPointer(start: channelData[0], count: frameLength)
        let rms = vDSP.rootMeanSquare(channelDataPointer)
        let avgPower = 20 * log10(rms)
        let normalizedPower = CGFloat((avgPower + 50) / 50)
        
        return max(0, min(1, normalizedPower))
    }
}
