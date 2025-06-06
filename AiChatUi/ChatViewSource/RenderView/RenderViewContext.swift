//
//  MessageContext.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

class RenderViewContext {
    static let shared = RenderViewContext()
    private var mapRenderAndView: [String:any BaseRenderView.Type] = [:]
        
    private init() {
        registerRenderView(model: TextOnlyMessage.self)
        registerRenderView(model: TextSingleImageMessage.self)
    }
    
    func registerRenderView(model: any BaseRenderView.Type) {
        mapRenderAndView[model.render] = model
    }
    
    func getMessageRenderView(render: String) -> (any BaseRenderView.Type)? {
        guard let view = mapRenderAndView[render] else {
            return nil
        }
        return view
    }
}
