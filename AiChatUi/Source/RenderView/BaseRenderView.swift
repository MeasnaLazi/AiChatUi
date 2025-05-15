//
//  BaseModel.swift
//  AiChatUi
//
//  Created by Measna on 11/5/25.
//

import SwiftUI

protocol BaseRenderView: View, Decodable {
    static var render: String { get }
}
