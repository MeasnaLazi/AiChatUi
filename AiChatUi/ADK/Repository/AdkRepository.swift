//
//  AdkService.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

protocol AdkRepository {
    func startSession(user: String, session: String) async throws -> Session
    func getSession(user: String, session: String) async throws -> Session
    func deleteSession(user: String, session: String) async throws -> Bool
}

struct AdkRepositoryImp : AdkRepository, BaseRepository {
    var requestExecutor: RequestExecutor
    
    init(requestExecute: RequestExecutor) {
        self.requestExecutor = requestExecute
    }
    
    func startSession(user: String, session: String) async throws -> Session {
        try await execute(AdkApi.start_session(user: user, session: session))
    }
    
    func getSession(user: String, session: String) async throws -> Session {
        try await execute(AdkApi.get_session(user: user, session: session))
    }
    
    func deleteSession(user: String, session: String) async throws -> Bool {
        try await execute(AdkApi.delete_session(user: user, session: session))
    }
}
