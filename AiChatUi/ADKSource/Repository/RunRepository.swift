//
//  AdkService.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

protocol RunRepository {
    func run(data: Data) async throws -> [Event]
    func runSSE(data: Data) async throws -> AsyncThrowingStream<Event, Error>
    func runCustomLive(sessionId: String, query: [String: String]) async throws -> WebSocket
    func runLive(session: Session) async throws -> WebSocket
}

struct RunRepositoryImp : RunRepository, BaseRepository {
    var requestExecutor: RequestExecutor
    
    init(requestExecute: RequestExecutor) {
        self.requestExecutor = requestExecute
    }
    
    func run(data: Data) async throws -> [Event] {
        try await execute(RunApi.run(data: data))
    }
    
    func runSSE(data: Data) async throws -> AsyncThrowingStream<Event, Error> {
        try await executeStream(RunApi.runSSE(data: data))
    }
    
    func runCustomLive(sessionId: String, query: [String: String]) async throws -> WebSocket {
        try await createWebSocket(RunApi.runLiveCustom(sessionId: sessionId, query: query))
    }
    
    func runLive(session: Session) async throws -> WebSocket {
        try await createWebSocket(RunApi.runLive(session: session))
    }
}
