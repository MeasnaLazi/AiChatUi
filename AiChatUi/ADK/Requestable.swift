//
//  Requestable.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//
import Foundation

public protocol Requestable {
    var requestURL : URL { get }
    var path : String? { get }
    var httpMethod : HTTPMethod { get }
    var header : [String : String] { get }
    var paramater : Paramater? { get }
    var timeout : TimeInterval? { get }
}

public enum HTTPMethod : String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
}

public enum Paramater {
    case body(Data)
    case query([String : String])
}
