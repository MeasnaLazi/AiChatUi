//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

public enum ContentType {
    case text
    case file
}

open class BaseChatViewModel : ObservableObject {
    @Published public var groupMessages: [GroupMessage] = []
    @Published var scrollPositionUUID: UUID? //when send, the message move to top
    
    open func sendMessage(content: String, type: ContentType) {
        var message: Message
    
        switch type {
            case .text:
            message = Message(text: content.trimmingCharacters(in: .whitespacesAndNewlines), type: .you)
            case .file:
            message = Message(text: "No support yet!", type: .you)
        }
        
        let group = GroupMessage(you: message)
        groupMessages.append(group)
        scrollPositionUUID = group.id
    }
    
    open func receiveMessage(text: String) {
        let message = Message(text: text, type: .agent)
        groupMessages[groupMessages.count - 1].agents.append(message)
    }
}
