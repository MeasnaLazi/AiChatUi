//
//  APIClient.swift
//  AiChatUi
//
//  Created by Measna on 25/5/25.
//

import Foundation

struct APIClient: RequestExecutor {
    private let session: URLSession
    var timeout: TimeInterval?
    var requestHeader: [String: String]? = ["Connection": "Keep-Alive"]

    init(session: URLSession = .shared, timeout: TimeInterval? = nil, requestHeader: [String: String]? = ["Connection": "Keep-Alive"]) {
        self.session = session
        self.timeout = timeout
        self.requestHeader = requestHeader
    }

    func execute<T: Responable>(_ request: Requestable) async throws -> T {
        let urlRequest = self.createURLRequest(from: request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "APIClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }

            if !(200..<300).contains(httpResponse.statusCode) {
                throw NSError(domain: "APIClientError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed with status code \(httpResponse.statusCode)"])
            }
            
            // when delete success, it's response "null"
            if let text = String(data: data, encoding: .utf8), text == "null" {
                let textData = Data("true".utf8)
                return try T.decode(textData)
            }
//            print("data: \(String(describing: String(data: data, encoding: .utf8)))")

            return try T.decode(data)
            
        } catch let decodingError as DecodingError {
            print("ApiClient decodingError: \(decodingError.localizedDescription)")
            throw decodingError
        } catch {
            print("ApiClient error: \(error.localizedDescription)")
            throw error
        }
    }
    enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError(Error)
        case streamProcessingError
        case apiError(String)
    }
    
    func executeStream<T: Responable>(_ request: Requestable) async throws -> AsyncThrowingStream<T, Error> {
        let urlRequest = createURLRequest(from: request)
        
        return AsyncThrowingStream { continuation in
//                    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//                        if let error = error {
////                            continuation.finish(throwing: APIError.requestFailed(error))
//                            return
//                        }
//
//                        guard let httpResponse = response as? HTTPURLResponse else {
////                            continuation.finish(throwing: APIError.invalidResponse)
//                            return
//                        }
//                        
//                        // Note: For streaming, we don't expect a single data blob here.
//                        // The actual stream handling happens via delegate or URLSession.bytes if not using a simple dataTask.
//                        // This basic dataTask is not ideal for streaming directly; URLSession.bytes(for: request) is better.
//                        // However, for simplicity in showing the async stream *creation*, we'll adapt.
//                        // A production app would use URLSession's byte stream directly.
//                        // The example below will be updated to use URLSession.bytes for proper stream handling.
//
//                        // This part is incorrect for stream processing with a simple dataTask completion handler.
//                        // We need to transition to using URLSession.bytes(for:) to get the AsyncBytes.
//
////                        continuation.finish(throwing: APIError.streamProcessingError) // Placeholder, will be replaced
//                    }
//                    // This task.resume() is for a non-streaming dataTask.
//                    // For a true streaming example, the approach is different.
//                    // task.resume() // Not for the bytes approach.

                    // Corrected approach for streaming using URLSession.bytes
                    Task {
                        do {
                            let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                                // Attempt to decode error body if available
                                var errorDataString = "No error data."
                                var errorBody: Data?
                                for try await byte in bytes { // consume the error body if any
                                    if errorBody == nil { errorBody = Data() }
                                    errorBody?.append(byte)
                                }
                                if let data = errorBody {
                                    errorDataString = String(data: data, encoding: .utf8) ?? "Could not decode error body."
                                }
                                continuation.finish(throwing: APIError.apiError("Invalid response status: \( (response as? HTTPURLResponse)?.statusCode ?? 0 ). Body: \(errorDataString)"))
                                return
                            }
                            
                            for try await line in bytes.lines {
                                if line.hasPrefix("data: ") {
                                    let dataString = String(line.dropFirst(6)) // Remove "data: "
                                    if dataString == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    guard let jsonData = dataString.data(using: .utf8) else {
                                        print("Warning: Could not convert string to data: \(dataString)")
                                        continue
                                    }
                                    print("dataString: \(dataString)")
                                    do {
                                        let streamResponse = try T.decode(jsonData)//try JSONDecoder().decode(Event.self, from: jsonData)
//                                        if let content = streamResponse {
                                            continuation.yield(streamResponse)
//                                        }
//                                        if streamResponse.choices.first?.finishReason != nil {
//                                            continuation.finish()
//                                            return
//                                        }
                                    } catch {
                                        print("Warning: Decoding stream chunk failed: \(error). Chunk: \(dataString)")
                                        // Depending on the error, you might want to continue or finish with an error
                                        // For now, we'll try to continue with the next chunk
                                    }
                                }
                            }
                            continuation.finish() // In case the stream ends without a [DONE] or finishReason in the last chunk
                        } catch {
                            continuation.finish(throwing: APIError.streamProcessingError)
                        }
                    }
                }

//        do {
//            let (byteStream, response) = try await session.bytes(for: urlRequest)
//
//            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
//                throw URLError(.badServerResponse)
//            }
//
//            let dataStream = byteStream.dataChunks()
//            return T.decode(from: dataStream)
//            
//        } catch let decodingError as DecodingError {
//            debugPrint("ApiClient decodingError: \(decodingError.localizedDescription)")
//            throw decodingError
//        } catch let urlError as URLError {
//            debugPrint("ApiClient urlError: \(urlError.localizedDescription)")
//            throw urlError
//        } catch {
//            debugPrint("ApiClient error: \(error.localizedDescription)")
//            throw error
//        }
    }
    
    private func createURLRequest(from requestable: Requestable) -> URLRequest {
        var url = requestable.requestURL
        if let path = requestable.path {
            url = url.appendingPathComponent(path)
        }
        
        var urlRequest = URLRequest(url: url)
        if let timeout = (requestable.timeout ?? self.timeout) {
            urlRequest.timeoutInterval = timeout
        }
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.httpMethod = requestable.httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = requestHeader
        requestable.header.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let paramater = requestable.paramater {
            switch paramater {
            case .body(let data):
                urlRequest.httpBody = data
            case.query(let queries):
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                components.queryItems = queries.map { URLQueryItem(name: $0.key, value: $0.value) }
                components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
                urlRequest.url = components.url
            }
        }
        
        print("urlRequest:\(urlRequest)")
        return urlRequest
    }
}
