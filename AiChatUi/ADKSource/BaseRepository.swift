//
//  BaseRepository.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

protocol BaseRepository {
    var requestExecutor: RequestExecutor { get set }
    init(requestExecute: RequestExecutor)
}

extension BaseRepository {
    func execute<T: Responable>(_ request: Requestable) async throws -> T {
        try await self.requestExecutor.execute(request)
    }
    func executeStream<T: Responable>(_ request: Requestable) async throws -> AsyncThrowingStream<T, Error> {
        try await self.requestExecutor.executeStream(request)
    }
    func createWebSocket(_ request: Requestable) async throws -> WebSocket {
        try await self.requestExecutor.createWebSocket(request)
    }
}
