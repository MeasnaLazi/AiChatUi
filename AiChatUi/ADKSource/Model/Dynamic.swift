//
//  Dynamic.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

enum Dynamic: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case object([String: Dynamic])
    case array([Dynamic])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([Dynamic].self) {
                self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: Dynamic].self) {
            self = .object(objectValue)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.typeMismatch(Dynamic.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
