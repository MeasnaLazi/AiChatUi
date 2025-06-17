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
        VStack {
            statusView
            
            CameraPreviewView(session: viewModel.cameraLivePlayer.captureSession)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            controlView
            
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
    
    @ViewBuilder
    private var statusView: some View {
        HStack {
            Spacer()
            Text(viewModel.webSocketStatus)
                .foregroundColor(statusFG())
                .padding(.bottom, 4)
            Spacer()
        }
        .background(.black)
    }
    
    @ViewBuilder
    private var controlView: some View {
        HStack(alignment: .center) {
            Button(action: {
                print("flash")
            }) {
                Image(systemName: viewModel.isStreaming ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 24))
                    .padding(10)
                    .background(Color(hex: 0x1e1e1e))
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
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
                    .font(.system(size: 30))
                    .padding(20)
                    .background(Color(hex: 0x1e1e1e))
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
            }
            Spacer()
            Button(action: {
                print("switch")
            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.system(size: 24))
                    .padding(10)
                    .background(Color(hex: 0x1e1e1e))
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.black)
    }
}

