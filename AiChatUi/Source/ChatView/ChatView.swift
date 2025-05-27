//
//  ChatView.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

public struct ChatView: View {
    @Environment(\.aiChatTheme) private var theme
    @Environment(\.pixelLength) private var pixelLength
    
    @ObservedObject private var viewModel: BaseChatViewModel
    @Binding private var inputText: String
    
    var onSendClicked: (() -> ())?
    
    public init(viewModel: BaseChatViewModel, inputText: Binding<String>, onSendClicked: (() -> ())? = nil) {
        self.viewModel = viewModel
        self._inputText =  inputText
        self.onSendClicked = onSendClicked
    }
    
    public var body: some View {
        VStack {
            listView
            inputView
        }
        .animation(.easeInOut, value: viewModel.groupMessages)
    }
    
    @ViewBuilder
    private var listView: some View {
        GeometryReader { geoReader in
            let scrollViewHeight = geoReader.size.height + 50
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.groupMessages, id: \.id) { groupMessage in
                        VStack {
                            MessageView(message: groupMessage.you)
                            ForEach(groupMessage.agents) { message in
                                MessageView(message: message)
                            }
                        }
                        .frame(
                            minHeight: (groupMessage.id == viewModel.groupMessages.last?.id && !viewModel.isInitMessages) ? scrollViewHeight : nil,
                            alignment: .top
                        )
                        .id(groupMessage.id)
                        .padding(.top)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
            }
            .scrollPosition(id: $viewModel.scrollPositionUUID, anchor: viewModel.isInitMessages ? .bottom : .top)
            .onChange(of: viewModel.groupMessages) {
                let WAIT_VIEW_RENDER = 1.0
                if let lastMessageId = viewModel.groupMessages.last?.id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + WAIT_VIEW_RENDER) {
                        viewModel.scrollPositionUUID = lastMessageId
                    }
                }
            }
        }
        .padding(.top, pixelLength)
    }
    
    @ViewBuilder
    private var inputView: some View {
        VStack {
            CustomTextEditor(text: $inputText) {
                onSendClick()
            }
            .padding([.leading, .trailing], 12)
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
                  onSendClick()
                }) {
                    if inputText.isEmpty {
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
            .padding([.leading, .trailing], 12)
            .padding(.bottom, 8)
        }
        .background(theme.colors.inputBG)
        .cornerRadius(12)
        .padding([.top, .bottom], 6)
        .padding([.leading, .trailing], 12)
    }
    
    private func onSendClick() {
        if !inputText.isEmpty, let onSendClicked {
            onSendClicked()
        }
    }
}
