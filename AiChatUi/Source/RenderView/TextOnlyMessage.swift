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

extension TextOnlyMessage: BaseRenderView {
    
    static var render: String {
        "text_only"
    }
    
    var body: some View {
        Text(text).background(.green)
    }
}
