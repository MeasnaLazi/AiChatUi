//
//  AnyMessageBaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI
import MarkdownUI

//struct MessageView: Identifiable, Equatable {
//    let id: UUID = UUID()
//    let viewProvider: () -> AnyView
//    private let model: any BaseMessageView
//
//    init(_ model: some BaseMessageView) {
//        self.model = model
//        self.viewProvider = { model.body }
//    }
//
//    func getBody() -> AnyView {
//        viewProvider()
//    }
//    
//    func getModel() -> BaseMessageView {
//        model
//    }
//    
//    static func == (lhs: Self, rhs: Self) -> Bool {
//        lhs.id == rhs.id
//    }
//}

struct MessageView: Identifiable, Equatable {
    let id: UUID = UUID()
    let text: String
    let body: () -> AnyView
    
    init(text: String) {
        self.text = text
        self.body = {
            AnyView(
                Markdown(text)
                    .markdownBlockStyle(\.codeBlock) {
                        if $0.language == "json" {
                           
                            Text($0.content)
                                .background(.yellow)
                            ModelRenderView(text: $0.content)
                        } else {
                            $0.label
                        }
                    }
            )
        }
    }
    
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

