//
//  ContentView.swift
//  AiChatUi
//
//  Created by Measna on 27/4/25.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme

    var aiChattheme: AiChatTheme {
        colorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        NavigationView {
            ChatView()
                .aiChatTheme(aiChattheme)
                .navigationTitle("Chat")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
