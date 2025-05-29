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
    @Published var isAnswering: Bool = false
    
    open func sendMessage(content: String, type: ContentType) {
        if content.isEmpty {
            return
        }
        
        self.isInitMessages = false
        self.isAnswering =  true
        
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
        if text.isEmpty {
            return 
        }
        
        self.stopThinking()
        
        let message = Message(text: text, type: .agent)
        groupMessages[groupMessages.count - 1].agents.append(message)
    }
    
    open func receiveMessageStream(text: String, isPartial: Bool) {
        if text.isEmpty {
            return
        }
        
        if !isPartial {
//            groupMessages[groupMessages.count - 1].agents[existMessages.count - 1].text = text
            return
        }
        
        let existMessages = groupMessages[groupMessages.count - 1].agents
        
        if existMessages.isEmpty {
            let message = Message(text: text, type: .agent)
            groupMessages[groupMessages.count - 1].agents.append(message)
        } else {
            groupMessages[groupMessages.count - 1].agents[existMessages.count - 1].text.append(text)
        }
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
    
    func stopThinking() {
        self.isAnswering = false
    }
}
