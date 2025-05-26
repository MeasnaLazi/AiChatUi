//
//  Responable.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

public protocol Responable {
    static func decode(_ data: Data) throws -> Self
    static func decode(from stream: AsyncThrowingStream<Data, Error>) -> AsyncThrowingStream<Self, Error>
}

extension Responable where Self: Decodable {
    public static func decode(_ data: Data) throws -> Self {
        return try _decoder.decode(Self.self, from: data)
    }
    
    public static func decode(from stream: AsyncThrowingStream<Data, Error>) -> AsyncThrowingStream<Self, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                var lineBuffer = ""
                var currentEventData: [String] = []
                var currentEventName: String? = nil
                var lastEventId: String? = nil

                do {
                    for try await dataChunk in stream {
                        if let chunkString = String(data: dataChunk, encoding: .utf8) {
                            lineBuffer += chunkString
                        } else {
                            print("Received non-UTF8 data chunk.")
                            continue
                        }

                        while let newlineIndex = lineBuffer.firstIndex(where: { $0.isNewline }) {
                            let line = String(lineBuffer.prefix(upTo: newlineIndex)).trimmingCharacters(in: .whitespaces)
                            lineBuffer.removeSubrange(...newlineIndex)

                            if line.isEmpty {
                                if !currentEventData.isEmpty {
                                    let eventDataString = currentEventData.joined(separator: "\n")
                                    do {
                                        if let jsonData = eventDataString.data(using: .utf8) {
                                            let decodedItem = try _decoder.decode(Self.self, from: jsonData)
                                            print("Successful decode!")
                                            continuation.yield(decodedItem)
                                        } else {
                                            print("Could not convert event data string to Data.")
                                        }
                                    } catch {
                                        print("FAILED TO DECODE item from \"\(eventDataString)\". Error: \(error)")
                                    }
                                    currentEventData.removeAll()
                                    currentEventName = nil // Reset for next event
                                } else {
                                    print("Empty line encountered, but no current event data to process.")
                                }
                                continue
                            }

                            if line.hasPrefix("id:") {
                                lastEventId = line.dropFirst("id:".count).trimmingCharacters(in: .whitespaces)
                                print("Parsed ID: \(lastEventId ?? "")")
                            } else if line.hasPrefix("event:") {
                                currentEventName = line.dropFirst("event:".count).trimmingCharacters(in: .whitespaces)
                                print("Parsed Event Name: \(currentEventName ?? "")")
                            } else if line.hasPrefix("data:") {
                                let dataContent = String(line.dropFirst("data:".count).trimmingCharacters(in: .whitespacesAndNewlines))
                                currentEventData.append(dataContent)
                                print("Appended data line: \"\(dataContent)\"")
                            } else if line.hasPrefix(":") {
                                print("Comment ignored: \"\(line)\"")
                            } else {
                                print("Ignored unknown line format: \"\(line)\"")
                            }
                        }
                    }
                    // After the loop, if there's anything left in lineBuffer, it's an incomplete line
                    if !lineBuffer.isEmpty {
                        print("Remaining in lineBuffer after stream finished: \"\(lineBuffer.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r"))\"")
                    }
                    print("Source dataStream finished.")
                    continuation.finish()
                } catch {
                    print("Error iterating source dataStream: \(error)")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable reason in
                print("Output stream terminated: \(reason)")
            }
        }
    }
}

private let _decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

extension Bool: Responable {}

extension Array<Event>: Responable {}
