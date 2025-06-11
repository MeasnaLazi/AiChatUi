//
//  PushToTalkButton.swift
//  AiChatUi
//
//  Created by Measna on 10/6/25.
//

import SwiftUI

struct PushToTalkButton: View {
    // Get the ViewModel from the environment
    @EnvironmentObject var viewModel: AudioViewModel

    // State to manage the button appearance
    @State private var isRecording = false

    var body: some View {
        VStack {
            Text(isRecording ? "Listening..." : "Hold to Talk")
                .font(.headline)
                .padding()

            Image(systemName: "mic.fill")
                .font(.system(size: 50))
                .foregroundColor(isRecording ? .red : .gray)
                .padding(30)
                .background(isRecording ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                .clipShape(Circle())
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            // This is called as soon as the user touches down
                            if !isRecording {
                                self.isRecording = true
                                viewModel.startRecording()
                            }
                        }
                        .onEnded { _ in
                            // This is called when the user lifts their finger
                            self.isRecording = false
                            viewModel.stopRecording()
                        }
                )
        }
        .animation(.spring(), value: isRecording)
    }
}
