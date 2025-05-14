//
//  ModelView.swift
//  AiChatUi
//
//  Created by Measna on 13/5/25.
//
import SwiftUI
struct ModelRenderView: View {
    let text: String
    let renderView: AnyView
    
    init(text: String) {
        self.text = text
        if let data = text.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let modelRender = try? decoder.decode(ModelRender.self, from: data) {
                renderView = modelRender.content.toAnyView()
            } else {
                renderView = AnyView(EmptyView())
            }
        } else {
            renderView = AnyView(EmptyView())
        }
    }
    
    var body: some View {
        renderView
    }
}

struct ModelRender {
    let render: String
    let content: BaseMessageView

    enum CodingKeys : String, CodingKey {
        case render = "render"
        case content = "content"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        render = try container.decode(String.self, forKey: .render)

        let chatType = MessageViewContext.shared.getMessageRenderView(render: render)
        content = try container.decode(chatType, forKey: .content)
    }
    
}

extension ModelRender : Decodable {}
