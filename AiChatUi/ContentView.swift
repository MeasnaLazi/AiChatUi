//
//  ContentView.swift
//  AiChatUi
//
//  Created by Measna on 27/4/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var inputText: String = ""
    @State private var isShowVoice = false

    var aiChattheme: AiChatTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    private func onSend() {
        let text = inputText
        inputText = ""
        
        chatViewModel.sendMessage(content: text, type: .text)
        Task {
//            await chatViewModel.sendMessageToApi(content: text)
            await chatViewModel.sendMessageToApiStreaming(content: text)
        }
    }
    
    var body: some View {
        NavigationView {
            
            ChatView(viewModel: chatViewModel, inputText: $inputText) { tapType in
                switch tapType {
                case .send:
                    onSend()
                case .voice:
                    print("TODO: Voice")
                    self.isShowVoice.toggle()
                case .stop:
                    print("TODO: Stop")
                    chatViewModel.stopAnswering()
                }
            }
            .sheet(isPresented: $isShowVoice) {
//                AudioView(sessionId: "lazi_session")
                AudioView(session: chatViewModel.session!)
            }
            .aiChatTheme(aiChattheme)
            .navigationTitle("Agent Chat")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear() {
                Task {
                    await chatViewModel.onInitialize()
                }
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
