//
//  RequestExecutor.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

protocol RequestExecutor {
    func execute<T: Responable>(_ request: Requestable) async throws -> T
    func executeStream<T: Responable>( _ request: Requestable) async throws -> AsyncThrowingStream<T, Error>
}
