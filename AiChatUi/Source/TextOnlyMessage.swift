//
//  TextOnlyMessgae.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

struct TextOnlyMessage {
    var text: String
}

extension TextOnlyMessage : MessageBaseModel {
    static func getMessageType() -> String {
        return "text_only"
    }
    func getMessageView() -> AnyView {
        return AnyView(Text(text))
    }
}
