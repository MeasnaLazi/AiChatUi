//
//  VideoViewModel.swift
//  AiChatUi
//
//  Created by Measna on 15/6/25.

import SwiftUI
import Accelerate
import AVFoundation

@MainActor
class VideoViewModel: ObservableObject {
    private var webSocket: WebSocket?
    private let runRepository: RunRepository = RunRepositoryImp(requestExecute: APIClient())
    private var eventStreamTask: Task<Void, Never>?
    
    @Published var isStreaming = false
    @Published var webSocketStatus = "Connecting..."
    @Published var audioLevel: CGFloat = 0.0
    
    let cameraLivePlayer: CameraLivePlayer = CameraLivePlayerImp()
    
    func startConnection(sessionId: String) async {
        guard let webSocket = try? await runRepository.runCustomLive(sessionId: sessionId, query: ["is_audio" : "true"]) else {
            print("VideoViewModel: Can not create webSocket!")
            return
        }
        self.webSocket = webSocket
        await webSocket.connect()
        startListeningToWebSocket()
    }

    private func startListeningToWebSocket() {
        guard let webSocket = self.webSocket else {
            print("VideoViewModel: WebSocket is not initialize!")
            return
        }
        
        eventStreamTask = Task {
            for await event in webSocket.webSocketEvents {
                DispatchQueue.main.async {
                    switch event {
                    case .connected:
                        print("VideoViewModel: Connected")
                        self.webSocketStatus = "Connected"
                    case .disconnected:
                        print("VideoViewModel: Disconnected")
                        self.webSocketStatus = "Disconnected"
                        self.cleanUp()
                    case .data(let data):
                        print("VideoViewModel: ...receiving data")
                        self.handleReceiveSound(data: data)
                    case .error(let errorMessage):
                        print("VideoViewModel: error: \(errorMessage)")
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
    
    
    func startConversation() async {
        guard let webSocket = self.webSocket else {
            print("VideoViewModel: WebSocket is not initialize!")
            return
        }
        isStreaming = true
        
        cameraLivePlayer.startRecording { data in
            print("VideoViewModel: Voice Sending data...")
            let dataString = self.createSendString(data: data, type: "audio/pcm")
            Task {
                try? await webSocket.send(string: dataString)
            }
        } vedioRecording: {data in
            print("VideoViewModel: Frame Sending data...")
            let dataString = self.createSendString(data: data, type: "image/jpeg")
            Task {
                try? await webSocket.send(string: dataString)
            }
        }
    }
    
    func stopConversation() {
        if isStreaming {
            isStreaming = false
            cameraLivePlayer.stopPlaying()
            cameraLivePlayer.stopRecording()
        }
    }
    
    func cleanUp() {
        self.stopConversation()
        self.endConnection()
    }
    
    deinit {
        Task { [weak self] in
            if let self {
                await self.cleanUp()
            }
        }
    }
    
    func endConnection() {
        guard let webSocket = self.webSocket else {
            print("VideoViewModel: WebSocket is not initialize!")
            return
        }
        self.eventStreamTask?.cancel()
        self.eventStreamTask = nil
        
        Task {
            await webSocket.disconnect()
        }
        self.webSocket = nil
        print("VideoViewModel: Connection cleaned up.")
    }
    
    private func createSendString(data: Data, type: String) -> String {
        let base64 = data.base64EncodedString()
        let payload: [String: String] = ["mime_type": type, "data": base64]
        let encoder = JSONEncoder()

        encoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? encoder.encode(payload) else {
            print("VideoViewModel: Can not encode payload")
            return ""
        }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("VideoViewModel: Can not convert to string")
            return ""
        }
        
        return jsonString
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
    
    private func handleReceiveSound(data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let receive = try? decoder.decode(Receive.self, from: data) else {
            print("VideoViewModel: Can not decode binary data: \(data.count) bytes")
            return
        }
        
        if let turnComplete = receive.turnComplete, turnComplete {
            print("VideoViewModel: Turn completed")
            return
        }
        
        if let interruped = receive.isInterruped, interruped {
            print("VideoViewModel: Interruped")
            self.cameraLivePlayer.stopPlaying()
            return
        }
        
        guard let data = receive.data else {
            print("VideoViewModel: data is emptry!")
            return
        }

        if let audioData = Data(base64Encoded: data) {
            self.cameraLivePlayer.startPlaying(data: audioData) { buffer in
                DispatchQueue.main.async {
                    self.audioLevel = self.calculateAudioLevel(from: buffer)
                }
            }
        }
    }
}
