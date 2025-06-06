//
//  AdkService.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

protocol SessionRepository {
    func startSession(user: String, session: String) async throws -> Session
    func getSession(user: String, session: String) async throws -> Session
    func deleteSession(user: String, session: String) async throws -> Bool
}

struct SessionRepositoryImp : SessionRepository, BaseRepository {
    var requestExecutor: RequestExecutor
    
    init(requestExecute: RequestExecutor) {
        self.requestExecutor = requestExecute
    }
    
    func startSession(user: String, session: String) async throws -> Session {
        try await execute(SessionApi.start_session(user: user, session: session))
    }
    
    func getSession(user: String, session: String) async throws -> Session {
        try await execute(SessionApi.get_session(user: user, session: session))
    }
    
    func deleteSession(user: String, session: String) async throws -> Bool {
        try await execute(SessionApi.delete_session(user: user, session: session))
    }
}
