//
//  AnyMessageBaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI
import MarkdownUI
import Splash

public struct MessageView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.aiChatTheme) private var aiChatTheme
    
    let message: Message
    
    public var body: some View {
        switch message.type {
        case .you:
            youView
        case .agent:
            agentView
        }
    }
    
    private var theme: Splash.Theme {
        switch self.colorScheme {
        case .dark:
            return .wwdc17(withFont: .init(size: 16))
        default:
            return .sunset(withFont: .init(size: 16))
        }
    }
    
    @ViewBuilder
    private var youView: some View {
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                Text(message.text)
                    .foregroundColor(aiChatTheme.colors.youMessageViewFG)
                    .padding(10)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .background(aiChatTheme.colors.youMessageViewBG)
            .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .topRight, .bottomLeft]))
            .padding(.leading, 16)
        }
    }
    
    @ViewBuilder
    private var agentView: some View {
        HStack {
            Markdown(message.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .markdownBlockStyle(\.codeBlock) {
                    if $0.language?.lowercased() == "json", let renderView = RenderView(text: $0.content) {
                        renderView
                    } else {
                        CustomCodeBlockView(configuration: $0, theme: theme)
                    }
                }
                .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
                .markdownBlockStyle(\.heading1) { configuration in
                    configuration.label
                        .markdownMargin(top: .em(0.5), bottom: .em(0.5))
                        .markdownTextStyle {
                            FontWeight(.bold)
                            FontSize(.em(1.2))
                        }
                }
                .markdownBlockStyle(\.heading2) { configuration in
                    configuration.label
                        .markdownMargin(top: .em(0.5), bottom: .em(0.5))
                        .markdownTextStyle {
                            FontWeight(.bold)
                            FontSize(.em(1.0))
                        }
                }
                .markdownBlockStyle(\.image) { configuration in
                    configuration.label
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 8, y: 8)
                        .markdownMargin(top: .em(1.6), bottom: .em(1.6))
                }
    //            .markdownImageProvider(.webImage)
                .markdownBulletedListMarker(.dash)
                .markdownNumberedListMarker(.lowerRoman)
                .markdownBlockStyle(\.taskListMarker) { configuration in
                    Image(systemName: configuration.isCompleted ? "checkmark.circle.fill" : "circle")
                        .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
                }
            Spacer()
        }
        .padding(.top)
    }
}
