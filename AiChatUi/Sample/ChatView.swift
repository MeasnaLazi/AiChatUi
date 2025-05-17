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
    
    @Environment(\.pixelLength) private var pixelLength
    @State private var scrollPosition: UUID?
    
    var body: some View {
        VStack {
            GeometryReader { geoProxy in
                let scrollViewHeight = geoProxy.size.height
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.messages, id: \.id) { message in
                   
                            message
                                .id(message.id)
                                .frame(
                                    minHeight: message.id == viewModel.messages.last?.id ? scrollViewHeight : nil,
                                    alignment: .top
                                )
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal)
                }
                .scrollPosition(id: $scrollPosition, anchor: .top)
            }
            .padding(.top, pixelLength)
            
            // Input area
            HStack {
                TextField("Type a message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !userInput.isEmpty {
                        let message = MessageView(text: userInput, type: .you)
                        viewModel.addMessgae(message: message)
                        withAnimation {
                            scrollPosition = message.id
                        }
                        userInput = ""
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let assistantMessage = MessageView(text: "Hold on, let me fetch the best answer for you!", type: .agent )
                            viewModel.addMessgae(message: assistantMessage)
                        }
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
                        let body = MessageView(text: jsonData.content, type: .agent)
                        viewModel.addMessgae(message: body)
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
