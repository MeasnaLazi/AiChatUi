//
//  ModelRender.swift
//  AiChatUi
//
//  Created by Measna on 14/5/25.
//


struct Render {
    let render: String
    let content: any BaseRenderView
    
    enum ModelRenderError: Error {
        case renderView
    }

    enum CodingKeys : String, CodingKey {
        case render = "render"
        case content = "content"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        render = try container.decode(String.self, forKey: .render)

        guard let renderView = RenderViewContext.shared.getMessageRenderView(render: render) else {
            throw ModelRenderError.renderView
        }
        
        content = try container.decode(renderView, forKey: .content)
    }
    
}

extension Render : Decodable {}
