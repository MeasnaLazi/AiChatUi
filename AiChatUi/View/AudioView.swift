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

//                Button(action: {
//                    if viewModel.isSpeaking {
//                        viewModel.stopSpeaking()
//                    } else {
//                        Task { await viewModel.startSpeaking() }
//                    }
//                }) {
//                        
//                Image(systemName: viewModel.isSpeaking ? "stop.fill" : "play.fill")
//                        .font(.system(size: 16))
//                        .padding(8)
//                        .background(theme.colors.inputSendButtonIconBG)
//                        .foregroundColor(theme.colors.inputSendButtonIconFG)
//                        .clipShape(Circle())
//                }
//                .padding(.bottom, 32)
                
                Image(systemName: "mic.fill")
                                .font(.system(size: 24))
                                .padding(20)
                                .background(viewModel.isSpeaking ? theme.colors.inputSendButtonIconBG.opacity(0.7) : theme.colors.inputSendButtonIconBG)
                                .foregroundColor(theme.colors.inputSendButtonIconFG)
                                .clipShape(Circle())
                                .scaleEffect(viewModel.isSpeaking ? 1.2 : 1.0) // 2. Add a scaling effect for visual feedback.
                                .gesture(longPressGesture()) // 3. Attach the custom long-press gesture.
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isSpeaking) // 4. Animate the changes.
                                .padding(.bottom, 32)
            }
        }
        .padding(.top)
        .onAppear {
            Task {
                await viewModel.startConnection(sessionId: sessionId)
            }
        }
        .onDisappear {
            viewModel.endConnection()
        }
    }
    
    private func longPressGesture() -> some Gesture {
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !viewModel.isSpeaking else { return }
                    viewModel.isSpeaking = true
                                    
                    Task {
                        do {
                            try await viewModel.startSpeaking()
                        } catch {
                            print("Error starting to speak: \(error.localizedDescription)")
                            await MainActor.run {
                                viewModel.isSpeaking = false
                            }
                        }
                    }
                }
                .onEnded { _ in
                    if viewModel.isSpeaking {
                        viewModel.stopSpeaking()
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

