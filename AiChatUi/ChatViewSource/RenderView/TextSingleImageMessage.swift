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

extension TextSingleImageMessage: BaseRenderView {
    
    static var render: String {
        "text_single_image"
    }
    
    var body: some View {
        VStack {
            Text(text)
            Text(image)
        }
    }
}
