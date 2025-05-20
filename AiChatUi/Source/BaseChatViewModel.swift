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
    @Published public var messageViews: [MessageView] = []
    @Published var scrollPositionUUID: UUID? //when send, the message move to top
    
    open func sendMessage(content: String, type: ContentType) -> MessageView {
        var messageView: MessageView
    
        switch type {
            case .text:
                messageView = MessageView(text: content.trimmingCharacters(in: .whitespacesAndNewlines), type: .you)
            case .file:
                messageView = MessageView(text: "No support yet!", type: .you)
        }
        messageViews.append(messageView)
        scrollPositionUUID = messageView.id
        
        return messageView
    }
    
    open func receiveMessage(text: String) -> MessageView {
        let messageView = MessageView(text: text, type: .agent )
        messageViews.append(messageView)
        
        return messageView
    }
}
