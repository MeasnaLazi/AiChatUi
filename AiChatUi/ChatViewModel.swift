//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 19/5/25.
//
import SwiftUI

@MainActor
class ChatViewModel: BaseChatViewModel {
    
    private let repository: AdkRepository = AdkRepositoryImp(requestExecute: APIClient())
    private var session: Session?
    
    override func sendMessage(content: String, type: ContentType) {
//        print("My logic!")
        super.sendMessage(content: content, type: type)
    }
    
    func onInitialize() async {
        do {
            let existSesstion = try? await repository.getSession(user: "lazi", session: "lazi_session")
            guard let session = existSesstion else {
                self.session = try await repository.startSession(user: "lazi", session: "lazi_session")
                return
            }
            
            self.session = session
            self.extractDataAndSetToList(session: session)
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func extractDataAndSetToList(session: Session) {
        let events = session.events
        let displayEvents  = events.filter { $0.content.parts.first?.text != nil}
        
        for event in displayEvents {
            let role = event.content.role
            let text = event.content.parts.first!.text!
            if role == "user" {
                self.sendMessage(content: text, type: .text)
            } else {
                self.receiveMessage(text: text)
            }
        }
        
    }
}
