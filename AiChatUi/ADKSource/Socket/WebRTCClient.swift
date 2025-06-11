//
//  WebRTCClient.swift
//  AiChatUi
//
//  Created by Measna on 10/6/25.
//
import Foundation
import WebRTC

// This delegate protocol is now simpler
protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didCreateOffer offer: RTCSessionDescription)
}

class WebRTCClient: NSObject, RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        // required
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        // required
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // required
    }
    
    
    weak var delegate: WebRTCClientDelegate?
    
    private var peerConnection: RTCPeerConnection?
    private let factory: RTCPeerConnectionFactory
    private var localAudioTrack: RTCAudioTrack?
    private var rtcSender: RTCRtpSender?

    override init() {
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        super.init()
    }
    
    

    func setupPeerConnection() {
        let configuration = RTCConfiguration()
        let iceServer = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        configuration.iceServers = [iceServer]
        
        // This is important for the new flow. It tells WebRTC to gather all
        // candidates before signaling.
        configuration.iceTransportPolicy = .all

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        self.peerConnection = self.factory.peerConnection(with: configuration, constraints: constraints, delegate: self)
    }

    func start() {
        guard let pc = self.peerConnection else { return }
        
        let audioSource = self.factory.audioSource(with: nil)
        self.localAudioTrack = self.factory.audioTrack(with: audioSource, trackId: "audio0")
        pc.add(self.localAudioTrack!, streamIds: ["stream0"])
        
        // Store the sender so we can enable/disable its track
               self.rtcSender = pc.add(self.localAudioTrack!, streamIds: ["stream0"])
               
               // When we start, the track should be disabled by default. The user must press the button to talk.
               self.rtcSender?.track?.isEnabled = false
        
        pc.offer(for: RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)) { (offer, error) in
            guard let offer = offer else {
                print("Error creating offer: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            Task {
                try? await pc.setLocalDescription(offer)
            }
        }
    }
    
    func startSendingAudio() {
        print("🎤 START sending microphone audio")
        self.rtcSender?.track?.isEnabled = true
    }

    func stopSendingAudio() {
        print("🛑 STOP sending microphone audio")
        self.rtcSender?.track?.isEnabled = false
    }

    func handleRemoteAnswer(sdp: RTCSessionDescription) {
        guard let pc = self.peerConnection else { return }
        Task {
            try? await pc.setRemoteDescription(sdp)
        }
    }
    
    // This function is no longer needed as we don't handle remote candidates separately.
    // func handleRemoteCandidate(candidate: RTCIceCandidate) { ... }
    
    func disconnect() {
        peerConnection?.close()
        peerConnection = nil
    }
    
    // MARK: - RTCPeerConnectionDelegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCPeerConnectionState) {
        print("Connection state is \(peerConnection.connectionState)")
        // UI updates can go here
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        if newState == .complete {
            guard let pc = self.peerConnection, let localDescription = pc.localDescription else {
                return
            }
            // ICE gathering is complete. Now we can send the offer with all candidates.
            self.delegate?.webRTCClient(self, didCreateOffer: localDescription)
        }
    }
    
    // This is no longer needed. We let the offer contain all candidates.
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // DO NOTHING HERE.
    }
    
    // Unchanged methods below...
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let audioTrack = stream.audioTracks.first {
            print("Received remote audio track: \(audioTrack.trackId)")
                   
           // ADD THIS NEW LOG
           print("🎤 Step 3: Remote audio track isEnabled state: \(audioTrack.isEnabled)")
              
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
