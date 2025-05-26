//
//  Responable.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

public protocol Responable {
    static func decode(_ data: Data) throws -> Self
}

extension Responable where Self: Decodable {
    public static func decode(_ data: Data) throws -> Self {
        return try _decoder.decode(Self.self, from: data)
    }
}

private let _decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

extension Bool: Responable {}
