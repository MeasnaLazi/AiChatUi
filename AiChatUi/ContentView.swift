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

    var aiChattheme: AiChatTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    private func onSend() {
//        let text = inputText
//        inputText = ""
//        
//        chatViewModel.sendMessage(content: text, type: .text)
//        Task {
//            await chatViewModel.sendMessageToApi(content: text)
//        }
        
                let temText = inputText
                inputText = ""

                var end = ""

                chatViewModel.sendMessage(content: temText, type: .text)

                if temText.lowercased().contains("code") {
                    end = "code"
                } else if temText.lowercased().contains("room") {
                    end = "stay"
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) {
                    if end == "" {
                        let _ = chatViewModel.receiveMessage(text: "Hold on!")
                        return
                    }
                    if let url = Bundle.main.url(forResource: "response_\(end)", withExtension: "json") {
                            do {
                                let data = try Data(contentsOf: url)
                                let decoder = JSONDecoder()
                                let jsonData = try decoder.decode(Response.self, from: data)
                                let _ = chatViewModel.receiveMessage(text: jsonData.content)
                            } catch {
                                print("error:\(error)")
                            }
                        }
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
                case .stop:
                    print("TODO: Stop")
                }
            }
            .aiChatTheme(aiChattheme)
            .navigationTitle("Agent Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear() {
            RenderViewContext.shared.registerRenderView(model: StayMessageRender.self)
            RenderViewContext.shared.registerRenderView(model: AirbnbRenderView.self)
            Task {
                await chatViewModel.onInitialize()
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
