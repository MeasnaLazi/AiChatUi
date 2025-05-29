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
        let displayEvents = session.events.filter {$0.content.parts.first?.text != nil}
        let messages = displayEvents.map {
            let text = $0.content.parts.first!.text!
            if $0.content.role == "user" {
                return Message(text: text, type: .you)
            } else {
                return Message(text: text, type: .agent)
            }
        }
    
        super.initExistMessages(messages: messages)
    }
    
    func sendMessageToApiStreaming(content: String) async {
        guard let session = session else {
            return
        }
        let jsonData = session.buildNewMesssageDictionary(text: content, streaming: true).toData()
        do {
            let itemStream = try await runRepository.runSSE(data: jsonData)
            var count = 0
            for try await item in itemStream {
                count += 1
                let text = item.content.parts.first?.text ?? ""
                let isPartial = item.partial ?? false
                print("== receive text: \(text)")
                super.receiveMessageStream(text: text, isPartial: isPartial)
            }
            print("stream count: \(count)")
            print("agents count: \(groupMessages.last?.agents.count ?? 0)")
            stopThinking()
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
            print("events: \(events.count)")
            for event in events {
                super.receiveMessage(text: event.content.parts.first?.text ?? "")
            }
            
        } catch {
            debugPrint(error)
        }
    }
}
