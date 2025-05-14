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
    static var render: String {
        "text_only"
    }
    var body: AnyView {
        AnyView(Text(text).background(.green))
    }
}
