//
//  AsyncSequence+Extension.swift
//  AiChatUi
//
//  Created by Measna on 26/5/25.
//

import Foundation

extension AsyncSequence where Element == UInt8, Self: Sendable {
    func dataChunks(chunkSize: Int = 1024 * 4) -> AsyncThrowingStream<Data, Error> { // Default chunk size 4KB
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var buffer = Data()
                    buffer.reserveCapacity(chunkSize) // Pre-allocate buffer
                    
                    var iterator = self.makeAsyncIterator()
                    
                    while let byte = try await iterator.next() {
                        buffer.append(byte)
                        if buffer.count >= chunkSize {
                            continuation.yield(buffer)
                            buffer.removeAll(keepingCapacity: true) // Reset buffer, keep capacity
                        }
                    }
                    // Yield any remaining data in the buffer
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            // Handle cancellation of the stream
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
