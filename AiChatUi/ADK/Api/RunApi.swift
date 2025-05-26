//
//  ADKApi.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//
import Foundation

enum RunApi : Requestable {
    var requestURL: URL {
        return URL(string: "http://localhost:8000")!
    }
    
    var path: String? {
        switch self {
        case .runSSE:
           return "/run_sse"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .runSSE:
           return .post
        }
    }
    
    var header: [String : String] {
        return ["Content-Type": "application/json"]
    }
    
    var paramater: Paramater? {
        switch self {
        case .runSSE(let data):
            return .body(data)
        }
    }
    
    var timeout: TimeInterval? {
        return nil
    }
    
    case runSSE(data: Data)
}
