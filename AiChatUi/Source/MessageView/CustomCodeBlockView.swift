//
//  CustomCodeBlockView.swift
//  AiChatUi
//
//  Created by Measna on 14/5/25.
//

import SwiftUI
import MarkdownUI
import Splash

struct CustomCodeBlockView: View {
    @Environment(\.aiChatTheme) private var aiChatTheme
    
    @State private var isCopied: Bool = false
    
    let configuration: CodeBlockConfiguration
    let theme: Splash.Theme
    let WAIT_IN_SEC_AFTER_CLICK_COPIED = 3.0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(configuration.language ?? "plain text")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(aiChatTheme.colors.codeBlockHeaderFG)
                
                Spacer()
                
                HStack {
                    Text(isCopied ? "Copied" : "Copy")
                        .font(.system(size: 12))
                    Image(systemName: isCopied ? "checkmark" : "document.on.document")
                        .font(.system(size: 11))
                }
                .onTapGesture {
                    isCopied.toggle()
                    copyToClipboard(configuration.content)
                    DispatchQueue.main.asyncAfter(deadline: .now() + WAIT_IN_SEC_AFTER_CLICK_COPIED) {
                        isCopied.toggle()
                    }
                    
                }
  
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background {
                Color(aiChatTheme.colors.codeBlockHeaderBG)
            }

            Divider()
          
            ScrollView(.horizontal) {
                configuration.label
                    .relativeLineSpacing(.em(0.25))
                    .markdownTextStyle {
                          FontFamilyVariant(.monospaced)
                          FontSize(.em(0.85))
                    }
                    .padding()
            }
        }
        .background(aiChatTheme.colors.codeBlockBG)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(aiChatTheme.colors.codeBlockBorder, lineWidth: 1)
        }
        .markdownMargin(top: .zero, bottom: .em(0.8))
    }
    
    private func copyToClipboard(_ string: String) {
        #if os(macOS)
        if let pasteboard = NSPasteboard.general {
            pasteboard.clearContents()
            pasteboard.setString(string, forType: .string)
        }
        #elseif os(iOS)
            UIPasteboard.general.string = string
        #endif
    }
}
