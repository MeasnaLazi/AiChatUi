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
        case .runLiveCustom:
            return URL(string: Const().SOCKET_END_POINT)!
        case .runLive:
            return URL(string: Const().SOCKET_END_POINT)!
        default:
            return URL(string: Const().API_END_POINT)!
        }
    }
    
    var path: String? {
        switch self {
        case .runSSE:
           return "/run_sse"
        case .run:
           return "/run"
        case .runLiveCustom(let sessionId, _):
           return "/ws/\(sessionId)"
        case .runLive:
            return "/run_live"
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
        case .runLiveCustom(_, let query):
            return .query(query)
        case .runLive(let session):
            let query = [
                "app_name": session.appName,
                "user_id": session.userId,
                "session_id": session.id,
                "modalities": "AUDIO"
            ]
            return .query(query)
        }
    }
    
    var timeout: TimeInterval? {
        return nil
    }
    
    case runSSE(data: Data)
    case run(data: Data)
    case runLive(session: Session) // different json format from runLiveCustom when send and receive
    case runLiveCustom(sessionId: String, query: [String: String])
}
