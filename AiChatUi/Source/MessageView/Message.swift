//
//  Message.swift
//  AiChatUi
//
//  Created by Measna on 23/5/25.
//
import SwiftUI

public enum MessageType {
    case you
    case agent
}

public struct Message: Identifiable {
    public let id = UUID()
    let text: String
    let type: MessageType
}

public struct GroupMessage: Identifiable, Equatable {
    public let id = UUID()
    let you: Message
    var agents = [Message]()
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
