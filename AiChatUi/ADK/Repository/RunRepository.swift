//
//  AdkService.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

protocol RunRepository {
    func runSSE(data: Data) async throws -> AsyncThrowingStream<Event, Error>
}

struct RunRepositoryImp : RunRepository, BaseRepository {
    var requestExecutor: RequestExecutor
    
    init(requestExecute: RequestExecutor) {
        self.requestExecutor = requestExecute
    }
    
    func runSSE(data: Data) async throws -> AsyncThrowingStream<Event, Error> {
        try await executeStream(RunApi.runSSE(data: data))
    }
}
