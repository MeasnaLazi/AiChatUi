//
//  SessionApi.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//
import Foundation

enum SessionApi : Requestable {
    var requestURL: URL {
        return URL(string: "http://192.168.1.89:8000/apps/airbnb")!
    }
    
    var path: String? {
        var user = "", session = ""
        switch self {
        case .start_session(let u, let s):
            user = u
            session = s
        case .get_session(let u, let s):
            user = u
            session = s
        case .delete_session(let u, let s):
            user = u
            session = s
        }
        return "/users/\(user)/sessions/\(session)"
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .start_session:
            return .post
        case .get_session:
            return .get
        case .delete_session:
            return .delete
        }
    }
    
    var header: [String : String] {
        return ["Content-Type": "application/json"]
    }
    
    var paramater: Paramater? {
        return nil
    }
    
    var timeout: TimeInterval? {
        return nil
    }
    
    case start_session(user: String, session: String)
    case get_session(user: String, session: String)
    case delete_session(user: String, session: String)
}
