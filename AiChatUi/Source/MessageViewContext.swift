//
//  MessageContext.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

class MessageViewContext {
    
    static let shared = MessageViewContext()
        
    private init() {
        // Private to prevent external initialization
        registerRenderView(model: TextOnlyMessage.self)
        registerRenderView(model: TextSingleImageMessage.self)
    }
    
    private var mapRenderAndView: [String:BaseMessageView.Type] = [:]
    
    func registerRenderView(model: BaseMessageView.Type) {
        mapRenderAndView[model.render] = model
    }
    
    func getMessageRenderView(render: String) -> BaseMessageView.Type {
        guard let view = mapRenderAndView[render] else {
            return TextOnlyMessage.self
        }
        return view
    }
}
