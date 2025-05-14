////
////  MainMessageView.swift
////  AiChatUi
////
////  Created by Measna on 13/5/25.
////
//
//import Markdown
//import SwiftUI
//
//struct MessageContent {
//    let text: String
//    let jsonTexts: [String]
//    
//    init(text: String) {
//        let document = Document(parsing: text)
//        
//        // Get only json block
//        var jsonBlocks: [CodeBlock] = []
//        for child in document.children {
//            if let jsonBlock = child as? CodeBlock, jsonBlock.language == "json" {
//                jsonBlocks.append(jsonBlock)
//            }
//        }
//        
//        // Get only text from json block
//        self.jsonTexts = jsonBlocks.map { $0.code }
//        
//        // Get text without json block
//        let removeJsonsDocument = Document(jsonBlocks.compactMap { $0 })
//        self.text = removeJsonsDocument.format()
//    }
//    
//    //struct Test {
//    //    let message_type: String
//    //    let content: BaseMessageView
//    //
//    //    enum CodingKeys : String, CodingKey {
//    //        case message_type = "message_type"
//    //        case content = "content"
//    //    }
//    //
//    //    init(from decoder: Decoder) throws {
//    //        let container = try decoder.container(keyedBy: CodingKeys.self)
//    //        message_type = try container.decode(String.self, forKey: .message_type)
//    //
//    //        let chatType = MessageViewContext().getMessageViewType(type: message_type)
//    //        content = try container.decode(chatType, forKey: .content)
//    //    }
//    //}
//    //
//    //extension Test : Decodable {}
//}
