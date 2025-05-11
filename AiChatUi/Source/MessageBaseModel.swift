//
//  BaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

protocol MessageBaseModel: Decodable {
    static func getMessageType() -> String
    func getMessageView() -> AnyView
}

extension MessageBaseModel {
    func toMessageView() -> MessageView {
        return MessageView(self)
    }
}
