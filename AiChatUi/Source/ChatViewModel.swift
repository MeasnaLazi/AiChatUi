//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

class ChatViewModel : ObservableObject {
    @Published var messages: [MessageView] = []
    
    func addMessgae(message: MessageView) {
        messages.append(message)
    }
    
}
