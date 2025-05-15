//
//  CustomCodeBlockView.swift
//  AiChatUi
//
//  Created by Measna on 14/5/25.
//

import SwiftUI
import MarkdownUI
import Splash

struct CustomCodeBlock: View {
    @State private var isCopied: Bool = false
    
    let configuration: CodeBlockConfiguration
    let theme: Splash.Theme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(configuration.language ?? "plain text")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(theme.plainTextColor))
                
                Spacer()

                Image(systemName: isCopied ? "list.bullet.clipboard" : "clipboard")
                    .onTapGesture {
                        print("copy click")
                        isCopied.toggle()
                        copyToClipboard(configuration.content)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            isCopied.toggle()
                        }
                        
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background {
                Color(theme.backgroundColor)
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
