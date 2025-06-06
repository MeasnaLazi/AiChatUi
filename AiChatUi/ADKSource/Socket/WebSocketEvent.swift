//
//  WebSocketEvent.swift
//  AiChatUi
//
//  Created by Measna on 2/6/25.
//

import Foundation

enum WebSocketEvent: Sendable, Hashable {
    case connected
    case disconnected
    case data(Data)
    case error(String)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .connected:
            hasher.combine(0)
        case .disconnected:
            hasher.combine(1)
        case .data(let data):
            hasher.combine(2)
            hasher.combine(data)
        case .error(let message):
            hasher.combine(3)
            hasher.combine(message)
        }
    }

    static func == (lhs: WebSocketEvent, rhs: WebSocketEvent) -> Bool {
        switch (lhs, rhs) {
        case (.connected, .connected): return true
        case (.disconnected, .disconnected): return true
        case (.data(let lData), .data(let rData)): return lData == rData
        case (.error(let lMsg), .error(let rMsg)): return lMsg == rMsg
        default: return false
        }
    }
}
