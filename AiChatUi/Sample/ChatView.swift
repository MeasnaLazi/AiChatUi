//
//  ChatView.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

// Main Chat View
struct ChatView: View {
    @Environment(\.aiChatTheme) private var theme
    
    @ObservedObject private var viewModel = ChatViewModel()
    @State private var askSomethingTextField = ""
    
    @Environment(\.pixelLength) private var pixelLength
    @State private var scrollPositionUUID: UUID?
    
    var body: some View {
        VStack {
            listView
            inputView
        }
        .animation(.easeInOut, value: viewModel.messageViews)
        .onAppear() {
            let youMessageView = MessageView(text: "Hey, hi!", type: .you)
            viewModel.addMessageView(messageView: youMessageView)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let url = Bundle.main.url(forResource: "test", withExtension: "json") {
                        do {
                            let data = try Data(contentsOf: url)
                            let decoder = JSONDecoder()
                            let jsonData = try decoder.decode(Response.self, from: data)
                            let agentMessageView = MessageView(text: jsonData.content, type: .agent)
                            viewModel.addMessageView(messageView: agentMessageView)
                        } catch {
                            print("error:\(error)")
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var listView: some View {
        GeometryReader { geoReader in
            let scrollViewHeight = geoReader.size.height
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.messageViews, id: \.id) { messageView in
                        messageView
                            .id(messageView.id)
                            .frame(
                                minHeight: messageView.id == viewModel.messageViews.last?.id ? scrollViewHeight : nil,
                                alignment: .top
                            )
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
            }
            .scrollPosition(id: $scrollPositionUUID, anchor: .top)
        }
        .padding(.top, pixelLength)
    }
    
    @ViewBuilder
    private var inputView: some View {
        VStack {
            TextField("", text: $askSomethingTextField, prompt: Text("Ask something").foregroundColor(theme.colors.inputPlaceholderTextFG))
                .font(.system(size: 16))
                .foregroundColor(theme.colors.inputTextFG)
                .overlay(EmptyView())
                .background(.clear)
                .padding([.leading, .trailing])
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            HStack {
                Button(action: {
                    print("file clicked!")
                }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 13))
                        .padding(6)
                        .background(theme.colors.inputButtonIconBG)
                        .foregroundColor(theme.colors.inputButtonIconFG)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                Button(action: {
                    if !askSomethingTextField.isEmpty {
                        let messageView = MessageView(text: askSomethingTextField, type: .you)
                        viewModel.addMessageView(messageView: messageView)
                        withAnimation {
                            scrollPositionUUID = messageView.id
                        }
                        askSomethingTextField = ""
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let assistantMessage = MessageView(text: "Hold on!", type: .agent )
                            viewModel.addMessageView(messageView: assistantMessage)
                        }
                    }
                }) {
                    if askSomethingTextField.isEmpty {
                        Image(systemName: "waveform" )
                            .font(.system(size: 16))
                            .foregroundColor(theme.colors.inputButtonIconFG)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14))
                            .padding(6)
                            .background(theme.colors.inputSendButtonIconBG)
                            .foregroundColor(theme.colors.inputSendButtonIconFG)
                            .clipShape(Circle())
                    }
      
                }
            }
            .padding([.leading, .trailing])
            .padding(.bottom, 8)
        }
        .background(theme.colors.inputBG)
        .cornerRadius(12)
        .padding([.top, .bottom], 6)
        .padding([.leading, .trailing], 12)
    }
}
