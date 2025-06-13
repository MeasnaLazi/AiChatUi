//
//  AudioView.swift
//  AiChatUi
//
//  Created by Measna on 4/6/25.
//

import SwiftUI

struct AudioView: View {
    
    @Environment(\.aiChatTheme) private var theme
    
    @StateObject private var viewModel = AudioViewModel()
    let sessionId: String

    var body: some View {
        ZStack(alignment: .center)  {
            VStack {
                Spacer()
                AudioVisualizerView(audioLevel: $viewModel.audioLevel)
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Text(viewModel.webSocketStatus)
                        .foregroundColor(statusFG())
                    Spacer()
                }
                
                Spacer()

                Button(action: {
                    if viewModel.isStreaming {
                        viewModel.stopConversation()
                    } else {
                        Task {
                            await viewModel.startConversation()
                        }
                   
                    }
                }) {
                        
                Image(systemName: viewModel.isStreaming ? "stop.fill" : "play.fill")
                        .font(.system(size: 16))
                        .padding(8)
                        .background(theme.colors.inputSendButtonIconBG)
                        .foregroundColor(theme.colors.inputSendButtonIconFG)
                        .clipShape(Circle())
                }
                .padding(.bottom, 32)
            }
        }
        .padding(.top)
        .onAppear {
            Task {
                await viewModel.startConnection(sessionId: sessionId)
            }
        }
    }
    
    private func statusFG() -> Color {
        switch viewModel.webSocketStatus {
        case "Connected":
            return .green
        case "Disconnected":
            return .orange
        case "Error":
            return .red
        default:
            return .blue
        }
    }
}

