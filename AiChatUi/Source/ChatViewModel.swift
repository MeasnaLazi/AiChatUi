//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

class ChatViewModel : ObservableObject {
    @Published var messageViews: [MessageView] = []
    
    func addMessageView(messageView: MessageView) {
        messageViews.append(messageView)
    }
    
}
