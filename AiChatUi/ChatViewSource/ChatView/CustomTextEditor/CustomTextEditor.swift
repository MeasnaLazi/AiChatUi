//
//  CustomTextEditor.swift
//  AiChatUi
//
//  Created by Measna on 18/5/25.
//

import SwiftUI

struct CustomTextEditor: View {
    @Environment(\.aiChatTheme) private var theme
    @Binding var text: String
    @State private var dynamicHeight: CGFloat = 36 // Start like TextField height
    @State private var isExpandOpen = false
    var onSendClick: () -> ()
    
    let MAX_HEIGHT: CGFloat = 80

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Ask something")
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.inputPlaceholderTextFG)
                    .padding(.leading, 4)
                    .padding(.top, 9)
            }
            
            TextViewWrapper(text: $text, height: $dynamicHeight)
                .frame(height: min(dynamicHeight, MAX_HEIGHT))
            
            if dynamicHeight > MAX_HEIGHT {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down.left.and.arrow.up.right")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.inputExpandButtonIconFG)
                        .padding(.top, 6)
                        .padding(.trailing, 4)
                        .background(theme.colors.inputBG)
                        .onTapGesture {
                            print("Expand Tap")
                            isExpandOpen.toggle()
                        }
                }
            }
        }
        .sheet(isPresented: $isExpandOpen) {
            FullScreenTextEditorView(text: $text, isExpandOpen: $isExpandOpen) {
                onSendClick()
            }
        }
    }
}

struct FullScreenTextEditorView: View {
    @Environment(\.aiChatTheme) private var theme
    @Binding var text: String
    @Binding var isExpandOpen: Bool
    @State private var dynamicHeight: CGFloat = 36
    
    var onSendClick: () -> ()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                TextViewWrapper(text: $text, height: $dynamicHeight, fontSize: 17.0)
                    .frame(height: UIScreen.main.bounds.height - 160)
                    .padding()
                
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.right.and.arrow.down.left")
                        .font(.system(size: 18).bold())
                        .foregroundColor(theme.colors.inputCollapeButtonIconFG)
                        .background(.clear)
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                        .onTapGesture {
                            isExpandOpen.toggle()
                        }
                }
            }
            
            HStack {
                Spacer()
                Button(action: {
                    isExpandOpen.toggle()
                    onSendClick()
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16))
                        .padding(8)
                        .background(theme.colors.inputSendButtonIconBG)
                        .foregroundColor(theme.colors.inputSendButtonIconFG)
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 20)
        }
    }
}

