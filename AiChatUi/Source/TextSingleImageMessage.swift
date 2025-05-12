//
//  TextSingleImageMessage.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

struct TextSingleImageMessage {
    var text: String
    var image: String
}

extension TextSingleImageMessage : BaseMessageView {
    static var messageType: String {
        "text_single_image"
    }
    var body: AnyView {
        AnyView(
            VStack {
                Text(text)
                Text(image)
            }
        )
    }
}
