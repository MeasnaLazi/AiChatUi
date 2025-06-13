//
//  WebSocket.swift
//  AiChatUi
//
//  Created by Measna on 2/6/25.
//
import Foundation

enum WebSocketError: Error, LocalizedError {
    case notConnected
    case connectionAlreadyActive
    case failedToCreateTask
    case unknownMessageType

    var errorDescription: String? {
        switch self {
        case .notConnected: return "WebSocket is not connected."
        case .connectionAlreadyActive: return "WebSocket connection is already active or being started."
        case .failedToCreateTask: return "Failed to create the WebSocket task."
        case .unknownMessageType: return "Received an unknown WebSocket message type."
        }
    }
}

actor WebSocket {
    let url: URL
    var webSocketTask: URLSessionWebSocketTask?
    let urlSession: URLSession
    let eventContinuation: AsyncStream<WebSocketEvent>.Continuation
    let webSocketEvents: AsyncStream<WebSocketEvent>

    init(url: URL, configuration: URLSessionConfiguration = .default) {
        self.url = url
        self.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        var temporaryContinuation: AsyncStream<WebSocketEvent>.Continuation?

        self.webSocketEvents = AsyncStream<WebSocketEvent> { continuation in
            temporaryContinuation = continuation
        }

        guard let capturedContinuation = temporaryContinuation else {
            fatalError("AsyncStream continuation was not captured during WebSocketActiveConnection initialization.")
        }
        self.eventContinuation = capturedContinuation
        self.eventContinuation.onTermination = { @Sendable [weak temSelf = self] _ in
            guard let webSocket = temSelf else {
                return
            }
            Task {
                await webSocket.cleanUp()
            }
        }
    }

    func connect() {
        print("WebSocket: Connecting...")
        guard webSocketTask == nil else {
            eventContinuation.yield(.error(WebSocketError.connectionAlreadyActive.localizedDescription))
            return
        }

        webSocketTask = urlSession.webSocketTask(with: url)
        guard let activeTask = webSocketTask else {
            eventContinuation.yield(.error(WebSocketError.failedToCreateTask.localizedDescription))
            eventContinuation.finish()
            return
        }

        eventContinuation.yield(.connected)
        activeTask.resume()
        receiveMessages(for: activeTask)
        print("WebSocket: Connected!")
    }
    
    func send(data: Data) async throws {
        guard let task = webSocketTask, task.state == .running else {
            throw WebSocketError.notConnected
        }
        try await task.send(.data(data))
    }

    func send(string: String) async throws {
        guard let task = webSocketTask, task.state == .running else {
            throw WebSocketError.notConnected
        }
        
        try await task.send(.string(string))
    }

    func disconnect() {
        print("WebSocket: Disconnected.")
        eventContinuation.yield(.disconnected)
        eventContinuation.finish()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func cleanUp() {
        print("WebSocket: Clean Up!")
        self.webSocketTask?.cancel(with: .goingAway, reason: "Stream terminated".data(using: .utf8))
    }

    private func receiveMessages(for currentTask: URLSessionWebSocketTask) {
        Task {
            var isConnectionActive = true
            while isConnectionActive && !Task.isCancelled {
                do {
                    let message = try await currentTask.receive()
                    switch message {
                    case .string(let text):
                        self.eventContinuation.yield(.data(Data(text.utf8)))
                    case .data(let data):
                        self.eventContinuation.yield(.data(data))
                    @unknown default:
                        self.eventContinuation.yield(.error(WebSocketError.unknownMessageType.localizedDescription))
                    }
                } catch {
                    print("WebSocket: ReceiveMessages error: \(error.localizedDescription)")
                    isConnectionActive = false
                    
                    let nsError = error as NSError
                    if nsError.domain == NSPOSIXErrorDomain &&
                       (nsError.code == ECONNRESET || nsError.code == EPIPE || nsError.code == ECONNABORTED || nsError.code == ENOTCONN) {
                        self.eventContinuation.yield(.disconnected)
                    } else if (error as? URLError)?.code == .cancelled || error is CancellationError {
                        self.eventContinuation.yield(.disconnected)
                    } else {
                        self.eventContinuation.yield(.error(error.localizedDescription))
                    }
                    self.eventContinuation.finish()
                    self.webSocketTask = nil
                }
            }
            if isConnectionActive && Task.isCancelled {
                print("WebSocket: ReceiveMessages task cancelled!")
                self.eventContinuation.yield(.disconnected)
                self.eventContinuation.finish()
                currentTask.cancel(with: .normalClosure, reason: nil)
                self.webSocketTask = nil
            }
        }
    }

    deinit {
        print("WebSocket: Deinit.")
        eventContinuation.finish()
        webSocketTask?.cancel(with: .goingAway, reason: "WebSocket deinitialized".data(using: .utf8))
    }
}
