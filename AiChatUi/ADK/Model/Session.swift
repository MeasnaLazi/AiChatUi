//
//  ADKMessage.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

struct Session {
    
    typealias State = [String: Dynamic]
    
    let id: String
    let appName: String
    let userId: String
    let state: State
    let events: [Event]
    let lastUpdateTime: Double
    
    func buildNewMesssageDictionary(text: String, streaming: Bool = false) -> Dictionary<String, Any> {
        let part = ["text": text]
        let parts = [part]
        let newMessage: [String: Any] = ["role": "user", "parts": parts]
        let jsonData: [String: Any] = ["app_name": appName,
                        "user_id" : userId,
                        "session_id": id,
                        "streaming": streaming,
                        "new_message": newMessage]
        return jsonData
    }
}

extension Session: Decodable, Responable {}

struct Event {
    let content: Content
    let invocationId: String
    let author: String
    let actions: Action
    let longRunningToolIds: [String]?
    let id: String
    let timestamp: Double
    let usageMetadata: UsageMetadata?
    
    struct Action {
        typealias ActionItem = [String: Dynamic]
        let stateDelta: ActionItem
        let artifactDelta: ActionItem
        let requestedAuthConfigs: ActionItem
    }
}

extension Event: Decodable, Responable {}
extension Event.Action: Decodable, Responable {}

struct UsageMetadata {
    let candidatesTokenCount: Int
    let candidatesTokensDetails: [TokenDetail]
    let promptTokenCount: Int
    let promptTokensDetails: [TokenDetail]
    let totalTokenCount: Int
    
    struct TokenDetail {
        let modality: String
        let tokenCount: Int
    }
}

extension UsageMetadata: Decodable, Responable {}
extension UsageMetadata.TokenDetail: Decodable, Responable {}

struct Content {
    let parts: [Part]
    let role: String
}

extension Content: Decodable, Responable {}

struct Part {
    let text: String?
    let functionCall: FunctionCall?
    let functionResponse: FunctionResponse?
}

extension Part: Decodable, Responable {}

struct FunctionCall {
    let id: String
    let args: [String: Dynamic]
    let name: String
}

extension FunctionCall: Decodable, Responable {}

struct FunctionResponse {
    let id: String
    let name: String
    let response: Response
    
    struct Response {
        let result: Result
    }
    
    struct Result {
        let content: [Content]
        let isError: Bool
    }
    
    struct Content {
        let type: String
        let text: String
    }
}

extension FunctionResponse: Decodable, Responable {}
extension FunctionResponse.Response: Decodable, Responable {}
extension FunctionResponse.Result: Decodable, Responable {}
extension FunctionResponse.Content: Decodable, Responable {}


