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

extension TextOnlyMessage : BaseMessageView {
    static var messageType: String {
        "text_only"
    }
    var body: AnyView {
        AnyView(Text(text))
    }
}
