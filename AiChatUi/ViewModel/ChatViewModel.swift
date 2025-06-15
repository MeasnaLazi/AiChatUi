//
//  ChatViewModel.swift
//  AiChatUi
//
//  Created by Measna on 19/5/25.
//
import SwiftUI

class ChatViewModel: BaseChatViewModel {
    
    private let adkRepository: SessionRepository = SessionRepositoryImp(requestExecute: APIClient())
    private let runRepository: RunRepository = RunRepositoryImp(requestExecute: APIClient())
    var session: Session?
    var streamTask: Task<Void, Never>? = nil
    
    func onInitialize() async {
        do {
            let existSesstion = try? await adkRepository.getSession(user: "lazi", session: "lazi_session")
            guard let session = existSesstion else {
                self.session = try await adkRepository.startSession(user: "lazi", session: "lazi_session")
                return
            }
            
//            print("ChatViewModel: session - \(session)")
            
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
        streamTask = Task {
            do {
                let itemStream = try await runRepository.runSSE(data: jsonData)
                var count = 0
                
                for try await item in itemStream {
                    count += 1
                    let text = item.content.parts.first?.text ?? ""
                    let isPartial = item.partial ?? false
                    super.receiveMessageStream(text: text, isPartial: isPartial)
                }
                print("ChatViewModel: stream count: \(count)")
                print("ChatViewModel: agents count: \(groupMessages.last?.agents.count ?? 0)")
                stopAnswering()
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func sendMessageToApi(content: String) async {
        guard let session = session else {
            return
        }
        let jsonData = session.buildNewMesssageDictionary(text: content).toData()
        do {
            let events = try await runRepository.run(data: jsonData)
            print("ChatViewModel: events: \(events.count)")
            for event in events {
                super.receiveMessage(text: event.content.parts.first?.text ?? "")
            }
            
        } catch {
            debugPrint(error)
        }
    }
    
    override func stopAnswering() {
        super.stopAnswering()
        streamTask?.cancel()
        streamTask = nil
    }
    
    deinit {
        streamTask?.cancel()
        streamTask = nil
    }
}
