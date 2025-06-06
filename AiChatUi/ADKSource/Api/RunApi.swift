//
//  ADKApi.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//
import Foundation

enum RunApi : Requestable {
    var requestURL: URL {
        switch self {
        case .runLive:
            return URL(string: "ws://192.168.1.89:8000")!
        default:
            return URL(string: "http://192.168.1.89:8000")!
        }
    }
    
    var path: String? {
        switch self {
        case .runSSE:
           return "/run_sse"
        case .run:
           return "/run"
        case .runLive(let sessionId, _):
           return "/ws/\(sessionId)"
        }
    }
    
    var httpMethod: HTTPMethod {
        return .post
    }
    
    var header: [String : String] {
        return ["Content-Type": "application/json"]
    }
    
    var paramater: Paramater? {
        switch self {
        case .runSSE(let data):
            return .body(data)
        case .run(let data):
            return .body(data)
        case .runLive(_, let query):
            return .query(query)
        
        }
    }
    
    var timeout: TimeInterval? {
        return nil
    }
    
    case runSSE(data: Data)
    case run(data: Data)
    case runLive(sessionId: String, query: [String: String])
}
