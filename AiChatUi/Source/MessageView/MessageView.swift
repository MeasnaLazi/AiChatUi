//
//  AnyMessageBaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI
import MarkdownUI
import Splash

struct MessageView: View, Identifiable, Equatable {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let id: UUID = UUID()
    let text: String
    
    var body: some View {
        Markdown(text)
            .markdownBlockStyle(\.codeBlock) {
                if $0.language == "json", let renderView = RenderView(text: $0.content) {
                    renderView
                } else {
                    CustomCodeBlock(configuration: $0, theme: theme)
                }
            }
            .markdownCodeSyntaxHighlighter(.splash(theme: self.theme))
            .markdownBlockStyle(\.heading1) { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.5), bottom: .em(0.5))
                    .markdownTextStyle {
                        FontFamily(.custom("Trebuchet MS"))
                        FontWeight(.bold)
                        FontSize(.em(1.2))
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
    }
    
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    private var theme: Splash.Theme {
        switch self.colorScheme {
        case .dark:
            return .wwdc17(withFont: .init(size: 16))
        default:
            return .sunset(withFont: .init(size: 16))
        }
    }
}
