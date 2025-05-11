//
//  MessageContext.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import Foundation

class MessageContext {
    private var baseModels: [MessageBaseModel.Type] = [TextOnlyMessage.self, TextSingleImageMessage.self]
//    init() {
//        for baseModel in baseModels {
//            print("message type: \(baseModel.getMessageType())")
//        }
//    }
    
    func getMessageViewType(type: String) -> MessageBaseModel.Type {
        if let find = baseModels.first(where: {$0.getMessageType() == type}) {
            return find
        }
        return TextOnlyMessage.self
    }
}

struct Test {
    let message_type: String
    let content: MessageBaseModel
    
    enum CodingKeys : String, CodingKey {
        case message_type = "message_type"
        case content = "content"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message_type = try container.decode(String.self, forKey: .message_type)
        let chatType = MessageContext().getMessageViewType(type: message_type)
        content = try container.decode(chatType, forKey: .content)
    }
}

extension Test : Decodable {}
