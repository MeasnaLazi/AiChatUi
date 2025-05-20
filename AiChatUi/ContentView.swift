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
    
    var body: some View {
        NavigationView {
            ChatView(viewModel: chatViewModel, inputText: $inputText) {
                let messageView = chatViewModel.sendMessage(content: inputText, type: .text)
                inputText = ""
                return messageView
            }
            .aiChatTheme(aiChattheme)
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
