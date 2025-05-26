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
}
