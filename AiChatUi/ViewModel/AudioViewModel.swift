//
//  AudioStreamingViewModel.swift
//  AiChatUi
//
//  Created by Measna on 4/6/25.
//
//import SwiftUI
//import Accelerate
//import AVFoundation
//
//@MainActor
//class AudioViewModel: ObservableObject {
//    private var webSocket: WebSocket?
//    private let runRepository: RunRepository = RunRepositoryImp(requestExecute: APIClient())
//    private let audioPlayer = AudioPlayer()
//    private var eventStreamTask: Task<Void, Never>?
//    
//    @Published var isStreaming = false
//    @Published var webSocketStatus = "Connecting"
//    @Published var audioLevel: CGFloat = 0.0
//    
//    func startConnection(sessionId: String) async {
//        guard let webSocket = try? await runRepository.runLive(sessionId: sessionId, query: ["is_audio" : "true"]) else {
//            print("Can not create webSocket!")
//            return
//        }
//        self.webSocket = webSocket
//        await webSocket.connect()
//        startListeningToWebSocket()
//    }
//
//    private func startListeningToWebSocket() {
//        guard let webSocket = self.webSocket else {
//            print("webSocket is not initialize!")
//            return
//        }
//        
//        eventStreamTask = Task {
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = .iso8601
//            
//            for await event in webSocket.webSocketEvents {
//                DispatchQueue.main.async {
//                    switch event {
//                    case .connected:
//                        print("connected")
//                        self.webSocketStatus = "Connected"
//                    case .disconnected:
//                        print("disconnected")
//                        self.webSocketStatus = "Disconnected"
//                        self.endConnection()
//                    case .data(let data):
//                       
//                        guard let receive = try? decoder.decode(Receive.self, from: data) else {
//                            print("Can not decode binary data: \(data.count) bytes")
//                            return
//                        }
//                        
//                        if let turnComplete = receive.turnComplete, turnComplete {
//                            print("Turn completed")
//                            return
//                        }
//                        
//                        if let interruped = receive.isInterruped, interruped {
//                            print("Interruped")
////                            self.audioPlayer.stopPlaying()
//                            return
//                        }
//                        
//                        
//                        guard let data = receive.data else {
//                            print("data is emptry!")
//                            return
//                        }
//
//                        print("...receiving data")
//                        let audioData = Data(base64Encoded: data)
//                        self.audioPlayer.playing(data: audioData!) { buffered in
//                            DispatchQueue.main.async {
//                                self.audioLevel = self.calculateAudioLevel(from: buffered)
//                            }
//                        }
//                    case .error(let errorMessage):
//                        print("error: \(errorMessage)")
//                        self.webSocketStatus = "Error"
//                    }
//                }
//            }
//
//            DispatchQueue.main.async {
//                if self.webSocketStatus != "Connected" && self.webSocketStatus != "Error" {
//                    self.webSocketStatus = "Disconnected"
//                }
//                self.endConnection()
//            }
//        }
//    }
//    
//    
//    func startConversation() async {
//        
//        guard let webSocket = self.webSocket else {
//            print("webSocket is not initialize!")
//            return
//        }
//        
//        do {
//            try await audioPlayer.start()
//            try audioPlayer.recording { data in
//                print("sending data...")
//                let dataString = self.createSendString(data: data)
//                Task {
//                    try? await webSocket.send(string: dataString)
//                }
//            }
//            isStreaming = true
//        } catch {
//            print("error: \(error.localizedDescription)")
//        }
//    }
//    
//    func stopConversation() {
//        if isStreaming {
//            isStreaming = false
//            audioPlayer.stop()
//        }
//    }
//    
//    deinit {
//        Task { [weak self] in
//            if let self {
//                await self.stopConversation()
//                await self.endConnection()
//            }
//        }
//    }
//    
//    private func createSendString(data: Data) -> String {
//        let base64 = data.base64EncodedString()
//        let payload: [String: String] = ["mime_type": "audio/pcm", "data": base64]
//        let encoder = JSONEncoder()
//
//        encoder.outputFormatting = .prettyPrinted
//        guard let jsonData = try? encoder.encode(payload) else {
//            print("can not encode payload")
//            return ""
//        }
//        
//        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
//            print("can not convert to string")
//            return ""
//        }
//        
//        return jsonString
//    }
//        
//    func endConnection() {
//        guard let webSocket = self.webSocket else {
//            print("webSocket is not initialize!")
//            return
//        }
//        self.eventStreamTask?.cancel()
//        self.eventStreamTask = nil
//        
//        Task {
//            await webSocket.disconnect()
//        }
//        self.webSocket = nil
//        print("Connection cleaned up.")
//    }
//    
//    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
//        guard let channelData = buffer.floatChannelData else {
//            return 0
//        }
//        
//        let frameLength = Int(buffer.frameLength)
//        let channelDataPointer = UnsafeBufferPointer(start: channelData[0], count: frameLength)
//        let rms = vDSP.rootMeanSquare(channelDataPointer)
//        let avgPower = 20 * log10(rms)
//        let normalizedPower = CGFloat((avgPower + 50) / 50)
//        
//        return max(0, min(1, normalizedPower))
//    }
//}

