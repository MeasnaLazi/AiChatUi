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

extension TextSingleImageMessage : MessageBaseModel {
    static func getMessageType() -> String {
        return "text_single_image"
    }
    func getMessageView() -> AnyView {
        return AnyView(VStack {
            Text(text)
            Text(image)
        })
    }
}
