//
//  AiChatTheme.swift
//  AiChatUi
//
//  Created by Measna on 18/5/25.
//

import SwiftUI


public extension EnvironmentValues {
    #if swift(>=6.0)
      @Entry var aiChatTheme = AiChatTheme()
    #else
        var aiChatTheme: AiChatTheme {
            get { self[AiChatThemeKey.self] }
            set { self[AiChatThemeKey.self] = newValue }
        }
    #endif
}

#if swift(<6.0)
@preconcurrency public struct AiChatThemeKey: EnvironmentKey {
    public static let defaultValue = AiChatTheme()
}
#endif

extension View {
    public func aiChatTheme(_ theme: AiChatTheme) -> some View {
        self.environment(\.aiChatTheme, theme)
    }

    public func aiChatTheme(
        colors: AiChatTheme.Colors = .init()
    ) -> some View {
        self.environment(\.aiChatTheme, AiChatTheme(colors: colors))
    }
}


public struct AiChatTheme {
    public let colors: AiChatTheme.Colors
    
    public init(colors: AiChatTheme.Colors = .init()) {
        self.colors = colors
    }
    
    public struct Colors {
        public var youMessageViewBG: Color
        public var youMessageViewFG: Color
        
        public var inputBG: Color
        public var inputTextFG: Color
        public var inputPlaceholderTextFG: Color
        public var inputButtonIconFG: Color
        public var inputButtonIconBG: Color
        public var inputSendButtonIconFG: Color
        public var inputSendButtonIconBG: Color
        public var inputExpandButtonIconFG: Color
        public var inputCollapeButtonIconFG: Color
        
        public var codeBlockBorder: Color
        public var codeBlockBG: Color
        public var codeBlockHeaderBG: Color
        public var codeBlockHeaderFG: Color
        
        public init(
            
            youMessageViewBG: Color = Color(hex: 0xf2f2f2),
            youMessageViewFG: Color = Color(hex: 0x111111),
            
            inputBG: Color = Color(hex: 0xeff3f4),
            inputTextFG: Color = Color(hex: 0x111111),
            inputPlaceholderTextFG: Color = Color(hex: 0x7e8386),
            inputButtonIconFG: Color = Color(hex: 0x40515e),
            inputButtonIconBG: Color = Color(hex: 0xe3e7e8),
            inputSendButtonIconFG: Color = Color(hex: 0xf7f9f9),
            inputSendButtonIconBG: Color = Color(hex: 0x0f1419),
            inputExpandButtonIconFG: Color = Color(hex: 0x8a8a8e),
            inputCollapeButtonIconFG: Color = Color(hex: 0x000000),
            
            codeBlockHeaderBorder: Color = Color(hex: 0xd7d7d7),
            codeBlockBG: Color = Color(hex: 0xffffff),
            codeBlockHeaderBG: Color = Color(hex: 0xefefef),
            codeBlockHeaderFG: Color = Color(hex: 0x000000)

        ) {
            self.youMessageViewBG = youMessageViewBG
            self.youMessageViewFG = youMessageViewFG
            
            self.inputBG = inputBG
            self.inputTextFG = inputTextFG
            self.inputPlaceholderTextFG = inputPlaceholderTextFG
            self.inputButtonIconFG = inputButtonIconFG
            self.inputButtonIconBG = inputButtonIconBG
            self.inputSendButtonIconFG = inputSendButtonIconFG
            self.inputSendButtonIconBG = inputSendButtonIconBG
            self.inputExpandButtonIconFG = inputExpandButtonIconFG
            self.inputCollapeButtonIconFG = inputCollapeButtonIconFG
            
            self.codeBlockBorder = codeBlockHeaderBorder
            self.codeBlockBG = codeBlockBG
            self.codeBlockHeaderBG = codeBlockHeaderBG
            self.codeBlockHeaderFG = codeBlockHeaderFG
        }
    }
}

extension AiChatTheme {
    static let light = AiChatTheme(colors: .init(
        inputBG: Color(hex: 0xeff3f4),
        inputTextFG: Color(hex: 0x111111),
        inputPlaceholderTextFG: Color(hex: 0x7e8386)
    ))
    
    static let dark = AiChatTheme(colors: .init(
        inputBG: Color(hex: 0x1e1e1e),
        inputTextFG: Color(hex: 0xffffff),
        inputPlaceholderTextFG: Color(hex: 0xaaaaaa)
    ))
}
