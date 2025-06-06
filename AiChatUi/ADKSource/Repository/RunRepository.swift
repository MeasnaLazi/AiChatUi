//
//  AdkService.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

protocol RunRepository {
    func runLive(sessionId: String, query: [String: String]) async throws -> WebSocket
    func runSSE(data: Data) async throws -> AsyncThrowingStream<Event, Error>
    func run(data: Data) async throws -> [Event]
}

struct RunRepositoryImp : RunRepository, BaseRepository {
    var requestExecutor: RequestExecutor
    
    init(requestExecute: RequestExecutor) {
        self.requestExecutor = requestExecute
    }
    
    func runLive(sessionId: String, query: [String: String]) async throws -> WebSocket {
        try await createWebSocket(RunApi.runLive(sessionId: sessionId, query: query))
    }
    
    func runSSE(data: Data) async throws -> AsyncThrowingStream<Event, Error> {
        try await executeStream(RunApi.runSSE(data: data))
    }
    
    func run(data: Data) async throws -> [Event] {
        try await execute(RunApi.run(data: data))
    }
}
