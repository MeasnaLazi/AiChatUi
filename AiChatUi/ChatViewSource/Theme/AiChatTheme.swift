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
        
        public var thinkingFG: Color
        
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
            codeBlockHeaderFG: Color = Color(hex: 0x000000),
            
            thinkingFG: Color = Color(hex: 0xAAAAAA)

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
            
            self.thinkingFG = thinkingFG
        }
    }
}

extension AiChatTheme {
    static let light = AiChatTheme(colors: .init())
    
    static let dark = AiChatTheme(colors: .init(
        youMessageViewBG: Color(hex: 0x212121),
        youMessageViewFG: Color.white,
        
        inputBG: Color(hex: 0x202327),
        inputTextFG: Color.white,
        inputPlaceholderTextFG: Color(hex: 0x7d7e80),
        inputButtonIconFG: Color(hex: 0x91969a),
        inputButtonIconBG: Color(hex: 0x2b2e32),
        inputSendButtonIconFG: Color(hex: 0x1e1e1e),
        inputSendButtonIconBG: Color.white,
        inputExpandButtonIconFG: Color(hex: 0x99999f),
        inputCollapeButtonIconFG: Color.white,
        
        codeBlockHeaderBorder: Color(hex: 0x202020),
        codeBlockBG: Color.black,
        codeBlockHeaderBG: Color(hex: 0x070707),
        codeBlockHeaderFG: Color(hex: 0xb5b5b4),
        
        thinkingFG: Color.white
    ))
}
