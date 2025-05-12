//
//  MessageContext.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

class MessageViewContext {
    
    private var mapTypeAndModel: [String:BaseMessageView.Type] = [:]
    
    init() {
        registerMessageModel(model: TextOnlyMessage.self)
        registerMessageModel(model: TextSingleImageMessage.self)
    }
    
    func registerMessageModel(model: BaseMessageView.Type) {
        mapTypeAndModel[model.messageType] = model
    }
    
    func getMessageViewType(type: String) -> BaseMessageView.Type {
        guard let model = mapTypeAndModel[type] else {
            return TextOnlyMessage.self
        }
        return model
    }
}

struct Test {
    let message_type: String
    let content: BaseMessageView
    
    enum CodingKeys : String, CodingKey {
        case message_type = "message_type"
        case content = "content"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message_type = try container.decode(String.self, forKey: .message_type)
        
        let chatType = MessageViewContext().getMessageViewType(type: message_type)
        content = try container.decode(chatType, forKey: .content)
    }
}

extension Test : Decodable {}
