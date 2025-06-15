//
//  AudioView.swift
//  AiChatUi
//
//  Created by Measna on 15/6/25.
//

import SwiftUI

struct VideoView: View {
    
    @StateObject private var viewModel = VideoViewModel()
    let sessionId: String

    var body: some View {
        ZStack(alignment: .center)  {
            
            CameraPreviewView(session: viewModel.cameraLivePlayer.captureSession)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.red)
                .ignoresSafeArea()
            
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
            viewModel.cameraLivePlayer.startCamera()
            Task {
                await viewModel.startConnection(sessionId: sessionId)
            }
        }
        .onDisappear {
            viewModel.cameraLivePlayer.stopCamera()
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

