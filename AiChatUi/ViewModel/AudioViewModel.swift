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
    
    @Published var isStreaming = false
    @Published var webSocketStatus = "Disconnected"
    @Published var audioLevel: CGFloat = 0.0
    
    func initilize(sessionId: String) async {
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
                        self.cleanupConnection()
                    case .data(let data):
                        
                        guard let receive = try? decoder.decode(Receive.self, from: data) else {
                            print("Can not decode binary data: \(data.count) bytes")
                            return
                        }
                        
                        guard let data = receive.data else {
                            print("Interruped, data is emptry!")
                            return
                        }
                        
                        let audioData = Data(base64Encoded: data)
                        self.audioPlayer.playing(data: audioData!) { buffered in
                            DispatchQueue.main.async {
                                self.audioLevel = self.calculateAudioLevel(from: buffered)
                            }
                        }
                        
//                        if let string = String(data: data, encoding: .ascii) {
//                            print("Received data: \(string)")
//                            let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
//                            let base64 = json!["data"]!
//                            let audioData = Data(base64Encoded: base64)
//                            self.audioPlayer.playing(data: audioData!)
//                                
//                        } else {
//                            print("Received binary data: \(data.count) bytes")
//                        }
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
                self.cleanupConnection()
            }
        }
    }
    
    
    func startConversation() async {
        
        guard let webSocket = self.webSocket else {
            print("webSocket is not initialize!")
            return
        }
       
        do {
            try audioPlayer.recording { data in
                print("sending data...")
                let dataString = self.createSendString(data: data)
                Task {
                    try? await webSocket.send(string: dataString)
                }
            }
       
            try await audioPlayer.start()
            isStreaming = true
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    func stopStreaming() {
        isStreaming = false
        audioPlayer.stop()
        cleanupConnection()
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
        
    private func cleanupConnection() {
        
        guard let webSocket = self.webSocket else {
            print("webSocket is not initialize!")
            return
        }
        eventStreamTask?.cancel()
        eventStreamTask = nil
        Task {
            await webSocket.disconnect()
        }

        self.webSocket = nil
        print("Connection cleaned up.")
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
