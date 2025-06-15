//
//  AudioView.swift
//  AiChatUi
//
//  Created by Measna on 4/6/25.
//

import SwiftUI

struct AudioView: View {
    
    @StateObject private var viewModel = AudioViewModel()
    let session: Session

    var body: some View {
        ZStack(alignment: .center)  {
            VStack {
                Spacer()
                AudioVisualizerView(audioLevel: $viewModel.audioLevel)
                Spacer()
            }
            
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
                    .font(.system(size: 24))
                    .padding(12)
                    .background(Color(hex: 0x1e1e1e))
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
            }
            
            VStack {
                HStack {
                    Spacer()
                    Text(viewModel.webSocketStatus)
                        .foregroundColor(statusFG())
                    Spacer()
                }
                
                Spacer()
            }
        }
        .padding(.top)
        .onAppear {
            Task {
                await viewModel.startConnection(session: session)
            }
        }
        .onDisappear {
            viewModel.cleanUp()
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

