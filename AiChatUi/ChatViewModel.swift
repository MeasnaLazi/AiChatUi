//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 19/5/25.
//
import SwiftUI

class ChatViewModel: BaseChatViewModel {
    
    private let adkRepository: AdkRepository = AdkRepositoryImp(requestExecute: APIClient())
    private let runRepository: RunRepository = RunRepositoryImp(requestExecute: APIClient())
    private var session: Session?
    
    override func sendMessage(content: String, type: ContentType) {
//        print("My logic!")
        super.sendMessage(content: content, type: type)
    }
    
    func onInitialize() async {
        do {
            let existSesstion = try? await adkRepository.getSession(user: "lazi", session: "lazi_session")
            guard let session = existSesstion else {
                self.session = try await adkRepository.startSession(user: "lazi", session: "lazi_session")
                return
            }
            
            self.session = session
            self.extractDataAndSetToList(session: session)
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func extractDataAndSetToList(session: Session) {
        
        for event in session.events {
            let role = event.content.role
            let text = event.content.parts.first!.text ?? ""
            if role == "user" {
                self.sendMessage(content: text, type: .text)
            } else {
                self.receiveMessage(text: text)
            }
        }
    }
    
    func sendMessageToApi(content: String) async {
        guard let session = session else {
            return
        }
        let part = ["text": content]
        let parts = [part]
        let newMessage = ["role": "user",
                          "parts": parts] as [String : Any]
        let jsonData = ["app_name": session.appName,
                        "user_id" : session.userId,
                        "session_id": session.id,
                        "streaming": true,
                        "new_message": newMessage].toData()
        do {
            let itemStream = try await runRepository.runSSE(data: jsonData)
            for try await item in itemStream {
                super.receiveMessage(text: item.content.parts.first?.text ?? "")
            }
        } catch {
            debugPrint(error)
        }
    }
}
