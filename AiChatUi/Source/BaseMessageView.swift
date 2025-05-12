//
//  BaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

protocol BaseMessageView : Decodable {
    static var messageType: String { get }
    var body: AnyView { get }
}

extension BaseMessageView {
    func toMessageView() -> MessageView {
        return MessageView(self)
    }
}
