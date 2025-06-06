//
//  AudioView.swift
//  AiChatUi
//
//  Created by Measna on 4/6/25.
//

import SwiftUI

struct AudioView: View {
    
    @StateObject private var viewModel = AudioViewModel()
    let sessionId: String

    var body: some View {
        VStack(spacing: 20) {
            AudioVisualizerView(audioLevel: $viewModel.audioLevel)
            
            Text(viewModel.isStreaming ? "Streaming..." : "Stopped")
                .font(.headline)

            Button(action: {
                if viewModel.isStreaming {
                    viewModel.stopStreaming()
                } else {
                    Task { await viewModel.startConversation() }
                }
            }) {
                Text(viewModel.isStreaming ? "Stop" : "Start")
                    .padding()
                    .background(viewModel.isStreaming ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .onAppear() {
            Task {
                await viewModel.initilize(sessionId: sessionId)
            }
        }
    }
}