import SwiftUI
import AVFoundation // Keep for permission request
import WebRTC

@MainActor
class AudioViewModel: ObservableObject {
    private var webSocket: WebSocket?
    private let runRepository: RunRepository = RunRepositoryImp(requestExecute: APIClient())
    private let webRTCClient = WebRTCClient() // Replaces AudioPlayer
    
    private var eventStreamTask: Task<Void, Never>?
    
    @Published var isStreaming = false
    @Published var webSocketStatus = "Connecting"
    // Audio level meter requires using the WebRTC stats API, which is more advanced.
    // For now, we will remove it to focus on getting the audio working.
    // @Published var audioLevel: CGFloat = 0.0
    
    init() {
        webRTCClient.delegate = self
    }

    func startConnection(sessionId: String) async {
        
        AudioSessionManager.shared.configure()
        
        guard let webSocket = try? await runRepository.runLive(sessionId: sessionId, query: ["is_audio" : "true"]) else {
            print("Cannot create webSocket!")
            return
        }
        self.webSocket = webSocket
        await webSocket.connect()
        startListeningToWebSocket()
        startConversation()
    }
    
    // This function's role changes to handle signaling messages
    private func startListeningToWebSocket() {
        guard let webSocket = self.webSocket else { return }
        
        eventStreamTask = Task {
            for await event in webSocket.webSocketEvents {
                if case .data(let data) = event {
                    let text = String(data: data, encoding: .utf8) ?? ""
                    print("signal receive: \(text)")
                    handleSignalingMessage(text)
                } else if case .connected = event {
                    DispatchQueue.main.async {
                        self.webSocketStatus = "Connected"
                    }
                } else if case .disconnected = event {
                    DispatchQueue.main.async {
                        self.webSocketStatus = "Disconnected"
                        self.endConnection()
                    }
                }
            }
        }
    }
    
    func startConversation() {
        // Permission is now handled by WebRTC, but it's good practice to check.
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else {
                print("Microphone permission denied.")
                return
            }
            
            // Setup and start the WebRTC connection process
            self.webRTCClient.setupPeerConnection()
            self.webRTCClient.start()
            self.isStreaming = true
        }
    }
    
    func stopConversation() {
        if isStreaming {
            isStreaming = false
            webRTCClient.disconnect()
            endConnection()
            
            AudioSessionManager.shared.deactivate()
        }
    }
    
    func startRecording() {
        webRTCClient.startSendingAudio()
    }
    
    func stopRecording() {
        webRTCClient.stopSendingAudio()
    }

    deinit {
//        stopConversation()
    }
    
    private func endConnection() {
        eventStreamTask?.cancel()
        eventStreamTask = nil
        Task {
            await webSocket?.disconnect()
            webSocket = nil
            print("Connection cleaned up.")
        }
    }
    
    // MARK: - Signaling Logic
    
    private func handleSignalingMessage(_ message: String) {
         guard let data = message.data(using: .utf8) else { return }
         
         // We now only expect 'answer' messages.
         if let signalingMessage = try? JSONDecoder().decode(SignalingMessage.self, from: data),
            signalingMessage.type == "answer",
            let sdp = signalingMessage.sdp {
             webRTCClient.handleRemoteAnswer(sdp: RTCSessionDescription(type: .answer, sdp: sdp))
         }
     }
}

// MARK: - WebRTCClientDelegate Conformance
extension AudioViewModel: WebRTCClientDelegate {
    nonisolated func webRTCClient(_ client: WebRTCClient, didCreateOffer offer: RTCSessionDescription) {
        let message = SignalingMessage(type: "offer", sdp: offer.sdp, candidate: nil)

        Task { @MainActor in
            sendSignalingMessage(message)
        }
    }
    
    nonisolated func webRTCClient(_ client: WebRTCClient, didGenerateCandidate candidate: RTCIceCandidate) {
//        let message = SignalingMessage(type: "candidate", sdp: nil, candidate: Candidate(from: candidate))
//        Task { @MainActor in
//            sendSignalingMessage(message)
//        }
    }
    
    private func sendSignalingMessage(_ message: SignalingMessage) {
        do {
            let data = try JSONEncoder().encode(message)
            if let jsonString = String(data: data, encoding: .utf8) {
                Task {
                    try? await webSocket?.send(string: jsonString)
                }
            }
        } catch {
            print("Error encoding signaling message: \(error)")
        }
    }
}

// MARK: - Codable Models for Signaling
struct SignalingMessage: Codable {
    let type: String
    let sdp: String?
    let candidate: Candidate?
}

struct Candidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    
    init(from iceCandidate: RTCIceCandidate) {
        self.sdp = iceCandidate.sdp
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
    }
}
