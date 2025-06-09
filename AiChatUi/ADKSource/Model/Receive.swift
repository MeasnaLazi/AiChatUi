//
//  Receive.swift
//  AiChatUi
//
//  Created by Measna on 6/6/25.
//

struct Receive: Decodable {
    let mimeType: String?
    let data: String?
    let turnComplete: Bool?
    let isInterruped:Bool?
    
    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data = "data"
        case turnComplete = "turn_complete"
        case interruped = "interrupted"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        data = try container.decodeIfPresent(String.self, forKey: .data)
        turnComplete = try container.decodeIfPresent(Bool.self, forKey: .turnComplete)
        isInterruped = try container.decodeIfPresent(Bool.self, forKey: .interruped)
    }
    
}
