//
//  Response.swift
//  AiChatUi
//
//  Created by Measna on 13/5/25.
//

struct Response {
    let content: String
    
    enum CodingKeys : String, CodingKey {
        case content = "content"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode(String.self, forKey: .content)
    }
}

extension Response : Decodable {}

//struct Test {
//    let message_type: String
//    let content: BaseMessageView
//    
//    enum CodingKeys : String, CodingKey {
//        case message_type = "message_type"
//        case content = "content"
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        message_type = try container.decode(String.self, forKey: .message_type)
//        
//        let chatType = MessageViewContext().getMessageViewType(type: message_type)
//        content = try container.decode(chatType, forKey: .content)
//    }
//}
//
//extension Test : Decodable {}
