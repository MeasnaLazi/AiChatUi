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
        var lastUUID: UUID?
        let displayEvents = session.events.filter {$0.content.parts.first?.text != nil}
        
        for event in displayEvents {
            let role = event.content.role
            let text = event.content.parts.first!.text ?? ""
            if role == "user" {
                self.sendMessage(content: text, type: .text)
            } else {
                lastUUID = self.receiveMessage(text: text)
            }
        }
        if let lastUUID {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                self.scrollPositionUUID = lastUUID
                print("scroll to button: \(lastUUID)")
            })
        }
    }
    
    func sendMessageToApiStreaming(content: String) async {
        guard let session = session else {
            return
        }
        let jsonData = session.buildNewMesssageDictionary(text: content, streaming: true).toData()
        do {
            let itemStream = try await runRepository.runSSE(data: jsonData)
            for try await item in itemStream {
                let _ = super.receiveMessage(text: item.content.parts.first?.text ?? "")
            }
        } catch {
            debugPrint(error)
        }
    }
    
    func sendMessageToApi(content: String) async {
        guard let session = session else {
            return
        }
        let jsonData = session.buildNewMesssageDictionary(text: content).toData()
        do {
            let events = try await runRepository.run(data: jsonData)
            let _ = super.receiveMessage(text: events.first?.content.parts.first?.text ?? "")
        } catch {
            debugPrint(error)
        }
    }
}
