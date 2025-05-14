//
//  ChatView.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

// Main Chat View
struct ChatView: View {
    @ObservedObject private var viewModel = ChatViewModel()
    @State private var userInput = ""
    
    var body: some View {
        VStack {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            message.body()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { old, new in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id)
                    }
                }
            }
            
            // Input area
            HStack {
                TextField("Type a message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !userInput.isEmpty {
//                        viewModel.addMessgae(message: TextOnlyMessage(text: userInput).toMessageView())
//                        userInput = ""
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                
                // Additional input types (file, voice, video)
                Menu {
//                    Button("Send File") { viewModel.addUserMessage(content: .file(URL(string: "https://example.com/file.pdf")!)) }
//                    Button("Send Voice") { viewModel.addUserMessage(content: .voice(URL(string: "https://example.com/voice.mp3")!)) }
//                    Button("Send Video") { viewModel.addUserMessage(content: .video(URL(string: "https://example.com/video.mp4")!)) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .animation(.easeInOut, value: viewModel.messages)
//        .overlay(
//            Group {
//                if viewModel.isLoading {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle())
//                }
//            }
//        )
        .onAppear() {
            
            if let url = Bundle.main.url(forResource: "test", withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: url)
                        let decoder = JSONDecoder()
                        let jsonData = try decoder.decode(Response.self, from: data)
//                        let messageContent = MessageContent(text: jsonData.content)
                        let body = MessageView(text: jsonData.content)
                        viewModel.addMessgae(message: body)
//                        viewModel.addMessgae(message: jsonData.content.toMessageView())
                        
//                        let jsonData = try decoder.decode(MarkDownMessageView.self, from: data)
                    } catch {
                        print("error:\(error)")
                    }
                }
            
//            let jsonTextOnly = """
//                {   
//                    message_type: "text_only",
//                    content: {
//                        text: "Hii"
//                    }
//                }
//                """
//            let jsonTextSingleImage = """
//                {   
//                    "message_type": "text_single_image",
//                    "content": {
//                        "text": "hi",
//                        "image": "lazi!"
//                    }
//                }
//                """
            
           

//            if let test = try? decoder.decode(Test.self, from: data) {
////                print("test: \(test.content)")
//                viewModel.addMessgae(message: test.content.toMessageView())
//            } else {
//                print("failed!!")
//            }
        }
    }
}
