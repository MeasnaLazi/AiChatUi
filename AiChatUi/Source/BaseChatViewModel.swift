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

@MainActor
open class BaseChatViewModel : ObservableObject {
    @Published public var groupMessages: [GroupMessage] = []
    @Published var scrollPositionUUID: UUID? //when send, the message move to top
    @Published var isInitMessages: Bool = true
    
    open func sendMessage(content: String, type: ContentType) {
        if content.isEmpty {
            return
        }
        
        var message: Message
    
        switch type {
        case .text:
            message = Message(text: content.trimmingCharacters(in: .whitespacesAndNewlines), type: .you)
        case .file:
            message = Message(text: "No support yet!", type: .you)
        }
        self.isInitMessages = false
        
        let group = GroupMessage(you: message)
        groupMessages.append(group)
        scrollPositionUUID = group.id
    }
    
    open func receiveMessage(text: String) {
        if text.isEmpty {
            return 
        }
        
        let message = Message(text: text, type: .agent)
        groupMessages[groupMessages.count - 1].agents.append(message)
    }
    
    func initExistMessages(messages: [Message]) {
        groupMessages.removeAll()
        
        for message in messages {
            if message.type == .you {
                let group = GroupMessage(you: message)
                groupMessages.append(group)
            } else {
                groupMessages[groupMessages.count - 1].agents.append(message)
            }
        }
    }
}
