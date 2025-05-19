//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

public class ChatViewModel : ObservableObject {
    @Published var messageViews: [MessageView] = []
    
    func addMessageView(messageView: MessageView) {
        messageViews.append(messageView)
    }
    
}

//protocol ChatViewModel : ObservableObject {
//    var messageViews: [MessageView] { get set }
//    func sendTextMessage(text: String)
//}
